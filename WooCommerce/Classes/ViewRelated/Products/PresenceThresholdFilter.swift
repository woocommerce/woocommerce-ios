import Foundation

final class PresenceThresholdFilter<T: Equatable> {
    private var values: [T]
    private let threshold: Double
    private let numberOfPastValues: Int

    init(values: [T] = [], threshold: Double, outOf numberOfPastValues: Int) {
        self.values = values
        self.threshold = threshold
        self.numberOfPastValues = numberOfPastValues
    }

    /// Appends the new value to the existing value sequence, and returns the latest value.
    func append(value: T) -> T? {
        self.values.append(value)
        self.values = values.suffix(numberOfPastValues)

        guard values.count > 1 else {
            return value
        }

        let repeatedValueCount = values.map({ $0 == value }).filter({$0}).count

        guard repeatedValueCount > 1 else {
            return value
        }

        let valueFrequency = Double(repeatedValueCount) / Double(values.count)
        if valueFrequency >= threshold {
            return nil
        }

        return value
    }
}
