import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var updates: [SafetyUpdate] = []
    @State private var showAddSheet = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    mapSection
                    updatesSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Circle Map")
            .onAppear {
                locationManager.requestPermission()
            }
            .onReceive(locationManager.firstLocationPublisher) { coord in
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add safety update")
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddUpdateSheet(locationManager: locationManager) { newUpdate in
                    updates.insert(newUpdate, at: 0)
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: newUpdate.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        )
                    )
                }
            }
        }
    }

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Circle Updates")
                .font(.title2.bold())

            Text("Share lightweight safety updates with your circle before situations escalate to SOS.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Map(position: $cameraPosition) {
                ForEach(updates) { update in
                    Annotation(shortLabel(for: update.type), coordinate: update.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: update.type.iconName)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(update.type.tint, in: Circle())

                            Text(shortLabel(for: update.type))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.thinMaterial, in: Capsule())
                        }
                    }
                }
            }
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
            )
        }
    }

    // updatesSection, shortLabel, openDirections 都不变
    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Updates")
                    .font(.title3.bold())
                Spacer()
                Text("\(updates.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if updates.isEmpty {
                ContentUnavailableView(
                    "No updates yet",
                    systemImage: "mappin.and.ellipse",
                    description: Text("Tap the + button to share a safety update with your circle.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    ForEach(updates) { update in
                        UpdateCard(update: update) {
                            openDirections(to: update)
                        }
                    }
                }
            }
        }
    }

    private func shortLabel(for type: SafetyUpdateType) -> String {
        switch type {
        case .suspiciousActivity: return "Suspicious"
        case .needPickup:         return "Pickup"
        case .runningLate:        return "Late"
        case .imSafe:             return "Safe"
        case .needHelp:           return "Help"
        }
    }

    private func openDirections(to update: SafetyUpdate) {
        let placemark = MKPlacemark(coordinate: update.coordinate)
        let mapItem   = MKMapItem(placemark: placemark)
        mapItem.name  = update.type.rawValue
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

#Preview {
    ContentView()
}
