import SwiftUI
import PhotosUI

struct ReceiptScanStep: View {
    @ObservedObject var viewModel: AddItemViewModel
    @State private var showingScanner = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Add Receipt Photo")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color("AccentPrimary"))

                    Text("Scan or import your receipt for automatic date detection")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    optionCard(
                        icon: "camera.fill",
                        title: "Scan Receipt",
                        subtitle: "Use camera with auto edge detection",
                        accentColor: Color("AccentPrimary")
                    ) {
                        showingScanner = true
                    }

                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        optionCardLabel(
                            icon: "photo.on.rectangle.angled",
                            title: "Choose from Gallery",
                            subtitle: "Select up to 5 receipt images",
                            accentColor: Color("AccentSecondary")
                        )
                    }

                    optionCard(
                        icon: "arrow.right",
                        title: "Skip",
                        subtitle: "Add receipt photos later",
                        accentColor: Color("TextTertiary")
                    ) {
                        viewModel.nextStep()
                    }
                }
                .padding(.horizontal, 20)

                if !viewModel.receiptImages.isEmpty {
                    receiptPreviewSection
                }

                if viewModel.isProcessingOCR {
                    ocrProcessingView
                }

                if let date = viewModel.detectedDate {
                    detectedDateBadge(date)
                }
            }
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingScanner) {
            DocumentScannerView { images in
                for image in images {
                    viewModel.processReceiptImage(image)
                }
            }
        }
        .onChange(of: selectedPhotos) { newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            viewModel.processReceiptImage(image)
                        }
                    }
                }
                selectedPhotos = []
            }
        }
    }

    private func optionCard(
        icon: String,
        title: String,
        subtitle: String,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            optionCardLabel(icon: icon, title: title, subtitle: subtitle, accentColor: accentColor)
        }
        .buttonStyle(CardPressStyle())
    }

    private func optionCardLabel(
        icon: String,
        title: String,
        subtitle: String,
        accentColor: Color
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(accentColor)
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("TextPrimary"))
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("TextSecondary"))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color("TextTertiary"))
        }
        .padding(16)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var receiptPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scanned Receipts (\(viewModel.receiptImages.count))")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color("TextSecondary"))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.receiptImages.indices, id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: viewModel.receiptImages[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 90, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            Button {
                                withAnimation { _ = viewModel.receiptImages.remove(at: index) }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color("StatusExpired"))
                                    .clipShape(Circle())
                            }
                            .offset(x: 6, y: -6)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var ocrProcessingView: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(Color("AccentSecondary"))
            Text("Analyzing receipt...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color("TextSecondary"))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(Color("BackgroundSecondary"))
        .clipShape(Capsule())
    }

    private func detectedDateBadge(_ date: Date) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color("AccentSecondary"))
            Text("Date detected: \(date.formattedMono)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(Color("AccentSecondary"))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color("AccentSecondary").opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
