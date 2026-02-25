//
//  Font.swift
//  Claudia
//
//  Created by Sherlock LUK on 22/02/2026.
//

import SwiftUI

public extension Font {
    
    static func serifFont(size: CGFloat) -> Font {
        Font.custom("Anthropic Serif Web Text", size: size)
    }
    
    static func sansFont(size: CGFloat) -> Font {
        Font.custom("Anthropic Sans Web Text", size: size)
    }
    
}
