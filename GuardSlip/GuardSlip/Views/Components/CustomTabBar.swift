import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Items"),
        ("calendar.badge.clock", "Timeline"),
        ("gearshape.fill", "Settings")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Color("DividerColor")
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { index in
                    tabButton(index: index)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color("BackgroundSecondary"))
        }
    }

    private func tabButton(index: Int) -> some View {
        let isSelected = selectedTab == index
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .top) {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(isSelected ? Color("AccentPrimary") : .clear)
                            .frame(width: 4, height: 4)

                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 20, weight: .medium))
                    }
                }

                Text(tabs[index].label)
                    .font(.system(size: 10, weight: .medium, design: .default))
            }
            .foregroundColor(isSelected ? Color("AccentPrimary") : Color("TextTertiary"))
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle())
    }
}

private struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
