//
//  TopIconBar.swift
//  Cove
//

import SwiftUI

/// A reusable top bar with a left back chevron and a right gear icon.
/// - Matches spacing and hit-target sizing used in Cove screens.
struct TopIconBar: View {
    var showBackArrow: Bool = true
    var showGear: Bool = true
    let onBackTapped: () -> Void
    let onGearTapped: () -> Void

    var body: some View {
        HStack {
            if showBackArrow {
                Button(action: { onBackTapped() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Colors.primaryDark)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .padding(.leading, 8)
            } else {
                // Keep layout consistent even without back arrow
                Color.clear.frame(width: 44).padding(.leading, 8)
            }

            Spacer()

            if showGear {
                Button(action: { onGearTapped() }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(TintOnPressIconStyle())
                .padding(.trailing, 8)
            } else {
                Color.clear.frame(width: 44).padding(.trailing, 8)
            }
        }
    }
}

// MARK: - Icon tint on press (matches usage in Cove headers)
private struct TintOnPressIconStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(Colors.primaryDark.opacity(configuration.isPressed ? 0.5 : 1.0))
    }
}


