import Foundation
import class UIKit.UIColor

/// Represents a formatted delta percentage string and its direction of change
struct DeltaPercentage {
    /// The delta percentage formatted as a localized string (e.g. `+100%`)
    let string: String

    /// The direction of change
    let direction: Direction

    init(string: String, direction: Direction) {
        self.string = string
        self.direction = direction
    }

    /// Convenience initializer
    /// - Parameters:
    ///   - value: The percentage expressed as a `Decimal` (e.g. 0.5 for 50%).
    ///   - formatter: The formatter used to format the value as a string.
    init(value: Decimal, formatter: NumberFormatter) {
        self.string = formatter.string(from: value as NSNumber) ?? ""
        self.direction = {
            if value > 0 {
                return .positive
            } else if value < 0 {
                return .negative
            } else {
                return .zero
            }
        }()
    }

    /// Represents the direction of change for a delta value
    enum Direction {
        case positive
        case negative
        case zero

        /// Background color for a `DeltaTag`
        var deltaBackgroundColor: UIColor {
            switch self {
            case .positive:
                return Constants.green
            case .negative:
                return Constants.red
            case .zero:
                return Constants.lightGray
            }
        }

        /// Text color for a `DeltaTag`
        var deltaTextColor: UIColor {
            switch self {
            case .positive, .negative:
                return .textInverted
            case .zero:
                return .text
            }
        }

        /// Line color for an `AnalyticsLineChart`
        var chartColor: UIColor {
            switch self {
            case .positive:
                return Constants.green
            case .negative:
                return Constants.red
            case .zero:
                return Constants.darkGray
            }
        }
    }
}

// MARK: Constants
extension DeltaPercentage {
    enum Constants {
        static let green: UIColor = .withColorStudio(.green, shade: .shade50)
        static let red: UIColor = .withColorStudio(.red, shade: .shade40)
        static let lightGray: UIColor = .withColorStudio(.gray, shade: .shade0)
        static let darkGray: UIColor = .withColorStudio(.gray, shade: .shade30)
    }
}
