import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0
    @State private var animateIcon = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "shield.fill",
            title: "All warranties in one place.",
            description: "Snap a photo of your receipt, add warranty details — never lose a claim again.",
            animationType: .glow
        ),
        OnboardingPage(
            icon: "bell.fill",
            title: "Smart reminders.",
            description: "Get notified before warranties expire so you can act in time.",
            animationType: .rock
        ),
        OnboardingPage(
            icon: "camera.viewfinder",
            title: "Scan & go.",
            description: "OCR reads the date from your receipt automatically.",
            animationType: .scan
        )
    ]

    var body: some View {
        ZStack {
            Color("BackgroundPrimary").ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        onboardingPageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                pageIndicator
                    .padding(.bottom, 32)

                bottomButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
        .onChange(of: currentPage) { _ in
            animateIcon = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation { animateIcon = true }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                animateIcon = true
            }
        }
    }

    private func onboardingPageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color("AccentSecondary").opacity(page.animationType == .glow && animateIcon ? 0.15 : 0.05))
                    .frame(width: 160, height: 160)
                    .blur(radius: page.animationType == .glow && animateIcon ? 20 : 10)
                    .scaleEffect(page.animationType == .glow && animateIcon ? 1.2 : 0.9)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateIcon)

                Image(systemName: page.icon)
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("AccentPrimary"), Color("AccentSecondary")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(page.animationType == .rock && animateIcon ? .degrees(10) : .degrees(0))
                    .animation(
                        page.animationType == .rock
                        ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                        : .default,
                        value: animateIcon
                    )
                    .overlay {
                        if page.animationType == .scan {
                            scanLineOverlay
                        }
                    }
            }

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(Color("AccentPrimary"))
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
            }

            Spacer()
            Spacer()
        }
    }

    private var scanLineOverlay: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color("AccentSecondary").opacity(0),
                        Color("AccentSecondary").opacity(0.7),
                        Color("AccentSecondary").opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 60, height: 2)
            .offset(y: animateIcon ? 25 : -25)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateIcon)
    }

    private var pageIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color("AccentPrimary") : Color("TextTertiary"))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }

    @ViewBuilder
    private var bottomButton: some View {
        if currentPage == pages.count - 1 {
            GoldButton(title: "Get Started", isFullWidth: true) {
                requestNotificationPermission()
                completeOnboarding()
            }
        } else {
            GoldButton(title: "Next", isFullWidth: true) {
                withAnimation { currentPage += 1 }
            }
        }
    }

    private func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation(.easeInOut(duration: 0.4)) {
            isOnboardingComplete = true
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let animationType: AnimationType

    enum AnimationType {
        case glow, rock, scan
    }
}
