import Foundation
import Combine

final class TimelineViewModel: ObservableObject {

    // MARK: - Published State

    @Published var items: [WarrantyItem] = []
    @Published var showExpired = false

    // MARK: - Timeline Sections

    var expiringThisWeek: [WarrantyItem] {
        sortedByExpiry(items.filter { (1...7).contains($0.daysRemaining) })
    }

    var expiringThisMonth: [WarrantyItem] {
        sortedByExpiry(items.filter { (8...30).contains($0.daysRemaining) })
    }

    var expiringNext3Months: [WarrantyItem] {
        sortedByExpiry(items.filter { (31...90).contains($0.daysRemaining) })
    }

    var expiringLater: [WarrantyItem] {
        sortedByExpiry(items.filter { $0.daysRemaining > 90 })
    }

    var expiredItems: [WarrantyItem] {
        items.filter { $0.daysRemaining <= 0 }
            .sorted { $0.expiryDate > $1.expiryDate }
    }

    var hasNoUpcoming: Bool {
        expiringThisWeek.isEmpty
        && expiringThisMonth.isEmpty
        && expiringNext3Months.isEmpty
        && expiringLater.isEmpty
    }

    // MARK: - Dependencies

    private let storageService: StorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(storageService: StorageServiceProtocol) {
        self.storageService = storageService

        storageService.itemsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$items)

        storageService.loadAllItems()
    }

    // MARK: - Helpers

    private func sortedByExpiry(_ items: [WarrantyItem]) -> [WarrantyItem] {
        items.sorted { $0.expiryDate < $1.expiryDate }
    }
}
