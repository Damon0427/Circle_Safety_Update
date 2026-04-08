import SwiftUI
import MapKit
import PhotosUI
// MARK: - Model


struct SafetyUpdate: Identifiable {
    let id = UUID()
    let type: SafetyUpdateType
    let note: String
    let timestamp: Date
    let coordinate: CLLocationCoordinate2D
    let image: UIImage?
}

// MARK: - Main View
struct ContentView: View {
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.3352, longitude: -121.8811), // SJSU area
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )
    @StateObject private var locationManager = LocationManager()

    @State private var updates: [SafetyUpdate] = []
    @State private var showAddSheet = false

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
                AddUpdateSheet { newUpdate in
                    updates.insert(newUpdate, at: 0)

                    withAnimation {
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
    }

    // MARK: - Sections

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Circle Updates")
                .font(.title2.bold())

            Text("Share lightweight safety updates with your circle before situations escalate to SOS.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Map(position: $cameraPosition) {
                ForEach(updates) { update in
                    Annotation(update.type.rawValue, coordinate: update.coordinate) {
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
        .onAppear{
            locationManager.requestPermission()

        }
    }

    private func shortLabel(for type: SafetyUpdateType) -> String {
        switch type {
        case .suspiciousActivity: return "Suspicious"
        case .needPickup: return "Pickup"
        case .runningLate: return "Late"
        case .imSafe: return "Safe"
        case .needHelp: return "Help"
        }
    }
    // Call a map Api function to navigate the pin from map
    private func openDirections(to update: SafetyUpdate) {
        let destinationPlacemark = MKPlacemark(coordinate: update.coordinate)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        destinationMapItem.name = update.type.rawValue

        destinationMapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Card View

struct UpdateCard: View {
    let update: SafetyUpdate
    let onTap: () -> Void


    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: update.type.iconName)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(update.type.tint, in: Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(update.type.rawValue)
                        .font(.headline)

                    Spacer()

                    Text(update.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let image = update.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if !update.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(update.note)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                } else {
                    Text("No additional context provided.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.18), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            print("Card tapped: \(update.type.rawValue)")
            onTap()
        }
    }
}

// MARK: - Add Update Sheet



struct AddUpdateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()

    @State private var selectedType: SafetyUpdateType = .suspiciousActivity
    @State private var note = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    let onShare: (SafetyUpdate) -> Void

    var body: some View {
        NavigationStack {
            Form {
                // ... 你原来的 sections 不变

                // Demo Location section 整个换成这个：
                Section("Location") {
                    if let loc = locationManager.userLocation {
                        Label("Using your current location", systemImage: "location.fill")
                            .foregroundStyle(.green)
                        Text("Lat: \(loc.latitude, specifier: "%.4f"), Lon: \(loc.longitude, specifier: "%.4f")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Fetching your location...", systemImage: "location")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share") {
                        let coordinate = locationManager.userLocation
                            ?? CLLocationCoordinate2D(latitude: 37.3352, longitude: -121.8811) // fallback
                        
                        let newUpdate = SafetyUpdate(
                            type: selectedType,
                            note: note,
                            timestamp: Date(),
                            coordinate: coordinate,
                            image: selectedImage
                        )
                        onShare(newUpdate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .task(id: selectedPhotoItem) {
                if let selectedPhotoItem,
                   let data = try? await selectedPhotoItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
