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
        let weight: String = unwrapWeight(weight: weight)
        guard withSpace else {
            return weight + weightUnit
        }
        return weight + " " + weightUnit
    }
}

// MARK: - Utils
private extension WeightFormatter {
    func unwrapWeight(weight: String?) -> String {
        return (weight == nil || weight?.isEmpty == true) ? "0" : (weight ?? "0")
    }
}
