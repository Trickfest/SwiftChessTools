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
import ChessCore

public class FENValidator {
    public static func isValid(_ fen: String) -> Bool {
        (try? FENSerializer().position(from: fen)) != nil
    }
}
