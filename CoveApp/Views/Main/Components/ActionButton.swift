//
//  ActionButton.swift
//  Cove
//
//  Created by Assistant for reusable action buttons

import SwiftUI

/// ActionButton: A reusable button component for actions like "message", "request", "confirm", etc.
/// - Consistent styling across the app
/// - Configurable size and colors
/// - Uses same font size as PillTabBar for consistency
struct ActionButton: View {
    let title: String
    let action: () -> Void

    // Customization options
    let width: CGFloat
    let height: CGFloat
    let backgroundColor: Color
    let textColor: Color
    let font: Font
    let cornerRadius: CGFloat

    // MARK: - Constants
    static let defaultWidth: CGFloat = 120
    static let defaultHeight: CGFloat = 36
    static let defaultCornerRadius: CGFloat = 15
    static let defaultFont: Font = .LibreBodoni(size: 16) // Same as PillTabBar

    init(
        title: String,
        width: CGFloat = ActionButton.defaultWidth,
        height: CGFloat = ActionButton.defaultHeight,
        backgroundColor: Color = Colors.primaryDark,
        textColor: Color = .white,
        font: Font = ActionButton.defaultFont,
        cornerRadius: CGFloat = ActionButton.defaultCornerRadius,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.width = width
        self.height = height
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.font = font
        self.cornerRadius = cornerRadius
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .foregroundColor(textColor)
                .frame(width: width, height: height)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Convenience Initializers

extension ActionButton {
    /// Message button style (default styling for messaging actions)
    static func message(action: @escaping () -> Void) -> ActionButton {
        ActionButton(
            title: "message",
            action: action
        )
    }

    /// Request button style (for friend requests)
    static func request(action: @escaping () -> Void) -> ActionButton {
        ActionButton(
            title: "request",
            action: action
        )
    }

    /// Confirm button style (for accepting requests)
    static func confirm(action: @escaping () -> Void) -> ActionButton {
        ActionButton(
            title: "confirm",
            action: action
        )
    }

    /// Delete button style (for rejecting requests)
    static func delete(action: @escaping () -> Void) -> ActionButton {
        ActionButton(
            title: "delete",
            action: action
        )
    }

    /// Pending button style (for pending states)
    static func pending() -> ActionButton {
        ActionButton(
            title: "pending",
            backgroundColor: Color.gray.opacity(0.3),
            textColor: .primary,
            action: {}
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        ActionButton.message {}
        ActionButton.request {}
        ActionButton.confirm {}
        ActionButton.delete {}
        ActionButton.pending()

        // Custom button
        ActionButton(
            title: "custom",
            width: 120,
            height: 40,
            backgroundColor: .blue,
            textColor: .white
        ) {}
    }
    .padding()
}
