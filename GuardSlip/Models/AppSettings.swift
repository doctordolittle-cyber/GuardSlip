import Foundation
import CoreGraphics

struct AppSettings: Codable, Equatable {
    var defaultReminderOffsets: [Int]
    var defaultWarrantyMonths: Int
    var currency: String
    var photoQuality: PhotoQuality
    var appearance: AppAppearance
    
    static let `default` = AppSettings(
        defaultReminderOffsets: [30, 7],
        defaultWarrantyMonths: 12,
        currency: Locale.current.currency?.identifier ?? "USD",
        photoQuality: .medium,
        appearance: .dark
    )
}

enum PhotoQuality: String, Codable, CaseIterable {
    case high, medium, compressed
    
    var displayName: String {
        switch self {
        case .high: return "High (Original)"
        case .medium: return "Medium (80%)"
        case .compressed: return "Compressed (50%)"
        }
    }
    
    var compressionQuality: CGFloat {
        switch self {
        case .high: return 1.0
        case .medium: return 0.8
        case .compressed: return 0.5
        }
    }
}

enum AppAppearance: String, Codable, CaseIterable {
    case system, light, dark
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
