import SwiftUI

struct SummaryCardsView: View {
    let activeCount: Int
    let expiringCount: Int
    let expiredCount: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Active",
                    count: activeCount,
                    icon: "checkmark.shield.fill",
                    colorName: "StatusActive"
                )

                SummaryCard(
                    title: "Expiring Soon",
                    count: expiringCount,
                    icon: "exclamationmark.triangle.fill",
                    colorName: "StatusExpiring"
                )

                SummaryCard(
                    title: "Expired",
                    count: expiredCount,
                    icon: "xmark.shield.fill",
                    colorName: "StatusExpired"
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let count: Int
    let icon: String
    let colorName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(colorName))
                    .frame(width: 32, height: 32)
                    .background(Color(colorName).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()
            }

            Text("\(count)")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(Color("TextPrimary"))

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color("TextSecondary"))
        }
        .padding(14)
        .frame(width: 130)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color("DividerColor"), lineWidth: 0.5)
        )
    }
}
