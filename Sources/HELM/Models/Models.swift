import Foundation

// MARK: - Route Models

enum RouteStatus: String, Codable, CaseIterable {
    case planned
    case inProgress = "in_progress"
    case completed
}

enum StopStatus: String, Codable, CaseIterable {
    case pending
    case visited
    case skipped
}

enum StopPriority: String, Codable, CaseIterable {
    case mustVisit = "must_visit"
    case niceToVisit = "nice_to_visit"
}

enum OptimizationMode: String, Codable, CaseIterable {
    case fastest
    case shortest
    case strictTimeWindows = "strict_time_windows"

    var displayName: String {
        switch self {
        case .fastest: return "Fastest"
        case .shortest: return "Shortest"
        case .strictTimeWindows: return "Time Windows"
        }
    }
}

struct SavedRoute: Codable, Identifiable {
    let id: String
    let name: String
    let status: RouteStatus
    let totalDistanceMeters: Int?
    let totalDurationSeconds: Int?
    let plannedDate: String?
    let optimizationMode: OptimizationMode
    let createdAt: String
    let updatedAt: String

    // Joined
    var routeStops: [RouteStop]?

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case totalDistanceMeters = "total_distance_meters"
        case totalDurationSeconds = "total_duration_seconds"
        case plannedDate = "planned_date"
        case optimizationMode = "optimization_mode"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case routeStops = "route_stops"
    }
}

struct RouteStop: Codable, Identifiable {
    let id: String
    let routeId: String
    let contactId: String
    let stopOrder: Int
    var status: StopStatus
    var priority: StopPriority
    var visitNotes: String?
    var visitedAt: String?
    var timeWindowStart: String?
    var timeWindowEnd: String?
    var expectedDurationMin: Int
    var visitOutcome: String?
    let createdAt: String

    // Joined
    var syncedContacts: ContactSummary?

    enum CodingKeys: String, CodingKey {
        case id
        case routeId = "route_id"
        case contactId = "contact_id"
        case stopOrder = "stop_order"
        case status, priority
        case visitNotes = "visit_notes"
        case visitedAt = "visited_at"
        case timeWindowStart = "time_window_start"
        case timeWindowEnd = "time_window_end"
        case expectedDurationMin = "expected_duration_min"
        case visitOutcome = "visit_outcome"
        case createdAt = "created_at"
        case syncedContacts = "synced_contacts"
    }
}

struct ContactSummary: Codable, Identifiable {
    let id: String
    let firstName: String?
    let lastName: String
    let accountName: String?
    let mailingStreet: String?
    let mailingCity: String?
    let mailingState: String?
    let mailingZip: String?
    let latitude: Double?
    let longitude: Double?
    let phone: String?
    let mobile: String?

    var displayName: String {
        if let account = accountName, !account.isEmpty { return account }
        let parts = [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }

    var formattedAddress: String? {
        let parts = [mailingStreet, mailingCity, mailingState, mailingZip]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case accountName = "account_name"
        case mailingStreet = "mailing_street"
        case mailingCity = "mailing_city"
        case mailingState = "mailing_state"
        case mailingZip = "mailing_zip"
        case latitude, longitude, phone, mobile
    }
}
