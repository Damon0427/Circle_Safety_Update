import SwiftUI

enum SafetyUpdateType: String, CaseIterable, Identifiable {
    case suspiciousActivity = "Suspicious Activity"
    case needPickup = "Need Pickup"
    case runningLate = "Running Late"
    case imSafe = "I'm Safe"
    case needHelp = "Need Help"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .suspiciousActivity: return "exclamationmark.triangle.fill"
        case .needPickup: return "car.fill"
        case .runningLate: return "clock.fill"
        case .imSafe: return "checkmark.circle.fill"
        case .needHelp: return "hand.raised.fill"
        }
    }

    var tint: Color {
        switch self {
        case .suspiciousActivity: return .orange
        case .needPickup: return .blue
        case .runningLate: return .yellow
        case .imSafe: return .green
        case .needHelp: return .red
        }
    }
}
