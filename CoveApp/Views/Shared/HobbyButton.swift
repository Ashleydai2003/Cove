//
//  HobbyButton.swift
//  Cove
//
//  Shared hobby button component for use across onboarding and profile views

import SwiftUI

// MARK: - Hobby Button Component

struct HobbyButton: View {
    let text: String
    let emoji: String
    let isSelected: Bool
    let borderWidth: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 16))
                    .fixedSize()

                Text(text)
                    .font(.LibreBodoni(size: 14))
                    .foregroundColor(isSelected ? .white : Colors.primaryDark)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .layoutPriority(1)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Colors.primaryDark : Colors.hobbyBackground)
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Colors.primaryDark, lineWidth: borderWidth)
            )
        }
    }
} 