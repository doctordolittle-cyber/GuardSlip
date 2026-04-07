import SwiftUI

struct ReviewSaveStep: View {
    @ObservedObject var viewModel: AddItemViewModel
    let onDismiss: () -> Void
    @State private var showSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Review Your Warranty")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color("AccentPrimary"))
                    .padding(.top, 8)

                summaryCard

                if !viewModel.receiptImages.isEmpty {
                    receiptSection
                }

                reminderSection

                GoldButton(
                    title: "Save Warranty",
                    icon: "checkmark.shield.fill",
                    isLoading: viewModel.isSaving,
                    isFullWidth: true
                ) {
                    saveItem()
                }
                .padding(.top, 8)
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .overlay {
            if showSuccess {
                successOverlay
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.category.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("AccentPrimary"))
                    .frame(width: 40, height: 40)
                    .background(Color("AccentPrimary").opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.name.isEmpty ? "Untitled" : viewModel.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color("TextPrimary"))

                    if !viewModel.store.isEmpty || !viewModel.brand.isEmpty {
                        Text([viewModel.store, viewModel.brand].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.system(size: 13))
                            .foregroundColor(Color("TextSecondary"))
                    }
                }
            }

            divider

            detailRow(label: "Category", value: viewModel.category.displayName)
            detailRow(label: "Purchase Date", value: viewModel.purchaseDate.formattedMono, isMono: true)
            detailRow(label: "Expiry Date", value: viewModel.expiryDate.formattedMono, isMono: true)
            detailRow(label: "Duration", value: durationText)

            if !viewModel.price.isEmpty {
                detailRow(label: "Price", value: viewModel.price, isMono: true)
            }

            if !viewModel.serialNumber.isEmpty {
                detailRow(label: "Serial Number", value: viewModel.serialNumber, isMono: true)
            }

            if !viewModel.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color("TextTertiary"))
                    Text(viewModel.notes)
                        .font(.system(size: 13))
                        .foregroundColor(Color("TextSecondary"))
                        .lineLimit(3)
                }
            }
        }
        .padding(18)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color("AccentPrimary"))
                .frame(width: 3)
                .padding(.vertical, 12)
        }
    }

    private var durationText: String {
        if viewModel.warrantyDuration == .custom {
            let days = Calendar.current.dateComponents([.day], from: viewModel.purchaseDate, to: viewModel.expiryDate).day ?? 0
            return "\(days) days"
        }
        return viewModel.warrantyDuration.rawValue
    }

    private func detailRow(label: String, value: String, isMono: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color("TextTertiary"))
                .frame(width: 110, alignment: .leading)

            Text(value)
                .font(.system(size: 13, weight: .medium, design: isMono ? .monospaced : .default))
                .foregroundColor(Color("TextPrimary"))

            Spacer()
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color("DividerColor"))
            .frame(height: 0.5)
    }

    private var receiptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Receipt Photos (\(viewModel.receiptImages.count))")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color("TextSecondary"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.receiptImages.indices, id: \.self) { index in
                        Image(uiImage: viewModel.receiptImages[index])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.remindBeforeExpiry ? "bell.fill" : "bell.slash")
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.remindBeforeExpiry ? Color("AccentPrimary") : Color("TextTertiary"))

                Text(viewModel.remindBeforeExpiry ? "Reminders enabled" : "No reminders")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("TextSecondary"))
            }

            if viewModel.remindBeforeExpiry {
                HStack(spacing: 6) {
                    ForEach(Array(viewModel.selectedReminderOffsets).sorted(by: >), id: \.self) { offset in
                        Text("\(offset)d before")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color("AccentPrimary"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("AccentPrimary").opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func saveItem() {
        let success = viewModel.save()
        if success {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showSuccess = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color("BackgroundPrimary").opacity(0.9).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("AccentPrimary"), Color("AccentSecondary")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Warranty Saved!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color("TextPrimary"))

                Text("Your warranty has been added successfully.")
                    .font(.system(size: 14))
                    .foregroundColor(Color("TextSecondary"))
            }
            .scaleEffect(showSuccess ? 1.0 : 0.5)
            .opacity(showSuccess ? 1.0 : 0)
        }
        .transition(.opacity)
    }
}
