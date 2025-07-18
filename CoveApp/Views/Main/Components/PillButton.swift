//
//  HobbyPill.swift
//  Cove
//
//  Created by Assistant

import SwiftUI

struct HobbyPill: View {
    let text: String
    let emoji: String?
    let isSelected: Bool
    let action: () -> Void

    // Optional customization
    let height: CGFloat
    let cornerRadius: CGFloat
    let selectedColor: Color
    let unselectedColor: Color
    let selectedTextColor: Color
    let unselectedTextColor: Color
    let font: Font

    init(
        text: String,
        emoji: String? = nil,
        isSelected: Bool = false,
        height: CGFloat = 36,
        cornerRadius: CGFloat = 12,
        selectedColor: Color = Colors.primaryDark,
        unselectedColor: Color = .white,
        selectedTextColor: Color = .white,
        unselectedTextColor: Color = .black,
        font: Font = .LeagueSpartan(size: 14),
        action: @escaping () -> Void
    ) {
        self.text = text
        self.emoji = emoji
        self.isSelected = isSelected
        self.height = height
        self.cornerRadius = cornerRadius
        self.selectedColor = selectedColor
        self.unselectedColor = unselectedColor
        self.selectedTextColor = selectedTextColor
        self.unselectedTextColor = unselectedTextColor
        self.font = font
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let emoji = emoji {
                    Text(emoji)
                        .fixedSize()
                }
                Text(text.lowercased())
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .foregroundColor(isSelected ? selectedTextColor : unselectedTextColor)
            .font(font)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isSelected ? selectedColor : unselectedColor)
                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 3)
            )
            .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Static Hobby Pill (non-interactive)
struct StaticHobbyPill: View {
    let text: String
    let emoji: String?
    let height: CGFloat
    let cornerRadius: CGFloat
    let backgroundColor: Color
    let textColor: Color
    let font: Font

    init(
        text: String,
        emoji: String? = nil,
        height: CGFloat = 36,
        cornerRadius: CGFloat = 12,
        backgroundColor: Color = .white,
        textColor: Color = Colors.k6F6F73,
        font: Font = .LeagueSpartan(size: 14)
    ) {
        self.text = text
        self.emoji = emoji
        self.height = height
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.font = font
    }

    var body: some View {
        HStack(spacing: 4) {
            if let emoji = emoji {
                Text(emoji)
                    .fixedSize()
            }
            Text(text.lowercased())
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .foregroundColor(textColor)
        .font(font)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 3)
        )
        .multilineTextAlignment(.center)
    }
}

#Preview {
    VStack(spacing: 16) {
        HobbyPill(text: "Soccer Teams", emoji: "⚽️", isSelected: true) {}

        HobbyPill(text: "Basketball Leagues", emoji: "🏀", isSelected: false) {}

        StaticHobbyPill(text: "Static Hobby", emoji: "✨")
    }
    .padding()
}
