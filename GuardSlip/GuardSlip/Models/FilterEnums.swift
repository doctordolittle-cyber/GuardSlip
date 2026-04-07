import Foundation

enum StatusFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case expiring = "Expiring Soon"
    case expired = "Expired"
}

enum SortOption: String, CaseIterable {
    case expiryDate = "Expiry Date"
    case purchaseDate = "Purchase Date"
    case name = "Name"
}

enum WarrantyDuration: String, CaseIterable, Identifiable {
    case sixMonths = "6 Months"
    case oneYear = "1 Year"
    case twoYears = "2 Years"
    case threeYears = "3 Years"
    case fiveYears = "5 Years"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var months: Int? {
        switch self {
        case .sixMonths: return 6
        case .oneYear: return 12
        case .twoYears: return 24
        case .threeYears: return 36
        case .fiveYears: return 60
        case .custom: return nil
        }
    }
}
