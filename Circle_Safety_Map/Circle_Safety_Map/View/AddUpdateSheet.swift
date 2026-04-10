import SwiftUI
import PhotosUI

struct AddUpdateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationManager: LocationManager

    @State private var selectedType: SafetyUpdateType = .suspiciousActivity
    @State private var note = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    let onShare: (SafetyUpdate) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Update Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(SafetyUpdateType.allCases) { type in
                            Label(type.rawValue, systemImage: type.iconName).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Optional Note") {
                    TextField("Add context for your circle", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section("Photo Evidence") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Upload Photo", systemImage: "photo")
                    }
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

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
            .navigationTitle("New Safety Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share") {
                        let coordinate = locationManager.userLocation
                            ?? CLLocationCoordinate2D(latitude: 37.3352, longitude: -121.8811)
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
