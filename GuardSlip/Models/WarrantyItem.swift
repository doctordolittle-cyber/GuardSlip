import Foundation

struct WarrantyItem: Codable, Identifiable, Equatable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }


    let id: UUID
    var name: String
    var store: String?
    var brand: String?
    var category: Category
    var purchaseDate: Date
    var expiryDate: Date
    var price: Double?
    var currency: String?
    var serialNumber: String?
    var notes: String?
    var receiptFileNames: [String]
    var reminderOffsets: [Int]
    let createdAt: Date
    
    var status: WarrantyStatus {
        WarrantyStatus.from(expiryDate: expiryDate)
    }
    
    var progress: Double {
        let total = expiryDate.timeIntervalSince(purchaseDate)
        guard total > 0 else { return 1.0 }
        let elapsed = Date().timeIntervalSince(purchaseDate)
        return min(max(elapsed / total, 0), 1)
    }
    
    var daysRemaining: Int {
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: expiryDate)).day ?? 0
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        store: String? = nil,
        brand: String? = nil,
        category: Category = .other,
        purchaseDate: Date = Date(),
        expiryDate: Date,
        price: Double? = nil,
        currency: String? = nil,
        serialNumber: String? = nil,
        notes: String? = nil,
        receiptFileNames: [String] = [],
        reminderOffsets: [Int] = [30, 7],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.store = store
        self.brand = brand
        self.category = category
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
        self.price = price
        self.currency = currency
        self.serialNumber = serialNumber
        self.notes = notes
        self.receiptFileNames = receiptFileNames
        self.reminderOffsets = reminderOffsets
        self.createdAt = createdAt
    }
}

enum WarrantyStatus: Equatable {
    case active(daysLeft: Int)
    case expiringSoon(daysLeft: Int)
    case expired(daysAgo: Int)
    
    static func from(expiryDate: Date) -> WarrantyStatus {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: expiryDate)).day ?? 0
        if days > 30 {
            return .active(daysLeft: days)
        } else if days > 0 {
            return .expiringSoon(daysLeft: days)
        } else {
            return .expired(daysAgo: abs(days))
        }
    }
    
    var displayText: String {
        switch self {
        case .active(let d): return "\(d) days left"
        case .expiringSoon(let d): return "\(d) days left"
        case .expired(let d): return d == 0 ? "Expired today" : "Expired \(d) days ago"
        }
    }
    
    var isActive: Bool { if case .active = self { return true }; return false }
    var isExpiringSoon: Bool { if case .expiringSoon = self { return true }; return false }
    var isExpired: Bool { if case .expired = self { return true }; return false }
    var colorName: String {
        switch self {
        case .active: return "StatusActive"
        case .expiringSoon: return "StatusExpiring"
        case .expired: return "StatusExpired"
        }
    }
}
