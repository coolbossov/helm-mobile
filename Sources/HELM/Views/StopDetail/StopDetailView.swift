import SwiftUI

struct StopDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var stop: RouteStop
    let routeId: String
    let onUpdate: (RouteStop) -> Void

    @State private var visitNotes: String = ""
    @State private var selectedOutcome: String = ""
    @State private var isSaving = false

    private let repo = RouteRepository()

    private let outcomes = [
        ("", "No outcome"),
        ("interested", "Interested"),
        ("not_interested", "Not Interested"),
        ("follow_up", "Follow Up"),
        ("booked", "Booked"),
        ("no_answer", "No Answer"),
        ("left_info", "Left Info"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Contact info
                if let contact = stop.syncedContacts {
                    Section("Contact") {
                        LabeledContent("Name", value: contact.displayName)
                        if let address = contact.formattedAddress {
                            LabeledContent("Address", value: address)
                        }
                        if let phone = contact.phone ?? contact.mobile {
                            LabeledContent("Phone") {
                                Link(phone, destination: URL(string: "tel:\(phone)")!)
                            }
                        }
                    }
                }

                // Navigation
                if let lat = stop.syncedContacts?.latitude, let lng = stop.syncedContacts?.longitude {
                    Section("Navigate") {
                        NavigationLinksRow(lat: lat, lng: lng)
                    }
                }

                // Status
                Section("Visit Status") {
                    Picker("Status", selection: Binding(
                        get: { stop.status },
                        set: { newStatus in
                            stop.status = newStatus
                            Task { try? await repo.updateStopStatus(routeId: routeId, stopId: stop.id, status: newStatus) }
                        }
                    )) {
                        Text("Pending").tag(StopStatus.pending)
                        Text("Visited").tag(StopStatus.visited)
                        Text("Skipped").tag(StopStatus.skipped)
                    }
                    .pickerStyle(.segmented)
                }

                // Notes & outcome
                Section("Notes") {
                    TextField("Visit notes…", text: $visitNotes, axis: .vertical)
                        .lineLimit(3...8)
                    Picker("Outcome", selection: $selectedOutcome) {
                        ForEach(outcomes, id: \.0) { outcome in
                            Text(outcome.1).tag(outcome.0)
                        }
                    }
                }

                // Priority & time window
                Section("Schedule") {
                    Picker("Priority", selection: Binding(
                        get: { stop.priority },
                        set: { stop.priority = $0 }
                    )) {
                        Text("Must Visit").tag(StopPriority.mustVisit)
                        Text("Nice to Visit").tag(StopPriority.niceToVisit)
                    }

                    if let start = Binding(
                        get: { stop.timeWindowStart.flatMap { timeString($0) } },
                        set: { stop.timeWindowStart = $0.map { formatTime($0) } }
                    ).wrappedValue {
                        // Show time window if set
                        LabeledContent("Time Window") {
                            Text("\(stop.timeWindowStart?.prefix(5) ?? "") – \(stop.timeWindowEnd?.prefix(5) ?? "")")
                                .foregroundStyle(.secondary)
                        }
                    }

                    LabeledContent("Duration") {
                        Stepper("\(stop.expectedDurationMin) min", value: Binding(
                            get: { stop.expectedDurationMin },
                            set: { stop.expectedDurationMin = $0 }
                        ), in: 5...480, step: 5)
                    }
                }
            }
            .navigationTitle("Stop Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .onAppear {
            visitNotes = stop.visitNotes ?? ""
            selectedOutcome = stop.visitOutcome ?? ""
        }
    }

    private func save() async {
        isSaving = true
        stop.visitNotes = visitNotes.isEmpty ? nil : visitNotes
        stop.visitOutcome = selectedOutcome.isEmpty ? nil : selectedOutcome

        do {
            var patch: [String: AnyJSON] = [:]
            if let notes = stop.visitNotes { patch["visit_notes"] = .string(notes) }
            if let outcome = stop.visitOutcome { patch["visit_outcome"] = .string(outcome) }
            patch["priority"] = .string(stop.priority.rawValue)
            patch["expected_duration_min"] = .number(Double(stop.expectedDurationMin))

            try await repo.updateStopMeta(routeId: routeId, stopId: stop.id, patch: patch)
            onUpdate(stop)
            dismiss()
        } catch {
            // ignore for now
        }
        isSaving = false
    }

    private func timeString(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: String(str.prefix(5)))
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct NavigationLinksRow: View {
    let lat: Double
    let lng: Double

    var body: some View {
        HStack(spacing: 12) {
            NavAppButton(title: "Apple Maps", icon: "map.fill", color: .blue) {
                URL(string: "maps://maps.apple.com/?daddr=\(lat),\(lng)")
            }
            NavAppButton(title: "Google", icon: "globe", color: .blue) {
                URL(string: "comgooglemaps://?daddr=\(lat),\(lng)&directionsmode=driving")
            }
            NavAppButton(title: "Waze", icon: "car.fill", color: .blue) {
                URL(string: "waze://?ll=\(lat),\(lng)&navigate=yes")
            }
        }
    }
}

struct NavAppButton: View {
    let title: String
    let icon: String
    let color: Color
    let url: () -> URL?

    var body: some View {
        Button {
            if let url = url() {
                UIApplication.shared.open(url)
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
