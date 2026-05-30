//
// ChessUI provides reusable SwiftUI chess board views and supporting helpers.
//
// See NOTICE.md for upstream attribution and license details.
//
// Copyright (C) 2025, Oğuzhan Eroğlu (https://meowingcat.io)
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import Foundation
import SwiftUI

public protocol ChessBoardColorScheme: Sendable {
    var light: Color { get }
    var dark: Color { get }
    var label: Color { get }
    var selected: Color { get }
    var hinted: Color { get }
    var legalMove: Color { get }
}

public struct ChessBoardColorSchemes {
    public struct Light: ChessBoardColorScheme {
        public var light: Color = Color(red: 0.95, green: 0.95, blue: 0.95)
        public var dark: Color = Color(red: 0.85, green: 0.85, blue: 0.85)
        
        public var label: Color = Color(red: 0.20, green: 0.20, blue: 0.20)
        
        public var selected: Color = Color(red: 0.20, green: 0.80, blue: 0.20)
        public var hinted: Color = Color(red: 0.80, green: 0.20, blue: 0.20)
        public var legalMove: Color = Color(red: 0.30, green: 0.30, blue: 0.30, opacity: 0.4)
        
        public init() {}
    }
    
    public struct Dark: ChessBoardColorScheme {
        public var light: Color = Color(red: 0.20, green: 0.20, blue: 0.20)
        public var dark: Color = Color(red: 0.10, green: 0.10, blue: 0.10)
        
        public var label: Color = Color(red: 0.80, green: 0.80, blue: 0.80)
        
        public var selected: Color = Color(red: 0.20, green: 0.80, blue: 0.20)
        public var hinted: Color = Color(red: 0.80, green: 0.20, blue: 0.20)
        public var legalMove: Color = Color(red: 0.70, green: 0.70, blue: 0.70, opacity: 0.4)
        
        public init() {}
    }
    
    public struct Orange: ChessBoardColorScheme {
        public var light: Color = Color(red: 1.0, green: 0.85, blue: 0.60)
        public var dark: Color = Color(red: 1.0, green: 0.65, blue: 0.25)
        public var label: Color = Color(red: 0.20, green: 0.20, blue: 0.20)
        
        public var selected: Color = Color(red: 0.20, green: 0.80, blue: 0.20)
        public var hinted: Color = Color(red: 0.80, green: 0.20, blue: 0.20)
        public var legalMove: Color = Color(red: 0.30, green: 0.30, blue: 0.30, opacity: 0.4)
        
        public init() {}
    }
    
    public struct Blue: ChessBoardColorScheme {
        public var light: Color = Color(red: 0.85, green: 0.95, blue: 1.0)
        public var dark: Color = Color(red: 0.55, green: 0.75, blue: 1.0)
        
        public var label: Color = Color(red: 0.20, green: 0.20, blue: 0.20)
        
        public var selected: Color = Color(red: 0.20, green: 0.80, blue: 0.20)
        public var hinted: Color = Color(red: 0.80, green: 0.20, blue: 0.20)
        public var legalMove: Color = Color(red: 0.30, green: 0.30, blue: 0.30, opacity: 0.4)
        
        public init() {}
    }
    
    public struct Green: ChessBoardColorScheme {
        public var light: Color = Color(red: 0.85, green: 1.0, blue: 0.85)
        public var dark: Color = Color(red: 0.55, green: 1.0, blue: 0.55)
        
        public var label: Color = Color(red: 0.20, green: 0.20, blue: 0.20)
        
        public var selected: Color = Color(red: 0.20, green: 0.80, blue: 0.20)
        public var hinted: Color = Color(red: 0.80, green: 0.20, blue: 0.20)
        public var legalMove: Color = Color(red: 0.30, green: 0.30, blue: 0.30, opacity: 0.4)
        
        public init() {}
    }
    
    public struct Red: ChessBoardColorScheme {
        public var light: Color = Color(red: 1.0, green: 0.85, blue: 0.85)
        public var dark: Color = Color(red: 1.0, green: 0.55, blue: 0.55)
        
        public var label: Color = Color(red: 0.20, green: 0.20, blue: 0.20)
        
        public var selected: Color = Color(red: 0.20, green: 0.80, blue: 0.20)
        public var hinted: Color = Color(red: 0.80, green: 0.20, blue: 0.20)
        public var legalMove: Color = Color(red: 0.30, green: 0.30, blue: 0.30, opacity: 0.4)
        
        public init() {}
    }
    
    public struct Yellow: ChessBoardColorScheme {
        public var light: Color = Color(red: 1.0, green: 1.0, blue: 0.85)
        public var dark: Color = Color(red: 1.0, green: 1.0, blue: 0.55)
        
        public var label: Color = Color(red: 0.20, green: 0.20, blue: 0.20)
        
        public var selected: Color = Color(red: 0.20, green: 0.80, blue: 0.20)
        public var hinted: Color = Color(red: 0.80, green: 0.20, blue: 0.20)
        public var legalMove: Color = Color(red: 0.30, green: 0.30, blue: 0.30, opacity: 0.4)
        
        public init() {}
    }
    
    public struct Purple: ChessBoardColorScheme {
        public var light: Color = Color(red: 0.85, green: 0.85, blue: 1.0)
        public var dark: Color = Color(red: 0.55, green: 0.55, blue: 1.0)
        
        public var label: Color = Color(red: 0.20, green: 0.20, blue: 0.20)
        
        public var selected: Color = Color(red: 0.20, green: 0.80, blue: 0.20)
        public var hinted: Color = Color(red: 0.80, green: 0.20, blue: 0.20)
        public var legalMove: Color = Color(red: 0.30, green: 0.30, blue: 0.30, opacity: 0.4)
        
        public init() {}
    }
    
    public static let light = Light()
    public static let dark = Dark()
    public static let orange = Orange()
    public static let blue = Blue()
    public static let green = Green()
    public static let red = Red()
    public static let yellow = Yellow()
    public static let purple = Purple()
}

public extension ChessBoardColorScheme where Self == ChessBoardColorSchemes.Light {
    static var light: ChessBoardColorSchemes.Light { ChessBoardColorSchemes.light }
}

public extension ChessBoardColorScheme where Self == ChessBoardColorSchemes.Dark {
    static var dark: ChessBoardColorSchemes.Dark { ChessBoardColorSchemes.dark }
}

public extension ChessBoardColorScheme where Self == ChessBoardColorSchemes.Orange {
    static var orange: ChessBoardColorSchemes.Orange { ChessBoardColorSchemes.orange }
}

public extension ChessBoardColorScheme where Self == ChessBoardColorSchemes.Blue {
    static var blue: ChessBoardColorSchemes.Blue { ChessBoardColorSchemes.blue }
}

public extension ChessBoardColorScheme where Self == ChessBoardColorSchemes.Green {
    static var green: ChessBoardColorSchemes.Green { ChessBoardColorSchemes.green }
}

public extension ChessBoardColorScheme where Self == ChessBoardColorSchemes.Red {
    static var red: ChessBoardColorSchemes.Red { ChessBoardColorSchemes.red }
}

public extension ChessBoardColorScheme where Self == ChessBoardColorSchemes.Yellow {
    static var yellow: ChessBoardColorSchemes.Yellow { ChessBoardColorSchemes.yellow }
}

public extension ChessBoardColorScheme where Self == ChessBoardColorSchemes.Purple {
    static var purple: ChessBoardColorSchemes.Purple { ChessBoardColorSchemes.purple }
}
