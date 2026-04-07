import Foundation
import Combine

final class SettingsViewModel: ObservableObject {

    // MARK: - Settings State

    @Published var settings: AppSettings

    // MARK: - Delete Confirmation Flow

    @Published var showingDeleteConfirm = false
    @Published var showingSecondDeleteConfirm = false

    // MARK: - Export / Import

    @Published var showingExportSheet = false
    @Published var exportURL: URL?
    @Published var showingImportPicker = false

    // MARK: - About

    @Published var showingAbout = false

    // MARK: - Alert

    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showingAlert = false

    // MARK: - Dependencies

    private let storageService: StorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(storageService: StorageServiceProtocol) {
        self.storageService = storageService
        self.settings = storageService.loadSettings()

        storageService.settingsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$settings)

        $settings
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] updatedSettings in
                self?.storageService.saveSettings(updatedSettings)
            }
            .store(in: &cancellables)
    }

    // MARK: - Reminder Offsets

    func toggleReminderOffset(_ offset: Int) {
        if settings.defaultReminderOffsets.contains(offset) {
            settings.defaultReminderOffsets.removeAll { $0 == offset }
        } else {
            settings.defaultReminderOffsets.append(offset)
            settings.defaultReminderOffsets.sort(by: >)
        }
    }

    func isReminderOffsetEnabled(_ offset: Int) -> Bool {
        settings.defaultReminderOffsets.contains(offset)
    }

    // MARK: - Save

    func saveSettings() {
        storageService.saveSettings(settings)
    }

    // MARK: - Export

    func exportData() {
        do {
            let url = try storageService.exportData()
            exportURL = url
            showingExportSheet = true
        } catch {
            presentAlert(title: "Export Failed", message: error.localizedDescription)
        }
    }

    // MARK: - Import

    func importData(from url: URL) {
        do {
            try storageService.importData(from: url)
            presentAlert(title: "Import Successful", message: "Your data has been imported.")
        } catch {
            presentAlert(title: "Import Failed", message: error.localizedDescription)
        }
    }

    // MARK: - Delete All Data

    func requestDeleteAll() {
        showingDeleteConfirm = true
    }

    func confirmFirstDelete() {
        showingDeleteConfirm = false
        showingSecondDeleteConfirm = true
    }

    func confirmFinalDelete() {
        showingSecondDeleteConfirm = false
        do {
            try storageService.deleteAllData()
            presentAlert(title: "Data Deleted", message: "All items and receipts have been removed.")
        } catch {
            presentAlert(title: "Delete Failed", message: error.localizedDescription)
        }
    }

    // MARK: - Alert Helpers

    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}
