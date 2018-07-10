import Foundation
import UIKit


/// AccountHeaderView: Displays an Account's Details: [Gravatar + Name + Username]
///
class AccountHeaderView: UIView {

    /// Account's Gravatar.
    ///
    @IBOutlet private var gravatarImageView: UIImageView! {
        didSet {
            gravatarImageView.image = .gravatarPlaceholderImage
        }
    }

    /// Account's Full Name.
    ///
    @IBOutlet private var fullnameLabel: UILabel!

    /// Account's Username.
    ///
    @IBOutlet private var usernameLabel: UILabel! {
        didSet {
            usernameLabel.textColor = StyleManager.wooGreyTextMin
        }
    }
}


// MARK: - Public Methods
//
extension AccountHeaderView {

    /// Account's Username.
    ///
    var username: String? {
        set {
            usernameLabel.text =  newValue
        }
        get {
            return usernameLabel.text
        }
    }

    /// Account's Full Name
    ///
    var fullname: String? {
        set {
            fullnameLabel.text =  newValue
        }
        get {
            return fullnameLabel.text
        }
    }

    /// Downloads (and displays) the Gravatar associated with the specified Email.
    ///
    func downloadGravatar(with email: String) {
        gravatarImageView.downloadGravatarWithEmail(email)
    }
}
