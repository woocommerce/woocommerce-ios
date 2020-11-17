import Foundation

/// Paper size options for printing a shipping label.
public enum ShippingLabelPaperSize {
    case label
    case legal
    case letter
}

/// RawRepresentable Conformance
extension ShippingLabelPaperSize: RawRepresentable {
    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.label:
            self = .label
        case Keys.legal:
            self = .legal
        case Keys.letter:
            self = .letter
        default:
            assertionFailure("Unexpected value for `ShippingLabelPaperSize`: \(rawValue)")
            self = .label
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .label:
            return Keys.label
        case .legal:
            return Keys.legal
        case .letter:
            return Keys.letter
        }
    }
}

/// Contains the supported ShippingLabelPaperSize values.
private enum Keys {
    static let label = "label"
    static let legal = "legal"
    static let letter = "letter"
}
