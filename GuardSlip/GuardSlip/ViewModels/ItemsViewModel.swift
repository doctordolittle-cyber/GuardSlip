import Foundation
import Combine

final class ItemsViewModel: ObservableObject {

    // MARK: - Published State

    @Published var items: [WarrantyItem] = []
    @Published var searchText = ""
    @Published var statusFilter: StatusFilter = .all
    @Published var selectedCategory: Category? = nil
    @Published var sortOption: SortOption = .expiryDate
    @Published var showingFilterSheet = false
    @Published var showingAddItem = false
    @Published private(set) var filteredItems: [WarrantyItem] = []

    // MARK: - Computed Counts

    var activeCount: Int { items.filter { $0.status.isActive }.count }
    var expiringCount: Int { items.filter { $0.status.isExpiringSoon }.count }
    var expiredCount: Int { items.filter { $0.status.isExpired }.count }

    // MARK: - Dependencies

    private let storageService: StorageServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(storageService: StorageServiceProtocol, notificationService: NotificationServiceProtocol) {
        self.storageService = storageService
        self.notificationService = notificationService

        bindStoragePublisher()
        bindFilterPipeline()

        storageService.loadAllItems()
    }

    // MARK: - Actions

    func deleteItem(_ item: WarrantyItem) {
        try? storageService.delete(item)
        notificationService.cancelNotifications(for: item.id)
    }

    // MARK: - Combine Pipelines

    private func bindStoragePublisher() {
        storageService.itemsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$items)
    }

    private func bindFilterPipeline() {
        Publishers.CombineLatest4($items, $searchText, $statusFilter, $selectedCategory)
            .combineLatest($sortOption)
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .map { combined, sortOption -> [WarrantyItem] in
                let (items, searchText, statusFilter, selectedCategory) = combined
                return Self.applyFilters(
                    items: items,
                    searchText: searchText,
                    statusFilter: statusFilter,
                    category: selectedCategory,
                    sortOption: sortOption
                )
            }
            .removeDuplicates()
            .assign(to: &$filteredItems)
    }

    // MARK: - Filtering Logic

    private static func applyFilters(
        items: [WarrantyItem],
        searchText: String,
        statusFilter: StatusFilter,
        category: Category?,
        sortOption: SortOption
    ) -> [WarrantyItem] {
        var result = items

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { item in
                item.name.lowercased().contains(query)
                || (item.store?.lowercased().contains(query) ?? false)
                || (item.brand?.lowercased().contains(query) ?? false)
                || item.category.displayName.lowercased().contains(query)
            }
        }

        switch statusFilter {
        case .all:
            break
        case .active:
            result = result.filter { $0.status.isActive }
        case .expiring:
            result = result.filter { $0.status.isExpiringSoon }
        case .expired:
            result = result.filter { $0.status.isExpired }
        }

        if let category {
            result = result.filter { $0.category == category }
        }

        switch sortOption {
        case .expiryDate:
            result.sort { $0.expiryDate < $1.expiryDate }
        case .purchaseDate:
            result.sort { $0.purchaseDate > $1.purchaseDate }
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        return result
    }
}
