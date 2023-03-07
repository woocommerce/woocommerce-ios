import Foundation

/// The purpose of this class is to detect repeated values in a data stream to compare with a given frequency threshold.
///
/// For example: when scanning barcodes, the same barcodes are detected for a continuous number of frames if the camera is still capturing similar frames.
/// To prevent triggering the handling of repeated barcodes, this class keeps track of a given number of latest values and returns `nil` when a new value has
/// been repeated more than the given frequency threshold.
///
final class PresenceThresholdFilter<T: Equatable> {
    private var values: [T]
    private let threshold: Double
    private let numberOfPastValues: Int

    /// - Parameters:
    ///   - values: an initial collection of values.
    ///   - threshold: the highest frequency a value can be repeated in the given number of past values.
    ///   - numberOfPastValues: how many latest values (including the new value) to calculate the frequency of repeated value.
    init(values: [T] = [], threshold: Double, outOf numberOfPastValues: Int) {
        self.values = values
        self.threshold = threshold
        self.numberOfPastValues = numberOfPastValues
    }

    /// Appends the new value to the existing value sequence, and returns the latest value.
    /// If the new value has been repeated over the given frequency threshold, `nil` is returned.
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
        if valueFrequency > threshold {
            return nil
        }

        return value
    }
}
