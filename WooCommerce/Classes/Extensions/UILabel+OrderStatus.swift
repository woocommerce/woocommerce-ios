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
        case .processing, .pending:
            backgroundColor = StyleManager.statusSuccessColor
            layer.borderColor = StyleManager.statusSuccessBoldColor.cgColor
        case .failed, .refunded:
            backgroundColor = StyleManager.statusDangerColor
            layer.borderColor = StyleManager.statusDangerBoldColor.cgColor
        case .completed:
            backgroundColor = StyleManager.statusPrimaryColor
            layer.borderColor = StyleManager.statusPrimaryBoldColor.cgColor
        default:
            backgroundColor = StyleManager.statusNotIdentifiedColor
            layer.borderColor = StyleManager.statusNotIdentifiedBoldColor.cgColor
        }
    }
}


// MARK: - Private
//
extension UILabel {

    fileprivate enum OrderStatusSettings {
        static let borderWidth = CGFloat(1.0)
        static let cornerRadius = CGFloat(4.0)
    }
}
