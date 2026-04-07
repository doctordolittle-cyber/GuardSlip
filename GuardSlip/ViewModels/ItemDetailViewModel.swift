import Foundation
import Combine
import UIKit

final class ItemDetailViewModel: ObservableObject {

    // MARK: - Published State

    @Published var item: WarrantyItem
    @Published var receiptImages: [(fileName: String, image: UIImage)] = []
    @Published var showingDeleteAlert = false
    @Published var showingEditSheet = false
    @Published var showingShareSheet = false

    // MARK: - Dependencies

    private let storageService: StorageServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        item: WarrantyItem,
        storageService: StorageServiceProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.item = item
        self.storageService = storageService
        self.notificationService = notificationService

        bindItemUpdates()
        loadReceiptImages()
    }

    // MARK: - Receipt Loading

    func loadReceiptImages() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var loaded: [(String, UIImage)] = []

            for fileName in self.item.receiptFileNames {
                if let url = self.storageService.receiptImageURL(fileName: fileName, for: self.item.id),
                   let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    loaded.append((fileName, image))
                }
            }

            DispatchQueue.main.async {
                self.receiptImages = loaded
            }
        }
    }

    // MARK: - Actions

    func deleteItem() {
        try? storageService.delete(item)
        notificationService.cancelNotifications(for: item.id)
    }

    func refreshItem() {
        storageService.itemsPublisher
            .compactMap { [id = item.id] items in items.first(where: { $0.id == id }) }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] refreshed in
                self?.item = refreshed
                self?.loadReceiptImages()
            }
            .store(in: &cancellables)
    }

    // MARK: - Share Image Generation

    func generateShareImage() -> UIImage {
        let cardWidth: CGFloat = 600
        let padding: CGFloat = 32
        let contentWidth = cardWidth - padding * 2

        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let bodyFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        let monoFont = UIFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        let labelColor = UIColor(white: 0.62, alpha: 1)
        let textColor = UIColor.white
        let bgColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
        let goldColor = UIColor(red: 0.83, green: 0.65, blue: 0.28, alpha: 1)

        var lines: [(label: String, value: String)] = [
            ("Category", item.category.displayName),
            ("Purchase", item.purchaseDate.formattedMono),
            ("Expires", item.expiryDate.formattedMono),
            ("Status", item.status.displayText)
        ]

        if let store = item.store { lines.insert(("Store", store), at: 1) }
        if let brand = item.brand { lines.insert(("Brand", brand), at: 1) }
        if let price = item.price {
            let currency = item.currency ?? "USD"
            lines.append(("Price", String(format: "%.2f %@", price, currency)))
        }
        if let serial = item.serialNumber { lines.append(("S/N", serial)) }

        let lineHeight: CGFloat = 30
        let cardHeight: CGFloat = padding + 40 + 12 + CGFloat(lines.count) * lineHeight + padding + 30

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cardWidth, height: cardHeight))
        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: cardWidth, height: cardHeight)
            bgColor.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 20).fill()

            goldColor.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 4, height: cardHeight), cornerRadius: 2).fill()

            let titleAttrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: textColor]
            let title = item.name as NSString
            title.draw(in: CGRect(x: padding, y: padding, width: contentWidth, height: 30), withAttributes: titleAttrs)

            var y = padding + 44
            for line in lines {
                let labelAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: labelColor]
                let valueAttrs: [NSAttributedString.Key: Any] = [.font: monoFont, .foregroundColor: textColor]

                (line.label as NSString).draw(
                    in: CGRect(x: padding, y: y, width: 100, height: lineHeight),
                    withAttributes: labelAttrs
                )
                (line.value as NSString).draw(
                    in: CGRect(x: padding + 110, y: y, width: contentWidth - 110, height: lineHeight),
                    withAttributes: valueAttrs
                )
                y += lineHeight
            }

            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor(white: 0.35, alpha: 1)
            ]
            let footer = "Generated by GuardSlip" as NSString
            footer.draw(
                in: CGRect(x: padding, y: cardHeight - padding - 10, width: contentWidth, height: 16),
                withAttributes: footerAttrs
            )
        }
    }

    // MARK: - Combine Bindings

    private func bindItemUpdates() {
        storageService.itemsPublisher
            .compactMap { [id = item.id] items in items.first(where: { $0.id == id }) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updated in
                self?.item = updated
            }
            .store(in: &cancellables)
    }
}
