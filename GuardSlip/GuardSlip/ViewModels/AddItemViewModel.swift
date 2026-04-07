import Foundation
import Combine
import UIKit

final class AddItemViewModel: ObservableObject {

    // MARK: - Step Navigation

    @Published var currentStep = 0

    // MARK: - Step 0: Receipt

    @Published var receiptImages: [UIImage] = []
    @Published var isProcessingOCR = false
    @Published var detectedDate: Date?

    // MARK: - Step 1: Details

    @Published var name = ""
    @Published var store = ""
    @Published var brand = ""
    @Published var category: Category = .other
    @Published var purchaseDate = Date()
    @Published var warrantyDuration: WarrantyDuration = .oneYear
    @Published var customExpiryDate = Date().adding(months: 12)
    @Published var price = ""
    @Published var selectedCurrency: String
    @Published var serialNumber = ""
    @Published var notes = ""

    // MARK: - Step 2: Reminders

    @Published var remindBeforeExpiry = true
    @Published var selectedReminderOffsets: Set<Int> = [30, 7]

    // MARK: - Saving

    @Published var isSaving = false

    // MARK: - Computed

    var expiryDate: Date {
        if warrantyDuration == .custom {
            return customExpiryDate
        }
        guard let months = warrantyDuration.months else { return customExpiryDate }
        return purchaseDate.adding(months: months)
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canAdvanceFromDetails: Bool { canSave }

    // MARK: - Dependencies

    private let storageService: StorageServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let ocrService: OCRServiceProtocol
    private let photoService: PhotoServiceProtocol
    private let settings: AppSettings
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        storageService: StorageServiceProtocol,
        notificationService: NotificationServiceProtocol,
        ocrService: OCRServiceProtocol,
        photoService: PhotoServiceProtocol,
        settings: AppSettings
    ) {
        self.storageService = storageService
        self.notificationService = notificationService
        self.ocrService = ocrService
        self.photoService = photoService
        self.settings = settings
        self.selectedCurrency = settings.currency

        self.selectedReminderOffsets = Set(settings.defaultReminderOffsets)
        if let months = WarrantyDuration.allCases.first(where: { $0.months == settings.defaultWarrantyMonths }) {
            self.warrantyDuration = months
        }
    }

    // MARK: - Step Navigation

    func nextStep() {
        guard currentStep < 2 else { return }
        currentStep += 1
    }

    func previousStep() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    // MARK: - OCR Processing

    func processReceiptImage(_ image: UIImage) {
        receiptImages.append(image)

        guard let cgImage = image.cgImage else { return }

        isProcessingOCR = true

        ocrService.recognizeDate(from: cgImage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] date in
                guard let self else { return }
                self.isProcessingOCR = false
                if let date {
                    self.detectedDate = date
                    self.purchaseDate = date
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Save

    func save() -> Bool {
        guard canSave else { return false }
        isSaving = true

        let itemID = UUID()
        var fileNames: [String] = []

        for (index, image) in receiptImages.enumerated() {
            let fileName = "receipt_\(index).jpg"
            fileNames.append(fileName)

            if let compressed = photoService.compressImage(image, quality: settings.photoQuality) {
                try? storageService.saveReceiptImage(compressed, for: itemID, fileName: fileName)
            }

            if let thumbnail = photoService.createThumbnail(image, size: CGSize(width: 200, height: 200)) {
                try? storageService.saveThumbnail(thumbnail, for: itemID, fileName: fileName)
            }
        }

        let parsedPrice = Double(price.replacingOccurrences(of: ",", with: "."))
        let reminderOffsets = remindBeforeExpiry ? Array(selectedReminderOffsets).sorted(by: >) : []

        let item = WarrantyItem(
            id: itemID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            store: store.nilIfEmpty,
            brand: brand.nilIfEmpty,
            category: category,
            purchaseDate: purchaseDate,
            expiryDate: expiryDate,
            price: parsedPrice,
            currency: selectedCurrency,
            serialNumber: serialNumber.nilIfEmpty,
            notes: notes.nilIfEmpty,
            receiptFileNames: fileNames,
            reminderOffsets: reminderOffsets
        )

        do {
            try storageService.save(item)
            if remindBeforeExpiry {
                notificationService.scheduleNotifications(for: item)
            }
            isSaving = false
            return true
        } catch {
            isSaving = false
            return false
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
