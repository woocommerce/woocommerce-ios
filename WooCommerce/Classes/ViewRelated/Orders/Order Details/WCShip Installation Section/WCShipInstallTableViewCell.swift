import UIKit

/// Displays the banner in the Order Detail for suggesting to the user to install/activate the WCShip extension.
///
final class WCShipInstallTableViewCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var body: UILabel!
    @IBOutlet weak var action: UILabel!
    @IBOutlet weak var placeholderImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureTitleLabel()
        configureBodyLabel()
        configureActionLabel()
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
        placeholderImageView.image = UIImage.productPlaceholderImage
        placeholderImageView.contentMode = .scaleAspectFit
        placeholderImageView.clipsToBounds = true
    }

    func configureTitleLabel() {
        title.applyTitleStyle()
    }

    func configureBodyLabel() {
        body.applyBodyStyle()
        body.numberOfLines = 0
    }

    func configureActionLabel() {
        action.applyActionableStyle()
    }

}
