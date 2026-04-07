import SwiftUI

struct CircularProgressRing<Content: View>: View {
    let progress: Double
    var lineWidth: CGFloat = 6
    var size: CGFloat = 50
    let content: Content

    @State private var animatedProgress: Double = 0

    init(
        progress: Double,
        lineWidth: CGFloat = 6,
        size: CGFloat = 50,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.content = content()
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color("DividerColor").opacity(0.3),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    gradientForProgress,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            content
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = min(max(progress, 0), 1)
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = min(max(newValue, 0), 1)
            }
        }
    }

    private var gradientForProgress: AngularGradient {
        let colors: [Color]
        if progress < 0.6 {
            colors = [Color("AccentSecondary"), Color("AccentSecondary")]
        } else if progress < 0.85 {
            colors = [Color("AccentSecondary"), Color("AccentPrimary")]
        } else {
            colors = [Color("AccentPrimary"), Color("StatusExpired")]
        }
        return AngularGradient(
            gradient: Gradient(colors: colors),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * animatedProgress)
        )
    }
}
