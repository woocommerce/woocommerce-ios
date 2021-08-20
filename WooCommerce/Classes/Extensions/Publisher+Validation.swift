import Foundation
import Combine

typealias ValidationPublisher = AnyPublisher<Bool, Never>

class ValidationPublishers {
    /// Validates whether a string has content other than whitespace and newlines
    ///
    static func contentValidation(for publisher: Published<String>.Publisher) -> ValidationPublisher {
        return publisher.map { value in
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty
        }
        .dropFirst()
        .eraseToAnyPublisher()
    }

    /// Validates whether a string has `Double` value greater than the provided value
    ///
    static func greaterThanValidation(_ double: Double, for publisher: Published<String>.Publisher) -> ValidationPublisher {
        return publisher.map { value in
            guard let numericValue = Double(value) else {
                return false
            }
            return numericValue > double
        }
        .dropFirst()
        .eraseToAnyPublisher()
    }

    /// Validates whether a string has `Double` value greater than or equal to the provided value
    ///
    static func greaterThanOrEqualToValidation(_ double: Double, for publisher: Published<String>.Publisher) -> ValidationPublisher {
        return publisher.map { value in
            guard let numericValue = Double(value) else {
                return false
            }
            return numericValue >= double
        }
        .dropFirst()
        .eraseToAnyPublisher()
    }
}

// MARK: - Helpers
extension Published.Publisher where Value == String {
    func hasContent() -> ValidationPublisher {
        return ValidationPublishers.contentValidation(for: self)
    }

    func greaterThan(_ double: Double) -> ValidationPublisher {
        return ValidationPublishers.greaterThanValidation(double, for: self)
    }

    func greaterThanOrEqualTo(_ double: Double) -> ValidationPublisher {
        return ValidationPublishers.greaterThanOrEqualToValidation(double, for: self)
    }
}
