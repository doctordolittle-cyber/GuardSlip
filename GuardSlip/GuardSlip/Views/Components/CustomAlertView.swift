import SwiftUI

struct AlertButton {
    let title: String
    let action: () -> Void
}

struct CustomAlertView: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let primaryButton: AlertButton
    var secondaryButton: AlertButton?

    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 20) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(Color("AccentPrimary"))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                VStack(spacing: 10) {
                    Button {
                        primaryButton.action()
                        dismiss()
                    } label: {
                        Text(primaryButton.title)
                            .font(.system(size: 15, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color("AccentPrimary"))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    if let secondaryButton {
                        Button {
                            secondaryButton.action()
                            dismiss()
                        } label: {
                            Text(secondaryButton.title)
                                .font(.system(size: 15, weight: .medium, design: .default))
                                .foregroundColor(Color("TextSecondary"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                }
            }
            .padding(24)
            .background(Color("BackgroundTertiary"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 40)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.85
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}
