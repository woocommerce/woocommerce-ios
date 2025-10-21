import Foundation
import Observation

/// A helper method for continuously tracking observations on a value.
///
public func withObservationTracking<T: Sendable>(of value: @Sendable @escaping @autoclosure () -> T, execute: @Sendable @escaping (T) -> Void) {
    Observation.withObservationTracking {
        execute(value())
    } onChange: {
        DispatchQueue.main.async {
            withObservationTracking(of: value(), execute: execute)
        }
    }
}
