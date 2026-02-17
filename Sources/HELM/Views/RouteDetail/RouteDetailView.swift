import SwiftUI
import MapKit
import Combine

@MainActor
final class RouteDetailViewModel: ObservableObject {
    @Published var route: SavedRoute?
    @Published var isLoading = false
    @Published var error: String?
    @Published var isOptimizing = false

    private let repo = RouteRepository()
    private var realtimeTask: Task<Void, Never>?

    var stops: [RouteStop] { route?.routeStops ?? [] }
    var visitedCount: Int { stops.filter { $0.status == .visited }.count }
    var skippedCount: Int { stops.filter { $0.status == .skipped }.count }
    var progressFraction: Double {
        guard !stops.isEmpty else { return 0 }
        return Double(visitedCount) / Double(stops.count)
    }

    func load(routeId: String) async {
        isLoading = true
        error = nil
        do {
            route = try await repo.fetchRoute(id: routeId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func updateStopStatus(stop: RouteStop, status: StopStatus) async {
        guard let routeId = route?.id else { return }
        // Optimistic update
        if let idx = route?.routeStops?.firstIndex(where: { $0.id == stop.id }) {
            route?.routeStops?[idx].status = status
            if status == .visited {
                route?.routeStops?[idx].visitedAt = ISO8601DateFormatter().string(from: Date())
            }
        }
        do {
            try await repo.updateStopStatus(routeId: routeId, stopId: stop.id, status: status)
        } catch {
            // Silently queue for offline sync — handled by OfflineSyncQueue
        }
    }

    func optimizeFromHere(currentLocation: CLLocation?) async {
        guard let routeId = route?.id else { return }
        isOptimizing = true
        do {
            try await repo.optimizeRoute(routeId: routeId, mode: route?.optimizationMode ?? .fastest)
            await load(routeId: routeId)
        } catch {
            // ignore
        }
        isOptimizing = false
    }

    func subscribeToRealtime(routeId: String) {
        realtimeTask = Task {
            let channel = SupabaseService.shared.client.channel("route:\(routeId)")
            let changes = channel.postgresChange(
                AnyAction.self,
                table: "route_stops",
                filter: "route_id=eq.\(routeId)"
            )
            await channel.subscribe()
            for await _ in changes {
                await load(routeId: routeId)
            }
        }
    }

    deinit {
        realtimeTask?.cancel()
    }
}

struct RouteDetailView: View {
    let routeId: String
    @StateObject private var vm = RouteDetailViewModel()
    @State private var selectedStop: RouteStop?
    @State private var showOptimizeSheet = false

    var body: some View {
        Group {
            if vm.isLoading && vm.route == nil {
                ProgressView("Loading route…")
            } else if let error = vm.error {
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if let route = vm.route {
                ScrollView {
                    VStack(spacing: 16) {
                        // Map preview
                        RouteMapView(stops: vm.stops)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)

                        // Progress
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Progress")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("\(vm.visitedCount) / \(vm.stops.count) visited")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: vm.progressFraction)
                                .tint(.green)

                            HStack(spacing: 12) {
                                StatChip(value: "\(vm.visitedCount)", label: "Visited", color: .green)
                                StatChip(value: "\(vm.skippedCount)", label: "Skipped", color: .secondary)
                                StatChip(
                                    value: "\(vm.stops.filter { $0.status == .pending }.count)",
                                    label: "Remaining",
                                    color: .blue
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Optimize button
                        if vm.stops.count > 1 {
                            Button {
                                showOptimizeSheet = true
                            } label: {
                                Label(
                                    vm.isOptimizing ? "Optimizing…" : "Re-optimize from here",
                                    systemImage: "wand.and.stars"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(vm.isOptimizing)
                            .padding(.horizontal)
                        }

                        // Stop list
                        VStack(spacing: 8) {
                            ForEach(vm.stops) { stop in
                                StopRowView(
                                    stop: stop,
                                    onStatusChange: { status in
                                        Task { await vm.updateStopStatus(stop: stop, status: status) }
                                    },
                                    onTap: { selectedStop = stop }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .navigationTitle(route.name)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task { await vm.load(routeId: routeId) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedStop) { stop in
            StopDetailView(stop: stop, routeId: routeId) { updatedStop in
                if let idx = vm.route?.routeStops?.firstIndex(where: { $0.id == updatedStop.id }) {
                    vm.route?.routeStops?[idx] = updatedStop
                }
            }
        }
        .task {
            await vm.load(routeId: routeId)
            vm.subscribeToRealtime(routeId: routeId)
        }
    }
}

struct StatChip: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct StopRowView: View {
    let stop: RouteStop
    let onStatusChange: (StopStatus) -> Void
    let onTap: () -> Void

    var priorityColor: Color {
        stop.priority == .mustVisit ? .orange : .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(stop.status == .visited ? Color.green : Color.blue)
                        .frame(width: 28, height: 28)
                    Text("\(stop.stopOrder + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(stop.syncedContacts?.displayName ?? "Stop \(stop.stopOrder + 1)")
                            .font(.subheadline.weight(.semibold))
                        if stop.priority == .mustVisit {
                            Text("Must Visit")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                    if let address = stop.syncedContacts?.formattedAddress {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let start = stop.timeWindowStart?.prefix(5), let end = stop.timeWindowEnd?.prefix(5) {
                        Label("\(start) – \(end)", systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(action: onTap) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Status buttons
            HStack(spacing: 8) {
                StatusButton(title: "Visited", isActive: stop.status == .visited, color: .green) {
                    onStatusChange(.visited)
                }
                StatusButton(title: "Skip", isActive: stop.status == .skipped, color: .secondary) {
                    onStatusChange(.skipped)
                }
                if stop.status != .pending {
                    StatusButton(title: "Reset", isActive: false, color: .secondary) {
                        onStatusChange(.pending)
                    }
                }

                Spacer()

                // Navigate button
                if let contact = stop.syncedContacts, let lat = contact.latitude, let lng = contact.longitude {
                    NavigateButton(lat: lat, lng: lng)
                }
            }
        }
        .padding(14)
        .background(stopBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(stopBorderColor, lineWidth: 1)
        )
    }

    private var stopBackground: Color {
        switch stop.status {
        case .visited: return Color.green.opacity(0.06)
        case .skipped: return Color.gray.opacity(0.06)
        case .pending: return Color(.systemBackground)
        }
    }

    private var stopBorderColor: Color {
        switch stop.status {
        case .visited: return Color.green.opacity(0.3)
        case .skipped: return Color.gray.opacity(0.2)
        case .pending: return Color.gray.opacity(0.2)
        }
    }
}

struct StatusButton: View {
    let title: String
    let isActive: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isActive ? color.opacity(0.15) : Color.clear)
                .foregroundStyle(isActive ? color : .secondary)
                .overlay(
                    Capsule().stroke(isActive ? color.opacity(0.4) : Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
    }
}

struct NavigateButton: View {
    let lat: Double
    let lng: Double
    @AppStorage("preferredNavApp") private var preferredNavApp = "apple"

    var body: some View {
        Button {
            openNavigation()
        } label: {
            Image(systemName: "location.fill")
                .font(.caption)
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Circle())
        }
    }

    private func openNavigation() {
        let urlString: String
        switch preferredNavApp {
        case "google":
            urlString = "comgooglemaps://?daddr=\(lat),\(lng)&directionsmode=driving"
        case "waze":
            urlString = "waze://?ll=\(lat),\(lng)&navigate=yes"
        default:
            urlString = "maps://maps.apple.com/?daddr=\(lat),\(lng)"
        }
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
