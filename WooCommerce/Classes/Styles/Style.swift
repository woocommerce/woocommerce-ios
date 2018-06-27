import UIKit


// MARK: - Style defines the basic API of a Woo Skin.
//
protocol Style {
    var wooCommerceBrandColor: UIColor { get }
    var statusDangerColor: UIColor { get }
    var statusDangerBoldColor: UIColor { get }
    var statusPrimaryColor: UIColor { get }
    var statusPrimaryBoldColor: UIColor { get }
    var statusSuccessColor: UIColor { get }
    var statusSuccessBoldColor: UIColor { get }
    var statusNotIdentifiedColor: UIColor { get }
    var statusNotIdentifiedBoldColor: UIColor { get }
    var defaultTextColor: UIColor { get }
    var sectionTitleColor: UIColor { get }
    var buttonPrimaryColor: UIColor { get }
    var buttonPrimaryHighlightedColor: UIColor { get }
    var cellSeparatorColor: UIColor { get }
    var wooGreyMid: UIColor { get }
}

// MARK: - WooCommerce's Default Style
//
class DefaultStyle: Style {
    let wooCommerceBrandColor = UIColor(red: 0x96/255.0, green: 0x58/255.0, blue: 0x8A/255.0, alpha: 0xFF/255.0)
    let statusDangerColor = UIColor(red: 255.0/255.0, green: 230.0/255.0, blue: 229.0/255.0, alpha: 1.0)
    let statusDangerBoldColor = UIColor(red: 255.0/255.0, green: 197.0/255.0, blue: 195.0/255.0, alpha: 1.0)
    let statusPrimaryColor = UIColor(red: 244.0/255.0, green: 249.0/255.0, blue: 251.0/255.0, alpha: 1.0)
    let statusPrimaryBoldColor = UIColor(red: 188.0/255.0, green: 222.0/255.0, blue: 238.0/255.0, alpha: 1.0)
    let statusSuccessColor = UIColor(red: 239.00/255.0, green: 249.0/255.0, blue: 230.0/255.0, alpha: 1.0)
    let statusSuccessBoldColor = UIColor(red: 201.0/255.0, green: 233.0/255.0, blue: 169.0/255.0, alpha: 1.0)
    let statusNotIdentifiedColor = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)
    let statusNotIdentifiedBoldColor = UIColor(red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1.0)
    let defaultTextColor = UIColor.black
    let sectionTitleColor = UIColor.darkGray
    let buttonPrimaryColor = UIColor(red: 0x96/255.0, green: 0x58/255.0, blue: 0x8A/255.0, alpha: 0xFF/255.0)
    let buttonPrimaryHighlightedColor = UIColor(red: 0x6E/255.0, green: 0x29/255.0, blue: 0x67/255.0, alpha: 0xFF/255.0)
    let cellSeparatorColor = UIColor.lightGray
    let wooGreyMid = UIColor(red: 150.0/255.0, green: 150.0/255.0, blue: 150.0/255.0, alpha: 1.0)
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

    static var wooCommerceBrandColor: UIColor {
        return active.wooCommerceBrandColor
    }

    static var statusDangerColor: UIColor {
        return active.statusDangerColor
    }

    static var statusDangerBoldColor: UIColor {
        return active.statusDangerBoldColor
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

    static var statusNotIdentifiedColor: UIColor {
        return active.statusNotIdentifiedColor
    }

    static var statusNotIdentifiedBoldColor: UIColor {
        return active.statusNotIdentifiedBoldColor
    }

    static var defaultTextColor: UIColor {
        return active.defaultTextColor
    }

    static var sectionTitleColor: UIColor {
        return active.sectionTitleColor
    }

    static var buttonPrimaryColor: UIColor {
        return active.buttonPrimaryColor
    }

    static var buttonPrimaryHighlightedColor: UIColor {
        return active.buttonPrimaryHighlightedColor
    }

    static var cellSeparatorColor: UIColor {
        return active.cellSeparatorColor
    }

    static var wooGreyMid: UIColor {
        return active.wooGreyMid
    }
}
