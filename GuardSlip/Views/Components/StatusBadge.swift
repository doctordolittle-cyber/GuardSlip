import SwiftUI

struct StatusBadge: View {
    let status: WarrantyStatus

    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 4) {
            statusIcon
            statusLabel
        }
        .font(.system(size: 11, weight: .semibold, design: .default))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(status.colorName).opacity(0.15))
        .clipShape(Capsule())
        .onAppear {
            if status.isExpiringSoon {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .active:
            Text("✓")
                .foregroundColor(Color(status.colorName))
        case .expiringSoon:
            Text("⏳")
                .opacity(isPulsing ? 0.5 : 1.0)
        case .expired:
            Text("✕")
                .foregroundColor(Color(status.colorName))
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch status {
        case .active(let daysLeft):
            HStack(spacing: 3) {
                Text("Active —")
                    .foregroundColor(Color(status.colorName))
                Text("\(daysLeft)d")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(status.colorName))
            }

        case .expiringSoon(let daysLeft):
            HStack(spacing: 3) {
                Text("Expiring —")
                    .foregroundColor(Color(status.colorName))
                    .opacity(isPulsing ? 0.6 : 1.0)
                Text("\(daysLeft)d")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(status.colorName))
                    .opacity(isPulsing ? 0.6 : 1.0)
            }

        case .expired:
            Text("Expired")
                .foregroundColor(Color(status.colorName))
                .strikethrough(true, color: Color(status.colorName).opacity(0.5))
        }
    }
}
