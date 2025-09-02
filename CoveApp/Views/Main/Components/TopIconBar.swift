//
//  TopIconBar.swift
//  Cove
//

import SwiftUI

/// A reusable top bar with a left back chevron and a right gear icon.
/// - Matches spacing and hit-target sizing used in Cove screens.
struct TopIconBar: View {
    let onBackTapped: () -> Void
    let onGearTapped: () -> Void

    var body: some View {
        HStack {
            Button(action: { onBackTapped() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Colors.primaryDark)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .padding(.leading, 8)

            Spacer()

            Button(action: { onGearTapped() }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(TintOnPressIconStyle())
            .padding(.trailing, 8)
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


