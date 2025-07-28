import Foundation

/// Min/Max Quantities. Sync values to API requirements
/// https://woocommerce.com/document/minmax-quantities/#section-6
///
extension Optional where Wrapped == String {
    var refinedMinMaxQuantityEmptyValue: String? {
        guard let self = self else {
            return nil
        }

        return self.isEmpty ? "0" : self
    }
}
