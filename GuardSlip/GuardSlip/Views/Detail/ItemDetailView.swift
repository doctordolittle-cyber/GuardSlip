import SwiftUI

struct ItemDetailView: View {
    @StateObject private var viewModel: ItemDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingFullScreenReceipt = false
    @State private var selectedReceiptIndex = 0

    private let storageService: StorageServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let ocrService: OCRServiceProtocol
    private let photoService: PhotoServiceProtocol

    init(
        item: WarrantyItem,
        storageService: StorageServiceProtocol,
        notificationService: NotificationServiceProtocol,
        ocrService: OCRServiceProtocol,
        photoService: PhotoServiceProtocol
    ) {
        self.storageService = storageService
        self.notificationService = notificationService
        self.ocrService = ocrService
        self.photoService = photoService
        _viewModel = StateObject(wrappedValue: ItemDetailViewModel(
            item: item,
            storageService: storageService,
            notificationService: notificationService
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                countdownRingSection
                detailsSection
                receiptsSection
                actionsSection
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Color("BackgroundPrimary"))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(Color("AccentPrimary"))
                }
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .overlay {
            if viewModel.showingDeleteAlert {
                CustomAlertView(
                    isPresented: $viewModel.showingDeleteAlert,
                    title: "Delete Warranty",
                    message: "Are you sure you want to delete \"\(viewModel.item.name)\"? This action cannot be undone.",
                    primaryButton: AlertButton(title: "Delete") {
                        viewModel.deleteItem()
                        dismiss()
                    },
                    secondaryButton: AlertButton(title: "Cancel") {}
                )
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingEditSheet) {
            AddItemFlowView(
                storageService: storageService,
                notificationService: notificationService,
                ocrService: ocrService,
                photoService: photoService,
                settings: storageService.loadSettings()
            )
        }
        .fullScreenCover(isPresented: $showingFullScreenReceipt) {
            ReceiptFullScreenView(
                images: viewModel.receiptImages.map(\.image),
                initialIndex: selectedReceiptIndex
            )
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            let image = viewModel.generateShareImage()
            ShareSheet(items: [image])
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.item.category.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("AccentPrimary"))
                    .frame(width: 44, height: 44)
                    .background(Color("AccentPrimary").opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.item.category.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("TextTertiary"))
                    Text(viewModel.item.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color("AccentPrimary"))
                }
            }

            StatusBadge(status: viewModel.item.status)
        }
    }

    private var countdownRingSection: some View {
        VStack(spacing: 12) {
            CircularProgressRing(progress: viewModel.item.progress, lineWidth: 10, size: 140) {
                VStack(spacing: 2) {
                    Text("\(max(viewModel.item.daysRemaining, 0))")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(viewModel.item.status.colorName))
                    Text("days")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("TextTertiary"))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var detailsSection: some View {
        VStack(spacing: 0) {
            if let store = viewModel.item.store {
                detailRow(icon: "storefront.fill", label: "Store", value: store)
            }
            if let brand = viewModel.item.brand {
                detailRow(icon: "tag.fill", label: "Brand", value: brand)
            }
            if let serial = viewModel.item.serialNumber {
                detailRow(icon: "barcode", label: "Serial Number", value: serial, isMono: true)
            }
            if let price = viewModel.item.price {
                let currency = viewModel.item.currency ?? "USD"
                detailRow(icon: "banknote.fill", label: "Price", value: String(format: "%.2f %@", price, currency), isMono: true)
            }
            detailRow(icon: "calendar", label: "Purchase Date", value: viewModel.item.purchaseDate.formattedMono, isMono: true)
            detailRow(icon: "calendar.badge.clock", label: "Expiry Date", value: viewModel.item.expiryDate.formattedMono, isMono: true)

            if let notes = viewModel.item.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.system(size: 13))
                            .foregroundColor(Color("AccentPrimary"))
                        Text("Notes")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color("TextTertiary"))
                    }
                    Text(notes)
                        .font(.system(size: 13))
                        .foregroundColor(Color("TextSecondary"))
                }
                .padding(14)
            }
        }
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func detailRow(icon: String, label: String, value: String, isMono: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("AccentPrimary"))
                    .frame(width: 20)

                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("TextTertiary"))

                Spacer()

                Text(value)
                    .font(.system(size: 13, weight: .medium, design: isMono ? .monospaced : .default))
                    .foregroundColor(Color("TextPrimary"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color("DividerColor"))
                .frame(height: 0.5)
                .padding(.horizontal, 14)
        }
    }

    @ViewBuilder
    private var receiptsSection: some View {
        if !viewModel.receiptImages.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Receipt Photos")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color("TextSecondary"))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.receiptImages.indices, id: \.self) { index in
                            Button {
                                selectedReceiptIndex = index
                                showingFullScreenReceipt = true
                            } label: {
                                Image(uiImage: viewModel.receiptImages[index].image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 130)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color("DividerColor"), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.showingShareSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Share")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(Color("AccentPrimary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color("BackgroundSecondary"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color("AccentPrimary").opacity(0.3), lineWidth: 1)
                )
            }

            Button {
                viewModel.showingDeleteAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Delete")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(Color("StatusExpired"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color("StatusExpired").opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
