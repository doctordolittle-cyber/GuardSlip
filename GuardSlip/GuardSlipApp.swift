import SwiftUI

@main
struct GuardSlipApp: App {
    private let storageService: StorageServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let ocrService: OCRServiceProtocol
    private let photoService: PhotoServiceProtocol

    init() {
        let storage = StorageService()
        self.storageService = storage
        self.notificationService = NotificationService()
        self.ocrService = OCRService()
        self.photoService = PhotoService()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                storageService: storageService,
                notificationService: notificationService,
                ocrService: ocrService,
                photoService: photoService
            )
        }
    }
}
