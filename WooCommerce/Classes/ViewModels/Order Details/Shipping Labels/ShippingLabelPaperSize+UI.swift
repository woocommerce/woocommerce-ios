import Yosemite

extension ShippingLabelPaperSize {
    /// Description for UI display.
    var description: String {
        switch self {
        case .label:
            return NSLocalizedString("Label (4 x 6 in)", comment: "Title of label paper size option for printing a shipping label")
        case .legal:
            return NSLocalizedString("Legal (8.5 x 14 in)", comment: "Title of legal paper size option for printing a shipping label")
        case .letter:
            return NSLocalizedString("Letter (8.5 x 11 in)", comment: "Title of letter paper size option for printing a shipping label")
        }
    }
}
