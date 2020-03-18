import Foundation


// MARK - Storyboard enum
enum Storyboard: String {
    case login
    case signup
    case emailMagicLink

    var instance: UIStoryboard {
        return UIStoryboard(name: self.rawValue.capitalized, bundle: WordPressAuthenticator.bundle)
    }

    /// Returns a view controller from a Storyboard
    /// assuming the identifier is the same as the class name.
    ///
    func instantiateViewController<T: NSObject>(ofClass classType: T.Type) -> T? {
        let identifier = classType.classNameWithoutNamespaces
        return instance.instantiateViewController(withIdentifier: identifier) as? T
    }
}
