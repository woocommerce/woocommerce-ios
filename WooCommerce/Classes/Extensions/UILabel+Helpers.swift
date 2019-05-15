import UIKit
import Yosemite


extension UILabel {
    func applyHeadlineStyle() {
        adjustsFontForContentSizeCategory = true
        font = .headline
        textColor = StyleManager.defaultTextColor
    }

    func applySubheadlineStyle() {
        adjustsFontForContentSizeCategory = true
        font = .subheadline
        textColor = StyleManager.defaultTextColor
    }

    func applyBodyStyle() {
        adjustsFontForContentSizeCategory = true
        font = .body
        textColor = StyleManager.defaultTextColor
    }

    func applySecondaryBodyStyle() {
        adjustsFontForContentSizeCategory = true
        font = .body
        textColor = StyleManager.wooGreyTextMin
    }

    func applyFootnoteStyle() {
        adjustsFontForContentSizeCategory = true
        font = .footnote
        textColor = StyleManager.defaultTextColor
    }

    func applyTitleStyle() {
        adjustsFontForContentSizeCategory = true
        font = .title1
        textColor = StyleManager.defaultTextColor
    }

    func applyPaddedLabelDefaultStyles() {
        adjustsFontForContentSizeCategory = true
        layer.borderWidth = 1.0
        layer.cornerRadius = 4.0
        font = .footnote
    }

    func applyEmptyStateTitleStyle() {
        adjustsFontForContentSizeCategory = true
        font = .body
        textColor = StyleManager.wooGreyMid
    }
}
