import Foundation
import UIKit
import Yosemite


// MARK: - UILabel + SubscriptionStatus Methods
//
extension UILabel {

    /// Applies the appropriate Style for a given `SubscriptionStatus`
    ///
    func applyStyle(for statusEnum: SubscriptionStatus) {
        applyFootnoteStyle()
        applyLayerSettings()
        applyBackground(for: statusEnum)
    }

    /// Setup: Layer
    ///
    private func applyLayerSettings() {
        layer.masksToBounds = true
        layer.borderWidth = SubscriptionStatusSettings.borderWidth
        layer.cornerRadius = SubscriptionStatusSettings.cornerRadius
    }

    /// Setup: Background Color
    ///
    private func applyBackground(for statusEnum: SubscriptionStatus) {
        switch statusEnum {
        case .pending, .pendingCancel, .custom:
            backgroundColor = .gray(.shade5)
        case .onHold:
            backgroundColor = .withColorStudio(.orange, shade: .shade5)
        case .active:
            backgroundColor = .withColorStudio(.green, shade: .shade5)
        case .cancelled, .expired:
            backgroundColor = .withColorStudio(.red, shade: .shade5)
        }

        textColor = .black
    }
}


// MARK: - Private
//
private extension UILabel {

    enum SubscriptionStatusSettings {
        static let borderWidth = CGFloat(0.0)
        static let cornerRadius = CGFloat(4.0)
    }
}
