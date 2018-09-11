import UIKit

class LogOutTableViewCell: UITableViewCell {

    @IBOutlet var logoutButton: UIButton!
    var didSelectLogout: (() -> Void)?

    @IBAction func logoutButtonTapped(sender: UIButton) {
        didSelectLogout?()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        logoutButton.setTitle(NSLocalizedString("Logout account", comment: "Log out button title"), for: .normal)
        logoutButton.tintColor = StyleManager.destructiveActionColor
        logoutButton.titleLabel?.applyBodyStyle()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
