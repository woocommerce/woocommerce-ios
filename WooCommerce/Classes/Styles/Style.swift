import UIKit


// MARK: - Style defines the basic API of a Woo Skin.
//
protocol Style {
    var alternativeLoginsTitleFont: UIFont { get }
    var buttonPrimaryColor: UIColor { get }
    var buttonPrimaryHighlightedColor: UIColor { get }
    var buttonPrimaryTitleColor: UIColor { get }
    var buttonSecondaryColor: UIColor { get }
    var buttonSecondaryHighlightedColor: UIColor { get }
    var buttonSecondaryTitleColor: UIColor { get }
    var buttonDisabledColor: UIColor { get }
    var buttonDisabledHighlightedColor: UIColor { get }
    var buttonDisabledTitleColor: UIColor { get }
    var cellSeparatorColor: UIColor { get }
    var defaultTextColor: UIColor { get }
    var sectionTitleColor: UIColor { get }
    var statusDangerColor: UIColor { get }
    var statusDangerBoldColor: UIColor { get }
    var statusNotIdentifiedColor: UIColor { get }
    var statusNotIdentifiedBoldColor: UIColor { get }
    var statusPrimaryColor: UIColor { get }
    var statusPrimaryBoldColor: UIColor { get }
    var statusSuccessColor: UIColor { get }
    var statusSuccessBoldColor: UIColor { get }
    var tableViewBackgroundColor: UIColor { get }
    var wooCommerceBrandColor: UIColor { get }
    var wooGreyMid: UIColor { get }
    var wooGreyTextMin: UIColor { get }
}

// MARK: - WooCommerce's Default Style
//
class DefaultStyle: Style {
    let alternativeLoginsTitleFont = UIFont.font(forStyle: .subheadline, weight: .semibold)
    let buttonPrimaryColor = UIColor(red: 0x96/255.0, green: 0x58/255.0, blue: 0x8A/255.0, alpha: 0xFF/255.0)
    let buttonPrimaryHighlightedColor = UIColor(red: 0x6E/255.0, green: 0x29/255.0, blue: 0x67/255.0, alpha: 0xFF/255.0)
    let buttonPrimaryTitleColor = UIColor.white
    let buttonSecondaryColor = UIColor.white
    let buttonSecondaryHighlightedColor = UIColor.gray
    let buttonSecondaryTitleColor = UIColor.gray
    let buttonDisabledColor = UIColor.white
    let buttonDisabledHighlightedColor = UIColor(red: 233.0/255.0, green: 239.0/255.0, blue: 234.0/255.0, alpha: 1.0)
    let buttonDisabledTitleColor = UIColor(red: 233.0/255.0, green: 239.0/255.0, blue: 234.0/255.0, alpha: 1.0)
    let cellSeparatorColor = UIColor.lightGray
    let defaultTextColor = UIColor.black
    let sectionTitleColor = UIColor.darkGray
    let statusDangerColor = UIColor(red: 255.0/255.0, green: 230.0/255.0, blue: 229.0/255.0, alpha: 1.0)
    let statusDangerBoldColor = UIColor(red: 255.0/255.0, green: 197.0/255.0, blue: 195.0/255.0, alpha: 1.0)
    let statusNotIdentifiedColor = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)
    let statusNotIdentifiedBoldColor = UIColor(red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1.0)
    let statusPrimaryColor = UIColor(red: 244.0/255.0, green: 249.0/255.0, blue: 251.0/255.0, alpha: 1.0)
    let statusPrimaryBoldColor = UIColor(red: 188.0/255.0, green: 222.0/255.0, blue: 238.0/255.0, alpha: 1.0)
    let statusSuccessColor = UIColor(red: 239.00/255.0, green: 249.0/255.0, blue: 230.0/255.0, alpha: 1.0)
    let statusSuccessBoldColor = UIColor(red: 201.0/255.0, green: 233.0/255.0, blue: 169.0/255.0, alpha: 1.0)
    let tableViewBackgroundColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
    let wooCommerceBrandColor = UIColor(red: 0x96/255.0, green: 0x58/255.0, blue: 0x8A/255.0, alpha: 0xFF/255.0)
    let wooGreyMid = UIColor(red: 150.0/255.0, green: 150.0/255.0, blue: 150.0/255.0, alpha: 1.0)
    let wooGreyTextMin = UIColor(red: 89.0/255.0, green: 89.0/255.0, blue: 89.0/255.0, alpha: 1.0)
}


// MARK: - StyleManager's Notifications
//
extension NSNotification.Name {
    static let StyleManagerDidUpdateActive = NSNotification.Name(rawValue: "StyleManagerDidUpdateActive")
}


// MARK: - StyleManager: Our "Active Style" Container!
//
class StyleManager {

    private static var active: Style = DefaultStyle() {
        didSet {
            NotificationCenter.default.post(name: .StyleManagerDidUpdateActive, object: self)
        }
    }

    static var alternativeLoginsTitleFont: UIFont {
        return active.alternativeLoginsTitleFont
    }

    static var buttonPrimaryColor: UIColor {
        return active.buttonPrimaryColor
    }

    static var buttonPrimaryHighlightedColor: UIColor {
        return active.buttonPrimaryHighlightedColor
    }

    static var buttonPrimaryTitleColor: UIColor {
        return active.buttonPrimaryTitleColor
    }

    static var buttonSecondaryColor: UIColor {
        return active.buttonSecondaryColor
    }

    static var buttonSecondaryHighlightedColor: UIColor {
        return active.buttonSecondaryHighlightedColor
    }

    static var buttonSecondaryTitleColor: UIColor {
        return active.buttonSecondaryTitleColor
    }

    static var buttonDisabledColor: UIColor {
        return active.buttonDisabledColor
    }

    static var buttonDisabledHighlightedColor: UIColor {
        return active.buttonDisabledHighlightedColor
    }

    static var buttonDisabledTitleColor: UIColor {
        return active.buttonDisabledTitleColor
    }

    static var cellSeparatorColor: UIColor {
        return active.cellSeparatorColor
    }

    static var defaultTextColor: UIColor {
        return active.defaultTextColor
    }

    static var statusDangerColor: UIColor {
        return active.statusDangerColor
    }

    static var statusDangerBoldColor: UIColor {
        return active.statusDangerBoldColor
    }

    static var statusNotIdentifiedColor: UIColor {
        return active.statusNotIdentifiedColor
    }

    static var statusNotIdentifiedBoldColor: UIColor {
        return active.statusNotIdentifiedBoldColor
    }

    static var statusPrimaryColor: UIColor {
        return active.statusPrimaryColor
    }

    static var statusPrimaryBoldColor: UIColor {
        return active.statusPrimaryBoldColor
    }

    static var statusSuccessColor: UIColor {
        return active.statusSuccessColor
    }

    static var statusSuccessBoldColor: UIColor {
        return active.statusSuccessBoldColor
    }

    static var sectionTitleColor: UIColor {
        return active.sectionTitleColor
    }

    static var tableViewBackgroundColor: UIColor {
        return active.tableViewBackgroundColor
    }

    static var wooCommerceBrandColor: UIColor {
        return active.wooCommerceBrandColor
    }

    static var wooGreyMid: UIColor {
        return active.wooGreyMid
    }

    static var wooGreyTextMin: UIColor {
        return active.wooGreyTextMin
    }
}
