import Foundation
import UIKit
import Yosemite


// MARK: - UILabel + OrderStatus Methods
//
extension UILabel {

    /// Applies the appropriate Style for a given OrderStatusEnum
    ///
    func applyStyle(for statusEnum: OrderStatusEnum) {
        applyFootnoteStyle()
        applyLayerSettings()
        applyBackground(for: statusEnum)
    }

    /// Setup: Layer
    ///
    private func applyLayerSettings() {
        layer.masksToBounds = true
        layer.borderWidth = OrderStatusSettings.borderWidth
        layer.cornerRadius = OrderStatusSettings.cornerRadius
    }

    /// Setup: Background Color
    ///
    private func applyBackground(for statusEnum: OrderStatusEnum) {
        switch statusEnum {
        case .cancelled:
            fallthrough
        case .completed:
            fallthrough
        case .custom:
            fallthrough
        case .onHold:
            fallthrough
        case .pending:
            fallthrough
        case .processing:
            backgroundColor = .gray(.shade5)
        case .failed:
            fallthrough
        case .refunded:
            backgroundColor = .error
        }

        textColor = .black
    }
}


// MARK: - Private
//
private extension UILabel {

    enum OrderStatusSettings {
        static let borderWidth = CGFloat(0.0)
        static let cornerRadius = CGFloat(4.0)
    }
}
