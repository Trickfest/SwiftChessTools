//
// ChessboardKit is a SwiftUI library for rendering chessboards and pieces.
//
// See the GitHub repo for documentation:
// https://github.com/rohanrhu/ChessboardKit
//
// Copyright (C) 2025, Oğuzhan Eroğlu (https://meowingcat.io)
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import Foundation

public class FenValidation {
    static public func validateFen(_ fen: String) -> Bool {
        let fields = fen.split(separator: " ")
        
        guard fields.count == 6 else { return false }
        
        let piecePlacement = fields.indices.contains(0) ? String(fields[0]) : ""
        let activeColor = fields.indices.contains(1) ? String(fields[1]) : ""
        let castling = fields.indices.contains(2) ? String(fields[2]) : ""
        let enPassant = fields.indices.contains(3) ? String(fields[3]) : ""
        let halfmoveStr = fields.indices.contains(4) ? String(fields[4]) : ""
        let fullmoveStr = fields.indices.contains(5) ? String(fields[5]) : ""
        
        if !isValidPiecePlacement(piecePlacement) {
            return false
        }
        
        if activeColor != "w" && activeColor != "b" {
            return false
        }
        
        if !isValidCastlingAvailability(castling) {
            return false
        }
        
        if !isValidEnPassantSquare(enPassant, activeColor: activeColor) {
            return false
        }
        
        guard let halfmoves = Int(halfmoveStr), halfmoves >= 0 else { return false }
        guard let fullmoves = Int(fullmoveStr), fullmoves > 0 else { return false }
        
        return true
    }

    static private func isValidPiecePlacement(_ placement: String) -> Bool {
        let ranks = placement.split(separator: "/")
        
        guard ranks.count == 8 else { return false }
        
        for rank in ranks {
            var squareCount = 0
            
            for char in rank {
                if let emptySquares = Int(String(char)) {
                    squareCount += emptySquares
                } else if "PNBRQKpnbrqk".contains(char) {
                    squareCount += 1
                } else {
                    return false
                }
            }
            
            if squareCount != 8 {
                return false
            }
        }
        
        return true
    }
    
    static private func isValidCastlingAvailability(_ castling: String) -> Bool {
        if castling == "-" {
            return true
        }
        
        if castling.isEmpty {
            return false
        }
        
        let uniqueChars = Set(castling)
        
        if uniqueChars.count != castling.count {
            return false
        }
        
        for char in castling {
            if !"KQkq".contains(char) {
                return false
            }
        }
        
        return true
    }

    static private func isValidEnPassantSquare(_ square: String, activeColor: String) -> Bool {
        if square == "-" {
            return true
        }
        
        if square.count != 2 {
            return false
        }
        
        guard let fileChar = square.first, let rankChar = square.last else { return false }
        
        if !"abcdefgh".contains(fileChar) {
            return false
        }
        
        guard let rank = Int(String(rankChar)), rank >= 1 && rank <= 8 else { return false }
        
        if (activeColor == "w" && rank != 6) || (activeColor == "b" && rank != 3) {
            return false
        }
        
        return true
    }
}
