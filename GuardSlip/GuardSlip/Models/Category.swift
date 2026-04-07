import Foundation

enum Category: String, Codable, CaseIterable, Identifiable {
    case electronics
    case appliances
    case auto
    case furniture
    case clothing
    case tools
    case sports
    case health
    case kids
    case other
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .electronics: return "Electronics"
        case .appliances: return "Appliances"
        case .auto: return "Auto"
        case .furniture: return "Furniture"
        case .clothing: return "Clothing"
        case .tools: return "Tools"
        case .sports: return "Sports"
        case .health: return "Health"
        case .kids: return "Kids"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .electronics: return "desktopcomputer"
        case .appliances: return "refrigerator"
        case .auto: return "car.fill"
        case .furniture: return "sofa.fill"
        case .clothing: return "tshirt.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        case .sports: return "sportscourt.fill"
        case .health: return "heart.fill"
        case .kids: return "figure.and.child.holdinghands"
        case .other: return "square.grid.2x2.fill"
        }
    }
}
