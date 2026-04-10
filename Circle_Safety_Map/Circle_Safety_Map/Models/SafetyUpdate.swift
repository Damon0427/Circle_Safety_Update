import CoreLocation
import UIKit

struct SafetyUpdate: Identifiable {
    let id = UUID()
    let type: SafetyUpdateType
    let note: String
    let timestamp: Date
    let coordinate: CLLocationCoordinate2D
    let image: UIImage?
}
