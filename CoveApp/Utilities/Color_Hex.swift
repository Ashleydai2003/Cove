//
//  Color_Hex.swift
//  Cove
//
//  Created by Ashley Dai on 4/15/25.
//

import SwiftUI
import Foundation

// Translate hex to valid SwiftUI color representation

extension Color {
    init(hex: String) {
        // Remove any non-alphanumeric characters (# or 0x) from the hex string
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        // Convert string to int; pass by reference
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64

        // Handles errors in the case that string is not valid
        switch hex.count {
            case 6: // RGB (24-bit)
                (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
            default:
                (r, g, b) = (0, 0, 0)
        }

        // Convert components from 255 range to 1 range
        // Does the opacity have to be there?
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
