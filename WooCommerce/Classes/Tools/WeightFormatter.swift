import Foundation

/// Manual weight formatting
///
final class WeightFormatter {

    private let weightUnit: String
    private var withSpace: Bool

    init(weightUnit: String, withSpace: Bool = false) {
        self.weightUnit = weightUnit
        self.withSpace = withSpace
    }

    // Returns the weight plus the unit. The weight can be zero in case the value is `nil` or empty.
    func formatWeight(weight: String?) -> String {
        let weight: String = (weight == nil || weight?.isEmpty == true) ? "0" : (weight ?? "0")
        guard withSpace else {
            return weight + weightUnit
        }
        return weight + " " + weightUnit
    }
}
