import UIKit


/// Represents a cell with a Title label, body label, and call-to-action button
///
final class ReadMoreTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!

    /// Closure to be executed whenever the edit button is tapped.
    ///
    var onMoreTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureLabels()
        configureMoreButton()
    }

    /// Configure the labels
    ///
    func configureLabels() {
        titleLabel?.applyHeadlineStyle()
        bodyLabel?.applySecondaryBodyStyle()
    }

    /// Configure the button
    ///
    func configureMoreButton() {
        moreButton.tintColor = .primary
        moreButton.addTarget(self, action: #selector(moreWasTapped), for: .touchUpInside)
    }

    @objc func moreWasTapped() {
        onMoreTouchUp?()
    }
}
