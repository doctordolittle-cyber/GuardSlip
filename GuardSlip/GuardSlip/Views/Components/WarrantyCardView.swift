import SwiftUI

struct WarrantyCardView: View {
    let item: WarrantyItem

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 14) {
            leftContent
            Spacer(minLength: 0)
            rightContent
        }
        .padding(14)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color("AccentPrimary"))
                .frame(width: 3)
                .padding(.vertical, 8)
        }
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var leftContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: item.category.iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("AccentPrimary"))
                    .frame(width: 28, height: 28)
                    .background(Color("AccentPrimary").opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .bold, design: .default))
                        .foregroundColor(Color("TextPrimary"))
                        .lineLimit(1)

                    if let subtitle = itemSubtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(Color("TextSecondary"))
                            .lineLimit(1)
                    }
                }
            }

            if !item.receiptFileNames.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 9))
                    Text("\(item.receiptFileNames.count)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .foregroundColor(Color("TextTertiary"))
                .padding(.leading, 36)
            }
        }
    }

    private var rightContent: some View {
        VStack(spacing: 6) {
            CircularProgressRing(progress: item.progress, lineWidth: 4, size: 40) {
                countdownIcon
            }

            Text(countdownText)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(countdownColor)
                .lineLimit(1)
        }
    }

    private var itemSubtitle: String? {
        [item.store, item.brand].compactMap { $0 }.joined(separator: " · ").nilIfEmpty
    }

    @ViewBuilder
    private var countdownIcon: some View {
        switch item.status {
        case .active:
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color("StatusActive"))
        case .expiringSoon:
            Image(systemName: "exclamationmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color("StatusExpiring"))
        case .expired:
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color("StatusExpired"))
        }
    }

    private var countdownText: String {
        switch item.status {
        case .active(let days), .expiringSoon(let days):
            return "\(days)d"
        case .expired(let days):
            return days == 0 ? "Today" : "-\(days)d"
        }
    }

    private var countdownColor: Color {
        switch item.status {
        case .active: return Color("StatusActive")
        case .expiringSoon: return Color("StatusExpiring")
        case .expired: return Color("StatusExpired")
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
