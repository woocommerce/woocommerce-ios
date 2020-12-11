import UIKit

/// Header view in reprint shipping label table view.
/// Shows information about reprinting a shipping label.
final class ReprintShippingLabelHeaderView: UITableViewHeaderFooterView {
    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var infoStackView: UIStackView!
    @IBOutlet private weak var infoImageView: UIImageView!
    @IBOutlet private weak var infoLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureContentStackView()
        configureInfoStackView()
        configureHeaderLabel()
        configureInfoImageView()
        configureInfoLabel()
    }
}

private extension ReprintShippingLabelHeaderView {
    func configureBackground() {
        contentView.backgroundColor = .basicBackground
    }

    func configureContentStackView() {
        contentStackView.spacing = Constants.stackViewSpacing
    }

    func configureInfoStackView() {
        infoStackView.spacing = Constants.stackViewSpacing
        infoStackView.alignment = .top
    }

    func configureHeaderLabel() {
        headerLabel.text = Localization.headerText
        headerLabel.numberOfLines = 0
        headerLabel.applyBodyStyle()
    }

    func configureInfoImageView() {
        infoImageView.image = Constants.infoImageView
        infoImageView.setContentHuggingPriority(.required, for: .horizontal)
    }

    func configureInfoLabel() {
        infoLabel.text = Localization.infoText
        infoLabel.textColor = Constants.infoTintColor
        infoLabel.numberOfLines = 0
    }
}

private extension ReprintShippingLabelHeaderView {
    enum Constants {
        static let stackViewSpacing = CGFloat(16)
        static let infoImageView = UIImage.infoOutlineImage.imageWithTintColor(infoTintColor)
        static let infoTintColor = UIColor.systemColor(.secondaryLabel)
    }

    enum Localization {
        static let headerText = NSLocalizedString(
            "If there was a printing error when you purchased the label, you can print it again.",
            comment: "Header text when reprinting a shipping label")
        static let infoText = NSLocalizedString(
            "If you already used the label in a package, printing and using it again is a violation of our terms of service",
            comment: "Info text when reprinting a shipping label")
    }
}
