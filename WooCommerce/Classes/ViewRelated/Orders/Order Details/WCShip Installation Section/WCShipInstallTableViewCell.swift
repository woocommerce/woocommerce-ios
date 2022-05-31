import UIKit

/// Displays the banner in the Order Detail for suggesting to the user to install/activate the WCShip extension.
///
final class WCShipInstallTableViewCell: UITableViewCell {

    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var body: UILabel!
    @IBOutlet private weak var action: UILabel!
    @IBOutlet private weak var placeholderImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureTitleLabel()
        configureBodyLabel()
        configureActionLabel()
    }

    func update(title: String, body: String, action: String, image: UIImage) {
        self.title.text = title
        self.body.text = body
        self.action.text = action
        placeholderImageView.image = image
    }
}

private extension WCShipInstallTableViewCell {

    func configureBackground() {
        applyDefaultBackgroundStyle()

        //Background when selected
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
    }

    func configurePlaceholderImageView() {
        placeholderImageView.contentMode = .scaleAspectFit
        placeholderImageView.clipsToBounds = true
    }

    func configureTitleLabel() {
        title.applyHeadlineStyle()
        title.text = ""
    }

    func configureBodyLabel() {
        body.applyBodyStyle()
        body.numberOfLines = 0
        body.text = ""
    }

    func configureActionLabel() {
        action.applyActionableStyle()
        action.text = ""
    }

}
