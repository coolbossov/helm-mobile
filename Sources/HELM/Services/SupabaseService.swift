import Foundation
import Supabase

// MARK: - Supabase Client Singleton

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: urlString),
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
        else {
            fatalError("Missing SUPABASE_URL or SUPABASE_ANON_KEY in Info.plist")
        }
        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }
}

// MARK: - Route Repository

final class RouteRepository {
    private let db: SupabaseClient

    init(client: SupabaseClient = SupabaseService.shared.client) {
        self.db = client
    }

    func fetchRoutes() async throws -> [SavedRoute] {
        let routes: [SavedRoute] = try await db
            .from("saved_routes")
            .select("*, route_stops(count)")
            .order("created_at", ascending: false)
            .execute()
            .value
        return routes
    }

    func fetchRoute(id: String) async throws -> SavedRoute {
        let route: SavedRoute = try await db
            .from("saved_routes")
            .select("""
                *,
                route_stops (
                    *,
                    synced_contacts (
                        id, first_name, last_name, account_name,
                        mailing_street, mailing_city, mailing_state, mailing_zip,
                        latitude, longitude, phone, mobile
                    )
                )
            """)
            .eq("id", value: id)
            .order("stop_order", referencedTable: "route_stops", ascending: true)
            .single()
            .execute()
            .value
        return route
    }

    func updateStopStatus(routeId: String, stopId: String, status: StopStatus) async throws {
        var updates: [String: AnyJSON] = ["status": .string(status.rawValue)]
        if status == .visited {
            updates["visited_at"] = .string(ISO8601DateFormatter().string(from: Date()))
        }
        try await db
            .from("route_stops")
            .update(updates)
            .eq("id", value: stopId)
            .eq("route_id", value: routeId)
            .execute()
    }

    func updateStopMeta(routeId: String, stopId: String, patch: [String: AnyJSON]) async throws {
        try await db
            .from("route_stops")
            .update(patch)
            .eq("id", value: stopId)
            .eq("route_id", value: routeId)
            .execute()
    }

    func optimizeRoute(routeId: String, mode: OptimizationMode) async throws {
        guard let url = URL(string: "\(SupabaseService.shared.client.supabaseURL)/functions/v1/optimize-route") else {
            return
        }
        // Call the HELM web API directly — pass Authorization header with current session token
        let session = try await SupabaseService.shared.client.auth.session
        var request = URLRequest(url: URL(string: "\(AppConfig.helmAPIBaseURL)/api/routes/\(routeId)/optimize")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(["mode": mode.rawValue])
        _ = try await URLSession.shared.data(for: request)
    }
}

// MARK: - App Configuration

enum AppConfig {
    static let helmAPIBaseURL: String = {
        Bundle.main.object(forInfoDictionaryKey: "HELM_API_BASE_URL") as? String
            ?? "https://helm-app.vercel.app"
    }()
}
