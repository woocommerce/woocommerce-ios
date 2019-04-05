import Foundation


// MARK: - Named Assets
//
extension UIImage {

    /// Returns the Default Site Icon Placeholder Image.
    ///
    @objc
    public static var siteAddressModalPlaceholder: UIImage {
        return UIImage(named: "site-address", in: bundle, compatibleWith: nil)!
    }

    /// Returns the Default Gravatar Placeholder Image.
    ///
    @objc
    public static var onePasswordImage: UIImage {
        return UIImage(named: "onepassword-button", in: bundle, compatibleWith: nil)!
    }

    /// Returns the Link Image.
    ///
    @objc
    public static var googleIcon: UIImage {
        return UIImage(named: "google", in: bundle, compatibleWith: nil)!
    }

    /// Returns WordPressAuthenticator's Bundle
    ///
    private static var bundle: Bundle {
        return WordPressAuthenticator.bundle
    }
}
