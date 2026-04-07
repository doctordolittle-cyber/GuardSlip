import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String?
    var buttonIcon: String?
    var buttonAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(Color("AccentPrimary"))
                .shadow(color: Color("AccentPrimary").opacity(0.4), radius: 12, x: 0, y: 4)
                .shadow(color: Color("AccentPrimary").opacity(0.15), radius: 24, x: 0, y: 8)
                .padding(.bottom, 8)

            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(Color("TextPrimary"))

                Text(message)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            if let buttonTitle, let buttonAction {
                GoldButton(
                    title: buttonTitle,
                    icon: buttonIcon,
                    action: buttonAction
                )
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
