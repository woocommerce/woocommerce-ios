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

    // Returns the weight plus the unit. The weight can be zero in case the value is `nil`.
    func formatWeight(weight: String?) -> String {
        guard withSpace else {
            return (weight ?? "0") + weightUnit
        }
        return (weight ?? "0") + " " + weightUnit
    }
}
