//
//  Fonts.swift
//  Cove
//
//  Created by Sheng Moua on 4/21/25.
//

import SwiftUI

// example: Text("Hello World").font(Fonts.libreBodoni(size: 28))
enum Fonts {
    static func libreBodoni(size: CGFloat) -> Font {
        Font.custom("LibreBodoni-Regular", size: size)
    }
}
