import UIKit
import Yosemite


extension UILabel {
    func applyHeadlineStyle() {
        adjustsFontForContentSizeCategory = true
        font = .headline
        textColor = .text
    }

    func applyLinkBodyStyle() {
        adjustsFontForContentSizeCategory = true
        font = .body
        textColor = .textLink
    }

    func applyLinkHeadlineStyle() {
        adjustsFontForContentSizeCategory = true
        font = .headline
        textColor = .textLink
    }

    func applySubheadlineStyle() {
        adjustsFontForContentSizeCategory = true
        font = .subheadline
        textColor = .text
    }

    func applyBodyStyle() {
        adjustsFontForContentSizeCategory = true
        font = .body
        textColor = .text
    }

    func applySecondaryBodyStyle() {
        adjustsFontForContentSizeCategory = true
        font = .body
        textColor = .textSubtle
    }

    func applyFootnoteStyle() {
        adjustsFontForContentSizeCategory = true
        font = .footnote
        textColor = .systemColor(.secondaryLabel)
    }

    func applySecondaryFootnoteStyle() {
        adjustsFontForContentSizeCategory = true
        font = .footnote
        textColor = .textSubtle
    }

    func applyTitleStyle() {
        adjustsFontForContentSizeCategory = true
        font = .title1
        textColor = .text
    }

    func applyPaddedLabelDefaultStyles() {
        adjustsFontForContentSizeCategory = true
        layer.borderWidth = 1.0
        layer.cornerRadius = 4.0
        font = .footnote
    }

    func applyPaddedLabelSubheadStyles() {
        adjustsFontForContentSizeCategory = true
        layer.borderWidth = 1.0
        layer.cornerRadius = 4.0
        font = .subheadline
    }

    func applyEmptyStateTitleStyle() {
        adjustsFontForContentSizeCategory = true
        font = .body
        textColor = .textQuaternary
    }

    func applyActionableStyle() {
        textColor = .accent
    }

    func applyCaption1Style() {
        adjustsFontForContentSizeCategory = true
        font = .caption1
        textColor = .textSubtle
    }

    func applyCalloutStyle() {
        adjustsFontForContentSizeCategory = true
        font = .callout
        textColor = .textSubtle
    }
}
