import UIKit

// Setting the UITextField background color via the appearance proxy does not seem to work
// As a workaround, this property exposes the texfield, so the background color can be set manually
//
extension UISearchBar {
    var textField: UITextField? {
        return subviews.map { $0.subviews.first(where: { $0 is UITextInputTraits}) as? UITextField }
            .compactMap { $0 }
            .first
    }
}
