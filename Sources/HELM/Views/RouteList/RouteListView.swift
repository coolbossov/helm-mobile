import SwiftUI

@MainActor
final class RouteListViewModel: ObservableObject {
    @Published var routes: [SavedRoute] = []
    @Published var isLoading = false
    @Published var error: String?

    private let repo = RouteRepository()

    func load() async {
        isLoading = true
        error = nil
        do {
            routes = try await repo.fetchRoutes()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct RouteListView: View {
    @StateObject private var vm = RouteListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.routes.isEmpty {
                    ProgressView("Loading routes…")
                } else if let error = vm.error {
                    ContentUnavailableView(
                        "Failed to load",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if vm.routes.isEmpty {
                    ContentUnavailableView(
                        "No Routes",
                        systemImage: "map",
                        description: Text("Plan a route on the HELM web app to get started.")
                    )
                } else {
                    List(vm.routes) { route in
                        NavigationLink(destination: RouteDetailView(routeId: route.id)) {
                            RouteRowView(route: route)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await vm.load() }
                }
            }
            .navigationTitle("My Routes")
        }
        .task { await vm.load() }
    }
}

struct RouteRowView: View {
    let route: SavedRoute

    var statusColor: Color {
        switch route.status {
        case .planned: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        }
    }

    var statusLabel: String {
        switch route.status {
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(route.name)
                    .font(.headline)
                Spacer()
                Label(statusLabel, systemImage: statusIcon)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            if let date = route.plannedDate {
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let dist = route.totalDistanceMeters {
                Text(formatDistance(dist))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusIcon: String {
        switch route.status {
        case .planned: return "clock"
        case .inProgress: return "car.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }

    private func formatDistance(_ meters: Int) -> String {
        let miles = Double(meters) / 1609.34
        return String(format: "%.1f mi", miles)
    }
}
