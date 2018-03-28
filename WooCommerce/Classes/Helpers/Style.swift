import UIKit

// protocol
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
}

// implementation
class DefaultStyle: Style {
    // Android uses flat colors with no alpha, so all alphas default to 1.0
    let wooCommerceBrandColor = UIColor(red: 0x96/255.0, green: 0x58/255.0, blue: 0x8A/255.0, alpha: 0xFF/255.0)
    let statusDangerColor = UIColor(red: 251.0/255.0, green: 229.0/255.0, blue: 227.0/255.0, alpha: 1.0)
    let statusDangerBoldColor = UIColor(red: 247.0/255.0, green: 204.0/255.0, blue: 201.0/255.0, alpha: 1.0)
    let statusPrimaryColor = UIColor(red: 245.0/255.0, green: 250.0/255.0, blue: 250.0/255.0, alpha: 1.0)
    let statusPrimaryBoldColor = UIColor(red: 198.0/255.0, green: 220.0/255.0, blue: 233.0/255.0, alpha: 1.0)
    let statusSuccessColor = UIColor(red: 247.00/255.0, green: 255.0/255.0, blue: 247.0/255.0, alpha: 1.0)
    let statusSuccessBoldColor = UIColor(red: 208.0/255.0, green: 231.0/255.0, blue: 185.0/255.0, alpha: 1.0)
    let statusNotIdentifiedColor = UIColor(red: 232.0/255.0, green: 232.0/255.0, blue: 232.0/255.0, alpha: 1.0)
    let statusNotIdentifiedBoldColor = UIColor(red: 221.0/255.0, green: 221.0/255.0, blue: 221.0/255.0, alpha: 1.0)
    let defaultTextColor = UIColor.black
}

// hold the pointer
class StyleManager {
    static var active: Style = DefaultStyle() {
        didSet {
            // post a notification
        }
    }
}

