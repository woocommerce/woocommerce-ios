import UIKit

/// Protocol
///
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
}

/// Implementation
///
class DefaultStyle: Style {
    // Android uses flat colors with no alpha, so all alphas default to 1.0
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
}

/// Hold the pointer
///
extension NSNotification.Name {
    static let StyleManagerDidUpdateActive = NSNotification.Name(rawValue: "StyleManagerDidUpdateActive")
}

class StyleManager {
    private static var active: Style = DefaultStyle() {
        didSet {
            NotificationCenter.default.post(name: .StyleManagerDidUpdateActive, object: self)
        }
    }
    static var wooCommerceBrandColor: UIColor {
        get {
            return active.wooCommerceBrandColor
        }
    }
    static var statusDangerColor: UIColor {
        get {
            return active.statusDangerColor
        }
    }
    static var statusDangerBoldColor: UIColor {
        get {
            return active.statusDangerBoldColor
        }
    }
    static var statusPrimaryColor: UIColor {
        get {
            return active.statusPrimaryColor
        }
    }
    static var statusPrimaryBoldColor: UIColor {
        get {
            return active.statusPrimaryBoldColor
        }
    }
    static var statusSuccessColor: UIColor {
        get {
            return active.statusSuccessColor
        }
    }
    static var statusSuccessBoldColor: UIColor {
        get {
            return active.statusSuccessBoldColor
        }
    }
    static var statusNotIdentifiedColor: UIColor {
        get {
            return active.statusNotIdentifiedColor
        }
    }
    static var statusNotIdentifiedBoldColor: UIColor {
        get {
            return active.statusNotIdentifiedBoldColor
        }
    }
    static var defaultTextColor: UIColor {
        get {
            return active.defaultTextColor
        }
    }
    static var sectionTitleColor: UIColor {
        return active.sectionTitleColor
    }
}
