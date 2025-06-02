//
//  Font_Extension.swift
//  Cove
//
//  Created by Ashley Dai on 4/15/25.
//

import SwiftUI


// Custom Fonts
extension Font {
    static func LibreBodoni(size: CGFloat) -> Font {
        return .custom("LibreBodoni-Regular", size: size)
    }
    static func LibreBodoniMedium(size: CGFloat) -> Font {
        return .custom("LibreBodoni-Regular_Medium", size: size)
    }
    static func LibreBodoniBold(size: CGFloat) -> Font {
        return .custom("LibreBodoni-Regular_Bold", size: size)
    }
    
    static func LeagueSpartan(size: CGFloat) -> Font {
        return .custom("LeagueSpartan-Regular", size: size)
    }
    static func LeagueSpartanMedium(size: CGFloat) -> Font {
        return .custom("LeagueSpartan-Medium", size: size)
    }
    static func LeagueSpartanSemiBold(size: CGFloat) -> Font {
        return .custom("LeagueSpartan-SemiBold", size: size)
    }
    
    static func LibreCaslon(size: CGFloat) -> Font {
        return .custom("LibreCaslontext-Regular", size: size)
    }
}
