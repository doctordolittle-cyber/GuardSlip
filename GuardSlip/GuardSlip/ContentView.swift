import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isOnboardingComplete = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    let storageService: StorageServiceProtocol
    let notificationService: NotificationServiceProtocol
    let ocrService: OCRServiceProtocol
    let photoService: PhotoServiceProtocol

    @StateObject private var itemsViewModel: ItemsViewModel
    @StateObject private var timelineViewModel: TimelineViewModel
    @StateObject private var settingsViewModel: SettingsViewModel

    init(
        storageService: StorageServiceProtocol,
        notificationService: NotificationServiceProtocol,
        ocrService: OCRServiceProtocol,
        photoService: PhotoServiceProtocol
    ) {
        self.storageService = storageService
        self.notificationService = notificationService
        self.ocrService = ocrService
        self.photoService = photoService

        _itemsViewModel = StateObject(wrappedValue: ItemsViewModel(
            storageService: storageService,
            notificationService: notificationService
        ))
        _timelineViewModel = StateObject(wrappedValue: TimelineViewModel(
            storageService: storageService
        ))
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(
            storageService: storageService
        ))
    }

    var body: some View {
        ZStack {
            Color("BackgroundPrimary").ignoresSafeArea()

            if !isOnboardingComplete {
                OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                    .transition(.opacity)
            } else {
                mainTabView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isOnboardingComplete)
        .preferredColorScheme(colorScheme)
    }

    private var mainTabView: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case 0:
                    ItemsView(
                        viewModel: itemsViewModel,
                        storageService: storageService,
                        notificationService: notificationService,
                        ocrService: ocrService,
                        photoService: photoService
                    )
                case 1:
                    TimelineView(viewModel: timelineViewModel)
                case 2:
                    SettingsView(viewModel: settingsViewModel)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }

    private var colorScheme: ColorScheme? {
        switch settingsViewModel.settings.appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
