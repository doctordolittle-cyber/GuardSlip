import SwiftUI

struct AddItemFlowView: View {
    @StateObject private var viewModel: AddItemViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        storageService: StorageServiceProtocol,
        notificationService: NotificationServiceProtocol,
        ocrService: OCRServiceProtocol,
        photoService: PhotoServiceProtocol,
        settings: AppSettings
    ) {
        _viewModel = StateObject(wrappedValue: AddItemViewModel(
            storageService: storageService,
            notificationService: notificationService,
            ocrService: ocrService,
            photoService: photoService,
            settings: settings
        ))
    }

    var body: some View {
        ZStack {
            Color("BackgroundPrimary").ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                stepIndicator
                    .padding(.vertical, 16)

                TabView(selection: $viewModel.currentStep) {
                    ReceiptScanStep(viewModel: viewModel)
                        .tag(0)
                    ItemDetailsStep(viewModel: viewModel)
                        .tag(1)
                    ReviewSaveStep(viewModel: viewModel) {
                        dismiss()
                    }
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

                navigationButtons
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color("TextSecondary"))
                    .frame(width: 32, height: 32)
                    .background(Color("BackgroundSecondary"))
                    .clipShape(Circle())
            }

            Spacer()

            Text(stepTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("TextPrimary"))

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var stepTitle: String {
        switch viewModel.currentStep {
        case 0: return "Receipt Photo"
        case 1: return "Item Details"
        case 2: return "Review"
        default: return ""
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(stepColor(for: index))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(stepBorderColor(for: index), lineWidth: 1.5)
                    )

                if index < 2 {
                    Rectangle()
                        .fill(index < viewModel.currentStep ? Color("AccentSecondary") : Color("DividerColor"))
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal, 60)
    }

    private func stepColor(for index: Int) -> Color {
        if index < viewModel.currentStep {
            return Color("AccentSecondary")
        } else if index == viewModel.currentStep {
            return Color("AccentPrimary")
        }
        return Color("BackgroundTertiary")
    }

    private func stepBorderColor(for index: Int) -> Color {
        if index <= viewModel.currentStep {
            return .clear
        }
        return Color("DividerColor")
    }

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.currentStep > 0 {
                Button {
                    withAnimation { viewModel.previousStep() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(Color("TextSecondary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("BackgroundSecondary"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            if viewModel.currentStep < 2 {
                Button {
                    withAnimation { viewModel.nextStep() }
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.system(size: 15, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color("AccentPrimary"), Color("AccentSecondary")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(viewModel.currentStep == 1 && !viewModel.canSave)
                .opacity(viewModel.currentStep == 1 && !viewModel.canSave ? 0.5 : 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
