import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundPrimary").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Settings")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(Color("AccentPrimary"))
                            Spacer()
                        }
                        .padding(.top, 16)

                        remindersSection
                        defaultsSection
                        appearanceSection
                        dataSection
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
        }
        .overlay {
            if viewModel.showingDeleteConfirm {
                CustomAlertView(
                    isPresented: $viewModel.showingDeleteConfirm,
                    title: "Delete All Data",
                    message: "This will permanently remove all warranties, receipts, and settings. This cannot be undone.",
                    primaryButton: AlertButton(title: "Continue") {
                        viewModel.confirmFirstDelete()
                    },
                    secondaryButton: AlertButton(title: "Cancel") {}
                )
            }
            if viewModel.showingSecondDeleteConfirm {
                CustomAlertView(
                    isPresented: $viewModel.showingSecondDeleteConfirm,
                    title: "Are you absolutely sure?",
                    message: "All your warranty data will be permanently deleted. This action is irreversible.",
                    primaryButton: AlertButton(title: "Delete Everything") {
                        viewModel.confirmFinalDelete()
                    },
                    secondaryButton: AlertButton(title: "Cancel") {}
                )
            }
            if viewModel.showingAlert {
                CustomAlertView(
                    isPresented: $viewModel.showingAlert,
                    title: viewModel.alertTitle,
                    message: viewModel.alertMessage,
                    primaryButton: AlertButton(title: "OK") {}
                )
            }
        }
        .sheet(isPresented: $viewModel.showingExportSheet) {
            if let url = viewModel.exportURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(
            isPresented: $viewModel.showingImportPicker,
            allowedContentTypes: [UTType.zip, UTType.archive],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                viewModel.importData(from: url)
            }
        }
        .sheet(isPresented: $viewModel.showingAbout) {
            AboutView()
        }
    }

    private var remindersSection: some View {
        settingsCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Default Reminders", icon: "bell.fill")

                Text("Applied to new warranties. Notify before expiry:")
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextTertiary"))

                HStack(spacing: 8) {
                    ForEach([30, 14, 7, 1], id: \.self) { offset in
                        reminderToggle(offset)
                    }
                }
            }
        }
    }

    private func reminderToggle(_ days: Int) -> some View {
        let isEnabled = viewModel.isReminderOffsetEnabled(days)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.toggleReminderOffset(days)
            }
        } label: {
            Text("\(days)d")
                .font(.system(size: 13, weight: isEnabled ? .bold : .medium, design: .monospaced))
                .foregroundColor(isEnabled ? Color("BackgroundPrimary") : Color("TextSecondary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isEnabled ? Color("AccentPrimary") : Color("BackgroundTertiary"))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var defaultsSection: some View {
        settingsCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Defaults", icon: "slider.horizontal.3")

                HStack {
                    Text("Warranty Duration")
                        .font(.system(size: 14))
                        .foregroundColor(Color("TextPrimary"))
                    Spacer()
                    Picker("", selection: $viewModel.settings.defaultWarrantyMonths) {
                        Text("6 Months").tag(6)
                        Text("1 Year").tag(12)
                        Text("2 Years").tag(24)
                        Text("3 Years").tag(36)
                        Text("5 Years").tag(60)
                    }
                    .pickerStyle(.menu)
                    .tint(Color("AccentPrimary"))
                }

                divider

                HStack {
                    Text("Currency")
                        .font(.system(size: 14))
                        .foregroundColor(Color("TextPrimary"))
                    Spacer()
                    Picker("", selection: $viewModel.settings.currency) {
                        ForEach(CurrencyOption.all) { currency in
                            Text("\(currency.symbol) \(currency.code)").tag(currency.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color("AccentPrimary"))
                }

                divider

                HStack {
                    Text("Photo Quality")
                        .font(.system(size: 14))
                        .foregroundColor(Color("TextPrimary"))
                    Spacer()
                    Picker("", selection: $viewModel.settings.photoQuality) {
                        ForEach(PhotoQuality.allCases, id: \.rawValue) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color("AccentPrimary"))
                }
            }
        }
    }

    private var appearanceSection: some View {
        settingsCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Appearance", icon: "paintbrush.fill")

                HStack(spacing: 8) {
                    ForEach(AppAppearance.allCases, id: \.rawValue) { appearance in
                        let isSelected = viewModel.settings.appearance == appearance
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.settings.appearance = appearance
                            }
                        } label: {
                            Text(appearance.displayName)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? Color("BackgroundPrimary") : Color("TextSecondary"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isSelected ? Color("AccentPrimary") : Color("BackgroundTertiary"))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
            }
        }
    }

    private var dataSection: some View {
        settingsCard {
            VStack(spacing: 0) {
                sectionHeader("Data", icon: "externaldrive.fill")
                    .padding(.bottom, 14)

                settingsButton(icon: "square.and.arrow.up", title: "Export All Data", subtitle: "Create a backup ZIP file") {
                    viewModel.exportData()
                }

                divider

                settingsButton(icon: "square.and.arrow.down", title: "Import Data", subtitle: "Restore from backup") {
                    viewModel.showingImportPicker = true
                }

                divider

                settingsButton(
                    icon: "trash",
                    title: "Delete All Data",
                    subtitle: "Remove all warranties and receipts",
                    isDestructive: true
                ) {
                    viewModel.requestDeleteAll()
                }
            }
        }
    }

    private var aboutSection: some View {
        settingsCard {
            VStack(spacing: 0) {
                sectionHeader("About", icon: "info.circle.fill")
                    .padding(.bottom, 14)

                settingsButton(icon: "doc.text", title: "About GuardSlip", subtitle: "Version 1.0") {
                    viewModel.showingAbout = true
                }
            }
        }
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading) {
            content()
        }
        .padding(16)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color("AccentPrimary"))
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color("AccentPrimary"))
        }
    }

    private func settingsButton(
        icon: String,
        title: String,
        subtitle: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isDestructive ? Color("StatusExpired") : Color("TextSecondary"))
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDestructive ? Color("StatusExpired") : Color("TextPrimary"))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color("TextTertiary"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color("TextTertiary"))
            }
            .padding(.vertical, 10)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color("DividerColor"))
            .frame(height: 0.5)
            .padding(.leading, 32)
    }
}
