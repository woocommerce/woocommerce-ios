import Foundation
import WooFoundation

extension String {
    /// Returns whether the product quantity rule (e.g. mininum or maximum quantities the product can be ordered) has a valid value
    ///
    var isAValidProductQuantityRuleValue: Bool {
        self.isNotEmpty && self != "0"
    }
}
