import UIKit

extension UIFont {
    static var headline: UIFont {
        return UIFont.preferredFont(forTextStyle: .headline)
    }

    static var subheadline: UIFont {
        return UIFont.preferredFont(forTextStyle: .subheadline)
    }

    static var body: UIFont {
        return UIFont.preferredFont(forTextStyle: .body)
    }

    static var caption1: UIFont {
        return UIFont.preferredFont(forTextStyle: .caption1)
    }
}
