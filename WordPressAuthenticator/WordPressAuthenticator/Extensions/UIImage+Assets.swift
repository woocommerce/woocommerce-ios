import Foundation


// MARK: - Named Assets
//
extension UIImage {

    /// Returns the Default Site Icon Placeholder Image.
    ///
    @objc
    public static var siteAddressModalPlaceholder: UIImage {
        return UIImage(named: "site-address-modal", in: bundle, compatibleWith: nil)!
    }


    /// Returns the Default Gravatar Placeholder Image.
    ///
    @objc
    public static var onePasswordImage: UIImage {
        return UIImage(named: "onepassword-wp-button", in: bundle, compatibleWith: nil)!
    }

    /// Returns the Link Image.
    ///
    @objc
    public static var googleIcon: UIImage {
        return UIImage(named: "google", in: bundle, compatibleWith: nil)!
    }

    /// Returns the Link Image.
    ///
    @objc
    public static var beveledBlueButtonImage: UIImage {
        return UIImage(named: "beveled-blue-button", in: bundle, compatibleWith: nil)!
    }

    /// Returns the Link Image.
    ///
    @objc
    public static var belevedBlueButtonDownImage: UIImage {
        return UIImage(named: "beveled-blue-button-down", in: bundle, compatibleWith: nil)!
    }

    /// Returns the Link Image.
    ///
    @objc
    public static var beveledSecondaryButtonImage: UIImage {
        return UIImage(named: "beveled-secondary-button", in: bundle, compatibleWith: nil)!
    }

    /// Returns the Link Image.
    ///
    @objc
    public static var beveledSecondaryButtonDownImage: UIImage {
        return UIImage(named: "beveled-secondary-button-down", in: bundle, compatibleWith: nil)!
    }

    /// Returns the Link Image.
    ///
    @objc
    public static var beveledDisabledButtonImage: UIImage {
        return UIImage(named: "beveled-disabled-button", in: bundle, compatibleWith: nil)!
    }

    /// Returns WordPressAuthenticator's Bundle
    ///
    private static var bundle: Bundle {
        return Bundle(for: WordPressAuthenticator.self)
    }
}
