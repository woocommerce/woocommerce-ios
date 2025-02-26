import Foundation

// MARK: - Named Assets
//
extension UIImage {
    /// Returns the Link Image.
    ///
    static var linkFieldImage: UIImage {
        return UIImage(named: "icon-url-field", in: bundle, compatibleWith: nil) ?? UIImage()
    }

    /// Returns the Default Magic Link Image.
    ///
    static var magicLinkImage: UIImage {
        return UIImage(named: "login-magic-link", in: bundle, compatibleWith: nil) ?? UIImage()
    }

    /// Returns the Default Site Icon Placeholder Image.
    ///
    @objc
    public static var siteAddressModalPlaceholder: UIImage {
        return UIImage(named: "site-address", in: bundle, compatibleWith: nil) ?? UIImage()
    }

    /// Returns the Link Image.
    ///
    @objc
    public static var authenticatorGoogleIcon: UIImage {
        return UIImage(named: "google", in: bundle, compatibleWith: nil) ?? UIImage()
    }

    /// Returns the Phone Icon.
    ///
    @objc
    public static var authenticatorPhoneIcon: UIImage {
        return UIImage(named: "phone-icon", in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate) ?? UIImage()
    }

    /// Returns the Key Icon.
    ///
    @objc
    public static var authenticatorKeyIcon: UIImage {
        return UIImage(named: "key-icon", in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate) ?? UIImage()
    }

    /// Returns WordPressAuthenticator's Bundle
    ///
    private static var bundle: Bundle {
        return WordPressAuthenticator.bundle
    }
}
