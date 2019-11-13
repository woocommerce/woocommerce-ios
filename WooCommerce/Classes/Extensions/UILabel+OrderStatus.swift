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
        case .processing:
            fallthrough
        case .pending:
            backgroundColor = .neutral(.shade40)
        case .failed:
            fallthrough
        case .refunded:
            backgroundColor = .error
        case .completed:
            backgroundColor = .neutral(.shade40)
        case .onHold:
            fallthrough
        case .cancelled:
            fallthrough
        case .custom:
            fallthrough
        default:
            backgroundColor = .neutral(.shade40)
        }
    }
}


// MARK: - Private
//
private extension UILabel {

    enum OrderStatusSettings {
        static let borderWidth = CGFloat(1.0)
        static let cornerRadius = CGFloat(4.0)
    }
}
