import SwiftUI

struct ItemsView: View {
    @ObservedObject var viewModel: ItemsViewModel
    let storageService: StorageServiceProtocol
    let notificationService: NotificationServiceProtocol
    let ocrService: OCRServiceProtocol
    let photoService: PhotoServiceProtocol

    @State private var selectedItem: WarrantyItem?
    @State private var navigateToDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundPrimary").ignoresSafeArea()

                if viewModel.items.isEmpty {
                    EmptyStateView(
                        icon: "shield",
                        title: "No items yet",
                        message: "Tap + to add your first warranty.",
                        buttonTitle: "Add Warranty",
                        buttonIcon: "plus"
                    ) {
                        viewModel.showingAddItem = true
                    }
                } else {
                    mainContent
                }

                fabButton
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToDetail) {
                if let item = selectedItem {
                    ItemDetailView(
                        item: item,
                        storageService: storageService,
                        notificationService: notificationService,
                        ocrService: ocrService,
                        photoService: photoService
                    )
                }
            }
            .sheet(isPresented: $viewModel.showingFilterSheet) {
                FilterSortSheet(
                    statusFilter: $viewModel.statusFilter,
                    selectedCategory: $viewModel.selectedCategory,
                    sortOption: $viewModel.sortOption
                )
            }
            .fullScreenCover(isPresented: $viewModel.showingAddItem) {
                AddItemFlowView(
                    storageService: storageService,
                    notificationService: notificationService,
                    ocrService: ocrService,
                    photoService: photoService,
                    settings: storageService.loadSettings()
                )
            }
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                searchSection
                SummaryCardsView(
                    activeCount: viewModel.activeCount,
                    expiringCount: viewModel.expiringCount,
                    expiredCount: viewModel.expiredCount
                )
                itemsList
            }
            .padding(.bottom, 100)
        }
    }

    private var headerSection: some View {
        HStack {
            Text("My Warranties")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(Color("AccentPrimary"))

            Spacer()

            Button {
                viewModel.showingFilterSheet = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(hasActiveFilters ? Color("AccentPrimary") : Color("TextSecondary"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var hasActiveFilters: Bool {
        viewModel.statusFilter != .all || viewModel.selectedCategory != nil || viewModel.sortOption != .expiryDate
    }

    private var searchSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color("TextTertiary"))

            TextField("Search warranties...", text: $viewModel.searchText)
                .font(.system(size: 15))
                .foregroundColor(Color("TextPrimary"))
                .autocorrectionDisabled()

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color("TextTertiary"))
                }
            }
        }
        .padding(12)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
    }

    private var itemsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.filteredItems) { item in
                Button {
                    selectedItem = item
                    navigateToDetail = true
                } label: {
                    WarrantyCardView(item: item)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        viewModel.deleteItem(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var fabButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    viewModel.showingAddItem = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color("AccentPrimary"), Color("AccentSecondary")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color("AccentPrimary").opacity(0.4), radius: 10, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
