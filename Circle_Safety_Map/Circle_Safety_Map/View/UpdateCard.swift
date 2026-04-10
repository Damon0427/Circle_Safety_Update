import SwiftUI

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
