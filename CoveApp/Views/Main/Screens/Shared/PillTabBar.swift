import SwiftUI

struct PillTabBar: View {
    let titles: [String]
    @Binding var selectedIndex: Int
    var height: CGFloat = 32
    var spacing: CGFloat = 8
    var pillColor: Color = Colors.primaryDark
    var textColor: Color = Colors.primaryDark
    var selectedTextColor: Color = .white
    var font: Font = .LibreBodoni(size: 16)
    var badges: [Bool] = [] // Array of boolean values indicating if each tab should show a red dot

    var body: some View {
        GeometryReader { geometry in
            let tabCount = titles.count
            let totalSpacing = CGFloat(max(tabCount - 1, 0)) * spacing
            // Prevent negative / non-finite values during initial layout when width may be zero
            let rawWidth = (geometry.size.width - totalSpacing) / CGFloat(tabCount == 0 ? 1 : tabCount)
            let tabWidth = max(rawWidth, 0)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(pillColor)
                    .frame(width: tabWidth, height: height)
                    .offset(x: CGFloat(selectedIndex) * (tabWidth + spacing), y: 0)
                    .animation(.easeInOut(duration: 0.4), value: selectedIndex)
                HStack(spacing: spacing) {
                    ForEach(titles.indices, id: \.self) { idx in
                        Button(action: { selectedIndex = idx }) {
                            Text(titles[idx])
                                .font(font)
                                .foregroundColor(selectedIndex == idx ? selectedTextColor : textColor)
                                .frame(width: tabWidth, height: height)
                                .overlay(alignment: .topTrailing) {
                                    if idx < badges.count && badges[idx] {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 10, height: 10)
                                            .padding(.top, 2)
                                            .padding(.trailing, 6)
                                    }
                                }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .frame(height: height)
    }
}

#Preview {
    PillTabBarPreview()
}

private struct PillTabBarPreview: View {
    @State private var selected = 1
    var body: some View {
        VStack(spacing: 20) {
            PillTabBar(titles: ["one", "two", "three"], selectedIndex: $selected)
                .padding()
            
            PillTabBar(
                titles: ["friends", "mutuals", "requests"], 
                selectedIndex: $selected,
                badges: [false, false, true] // Show red dot on requests tab
            )
            .padding()
        }
    }
}
