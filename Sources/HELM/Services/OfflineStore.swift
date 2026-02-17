import Foundation
import SwiftData

// MARK: - Offline Cache Models (SwiftData)

@Model
final class CachedRoute {
    @Attribute(.unique) var id: String
    var name: String
    var statusRaw: String
    var totalDistanceMeters: Int?
    var totalDurationSeconds: Int?
    var plannedDate: String?
    var updatedAt: String

    init(from route: SavedRoute) {
        self.id = route.id
        self.name = route.name
        self.statusRaw = route.status.rawValue
        self.totalDistanceMeters = route.totalDistanceMeters
        self.totalDurationSeconds = route.totalDurationSeconds
        self.plannedDate = route.plannedDate
        self.updatedAt = route.updatedAt
    }
}

@Model
final class CachedStop {
    @Attribute(.unique) var id: String
    var routeId: String
    var contactId: String
    var stopOrder: Int
    var statusRaw: String
    var visitNotes: String?
    var visitedAt: String?
    var visitOutcome: String?

    // Contact snapshot for offline use
    var contactName: String?
    var contactAddress: String?
    var contactPhone: String?
    var contactLat: Double?
    var contactLng: Double?

    init(from stop: RouteStop) {
        self.id = stop.id
        self.routeId = stop.routeId
        self.contactId = stop.contactId
        self.stopOrder = stop.stopOrder
        self.statusRaw = stop.status.rawValue
        self.visitNotes = stop.visitNotes
        self.visitedAt = stop.visitedAt
        self.visitOutcome = stop.visitOutcome
        self.contactName = stop.syncedContacts?.displayName
        self.contactAddress = stop.syncedContacts?.formattedAddress
        self.contactPhone = stop.syncedContacts?.phone ?? stop.syncedContacts?.mobile
        self.contactLat = stop.syncedContacts?.latitude
        self.contactLng = stop.syncedContacts?.longitude
    }
}

// MARK: - Offline Mutation Queue

@Model
final class PendingMutation {
    var id: String = UUID().uuidString
    var method: String
    var path: String
    var bodyJSON: String
    var createdAt: Date = Date()

    init(method: String, path: String, body: [String: String]) {
        self.method = method
        self.path = path
        self.bodyJSON = (try? String(data: JSONEncoder().encode(body), encoding: .utf8)) ?? "{}"
    }
}

// MARK: - Sync Queue

@MainActor
final class OfflineSyncQueue: ObservableObject {
    static let shared = OfflineSyncQueue()
    private let auth = SupabaseService.shared.client.auth

    func enqueue(method: String, path: String, body: [String: String], context: ModelContext) {
        let mutation = PendingMutation(method: method, path: path, body: body)
        context.insert(mutation)
        try? context.save()
    }

    func flush(context: ModelContext) async {
        let descriptor = FetchDescriptor<PendingMutation>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        guard let mutations = try? context.fetch(descriptor), !mutations.isEmpty else { return }

        for mutation in mutations {
            do {
                guard let url = URL(string: "\(AppConfig.helmAPIBaseURL)\(mutation.path)") else { continue }
                let session = try await auth.session
                var request = URLRequest(url: url)
                request.httpMethod = mutation.method
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                request.httpBody = mutation.bodyJSON.data(using: .utf8)
                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode < 300 {
                    context.delete(mutation)
                }
            } catch {
                break // Stop flushing on first error; retry later
            }
        }
        try? context.save()
    }
}
