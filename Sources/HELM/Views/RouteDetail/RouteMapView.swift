import SwiftUI
import MapKit

struct RouteMapView: View {
    let stops: [RouteStop]

    private var annotations: [StopAnnotation] {
        stops.compactMap { stop in
            guard let lat = stop.syncedContacts?.latitude,
                  let lng = stop.syncedContacts?.longitude else { return nil }
            return StopAnnotation(
                id: stop.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                order: stop.stopOrder + 1,
                status: stop.status
            )
        }
    }

    private var region: MKCoordinateRegion {
        guard !annotations.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        let lats = annotations.map { $0.coordinate.latitude }
        let lngs = annotations.map { $0.coordinate.longitude }
        let centerLat = (lats.min()! + lats.max()!) / 2
        let centerLng = (lngs.min()! + lngs.max()!) / 2
        let spanLat = max((lats.max()! - lats.min()!) * 1.4, 0.01)
        let spanLng = max((lngs.max()! - lngs.min()!) * 1.4, 0.01)
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLng)
        )
    }

    var body: some View {
        Map(initialPosition: .region(region)) {
            ForEach(annotations) { annotation in
                Annotation(
                    "\(annotation.order)",
                    coordinate: annotation.coordinate,
                    anchor: .bottom
                ) {
                    ZStack {
                        Circle()
                            .fill(annotation.status == .visited ? Color.green : Color.blue)
                            .frame(width: 24, height: 24)
                        Text("\(annotation.order)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
            if annotations.count >= 2 {
                MapPolyline(coordinates: annotations.map(\.coordinate))
                    .stroke(.blue.opacity(0.6), lineWidth: 2)
            }
        }
        .disabled(true)
    }
}

struct StopAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let order: Int
    let status: StopStatus
}
