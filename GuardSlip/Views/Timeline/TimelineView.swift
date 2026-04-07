import SwiftUI

struct TimelineView: View {
    @ObservedObject var viewModel: TimelineViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundPrimary").ignoresSafeArea()

                if viewModel.hasNoUpcoming && viewModel.expiredItems.isEmpty {
                    happyEmptyState
                } else {
                    mainContent
                }
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("Timeline")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color("AccentPrimary"))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                if viewModel.hasNoUpcoming && !viewModel.expiredItems.isEmpty {
                    happyBanner
                }

                timelineSections
            }
            .padding(.bottom, 100)
        }
    }

    private var timelineSections: some View {
        VStack(spacing: 20) {
            if !viewModel.expiringThisWeek.isEmpty {
                timelineSection(
                    title: "Expiring This Week",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: "StatusExpiring",
                    items: viewModel.expiringThisWeek,
                    isUrgent: true
                )
            }

            if !viewModel.expiringThisMonth.isEmpty {
                timelineSection(
                    title: "Expiring This Month",
                    icon: "clock.fill",
                    iconColor: "StatusExpiring",
                    items: viewModel.expiringThisMonth
                )
            }

            if !viewModel.expiringNext3Months.isEmpty {
                timelineSection(
                    title: "Next 3 Months",
                    icon: "calendar",
                    iconColor: "AccentSecondary",
                    items: viewModel.expiringNext3Months
                )
            }

            if !viewModel.expiringLater.isEmpty {
                timelineSection(
                    title: "Later",
                    icon: "calendar.badge.plus",
                    iconColor: "StatusActive",
                    items: viewModel.expiringLater
                )
            }

            if !viewModel.expiredItems.isEmpty {
                expiredSection
            }
        }
    }

    private func timelineSection(
        title: String,
        icon: String,
        iconColor: String,
        items: [WarrantyItem],
        isUrgent: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(iconColor))

                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color("TextPrimary"))

                Spacer()

                Text("\(items.count)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(iconColor))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(iconColor).opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            ForEach(items) { item in
                TimelineRowView(item: item, isUrgent: isUrgent)
                    .padding(.horizontal, 20)
            }
        }
    }

    private var expiredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.showExpired.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.shield.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color("StatusExpired"))

                    Text("Expired")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color("TextPrimary"))

                    Spacer()

                    Text("\(viewModel.expiredItems.count)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color("StatusExpired"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color("StatusExpired").opacity(0.12))
                        .clipShape(Capsule())

                    Image(systemName: viewModel.showExpired ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color("TextTertiary"))
                }
                .padding(.horizontal, 20)
            }

            if viewModel.showExpired {
                ForEach(viewModel.expiredItems) { item in
                    TimelineRowView(item: item, isExpired: true)
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var happyEmptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color("AccentSecondary").opacity(0.08))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(Color("AccentSecondary"))
            }

            Text("All warranties are safe!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("TextPrimary"))

            Text("Nothing expiring soon.")
                .font(.system(size: 14))
                .foregroundColor(Color("TextSecondary"))

            Spacer()
        }
    }

    private var happyBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color("AccentSecondary"))

            Text("No upcoming expirations — you're all good!")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color("TextSecondary"))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("AccentSecondary").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
    }
}

private struct TimelineRowView: View {
    let item: WarrantyItem
    var isUrgent: Bool = false
    var isExpired: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.category.iconName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color("AccentPrimary"))
                .frame(width: 32, height: 32)
                .background(Color("AccentPrimary").opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isExpired ? Color("TextTertiary") : Color("TextPrimary"))
                    .strikethrough(isExpired, color: Color("StatusExpired"))

                Text(item.expiryDate.formattedMono)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("TextTertiary"))
            }

            Spacer()

            HStack(spacing: 8) {
                CircularProgressRing(progress: item.progress, lineWidth: 3, size: 28) {
                    EmptyView()
                }

                Text(countdownText)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(countdownColor)
            }
        }
        .padding(12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isUrgent ? Color("StatusExpiring").opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var cardBackground: Color {
        if isExpired { return Color("StatusExpired").opacity(0.05) }
        if isUrgent { return Color("StatusExpiring").opacity(0.06) }
        return Color("BackgroundSecondary")
    }

    private var countdownText: String {
        let days = item.daysRemaining
        if days <= 0 { return "Expired" }
        return "\(days)d"
    }

    private var countdownColor: Color {
        switch item.status {
        case .active: return Color("StatusActive")
        case .expiringSoon: return Color("StatusExpiring")
        case .expired: return Color("StatusExpired")
        }
    }
}
