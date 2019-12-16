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
        case .pending, .completed, .cancelled, .refunded, .custom:
            backgroundColor = .gray(.shade5)
        case .onHold:
            backgroundColor = .withColorStudio(.orange, shade: .shade5)
        case .processing:
            backgroundColor = .withColorStudio(.green, shade: .shade5)
        case .failed:
            backgroundColor = .withColorStudio(.red, shade: .shade5)
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
