import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundPrimary").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        appIconSection
                        descriptionSection
                        linksSection
                        creditsSection
                    }
                    .padding(24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color("TextSecondary"))
                            .frame(width: 28, height: 28)
                            .background(Color("BackgroundSecondary"))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var appIconSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color("AccentPrimary"), Color("AccentSecondary")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "shield.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text("GuardSlip")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color("TextPrimary"))

                Text("Version 1.0 (1)")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("TextTertiary"))
            }
        }
        .padding(.top, 8)
    }

    private var descriptionSection: some View {
        Text("GuardSlip helps you track warranties and receipts. Keep all your purchase information in one place, get timely reminders, and never miss a warranty claim.")
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(Color("TextSecondary"))
            .multilineTextAlignment(.center)
            .lineSpacing(5)
            .padding(.horizontal, 8)
    }

    private var linksSection: some View {
        VStack(spacing: 0) {
            aboutRow(icon: "star.fill", title: "Rate App", subtitle: "If you enjoy GuardSlip, please leave a review") {}
            rowDivider
            aboutRow(icon: "square.and.arrow.up", title: "Share App", subtitle: "Tell your friends about GuardSlip") {}
            rowDivider
            aboutRow(icon: "lock.shield.fill", title: "Privacy Policy", subtitle: "Your data stays on your device") {}
        }
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var creditsSection: some View {
        VStack(spacing: 8) {
            Text("Made with care")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color("TextTertiary"))

            Text("100% local. No server. No tracking.")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color("TextTertiary"))
        }
    }

    private func aboutRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color("AccentPrimary"))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Color("TextTertiary"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("TextTertiary"))
            }
            .padding(16)
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color("DividerColor"))
            .frame(height: 0.5)
            .padding(.leading, 54)
    }
}
