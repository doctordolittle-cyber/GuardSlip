import SwiftUI

struct FilterSortSheet: View {
    @Binding var statusFilter: StatusFilter
    @Binding var selectedCategory: Category?
    @Binding var sortOption: SortOption
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    statusSection
                    categorySection
                    sortSection
                }
                .padding(20)
            }
            .background(Color("BackgroundPrimary"))
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        statusFilter = .all
                        selectedCategory = nil
                        sortOption = .expiryDate
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color("TextSecondary"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Apply")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color("AccentPrimary"))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Status")

            FlowLayout(spacing: 10) {
                ForEach(StatusFilter.allCases, id: \.rawValue) { filter in
                    chipButton(
                        title: filter.rawValue,
                        isSelected: statusFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            statusFilter = filter
                        }
                    }
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Category")

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 10)
            ], spacing: 10) {
                ForEach(Category.allCases) { category in
                    categoryChip(category)
                }
            }
        }
    }

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Sort by")

            FlowLayout(spacing: 10) {
                ForEach(SortOption.allCases, id: \.rawValue) { option in
                    chipButton(
                        title: option.rawValue,
                        isSelected: sortOption == option
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            sortOption = option
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Color("AccentPrimary"))
            .textCase(.uppercase)
            .tracking(1)
    }

    private func chipButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Color("BackgroundPrimary") : Color("TextSecondary"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color("AccentPrimary") : Color("BackgroundSecondary"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color("DividerColor"), lineWidth: 0.5)
                )
        }
    }

    private func categoryChip(_ category: Category) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = isSelected ? nil : category
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.system(size: 11))
                Text(category.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? Color("AccentPrimary") : Color("TextSecondary"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color("BackgroundSecondary"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color("AccentPrimary") : Color("DividerColor"), lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
