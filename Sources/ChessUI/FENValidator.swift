//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
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
