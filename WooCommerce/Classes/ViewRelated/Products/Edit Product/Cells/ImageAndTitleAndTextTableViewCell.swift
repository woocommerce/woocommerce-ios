import UIKit

/// Displays an optional image, title and text.
///
final class ImageAndTitleAndTextTableViewCell: UITableViewCell {
    struct ViewModel {
        let title: String?
        let text: String?
        let image: UIImage?
        let imageTintColor: UIColor?
        let numberOfLinesForText: Int
        let isActionable: Bool

        init(title: String?, text: String?, image: UIImage? = nil, imageTintColor: UIColor? = nil, numberOfLinesForText: Int = 1, isActionable: Bool = true) {
            self.title = title
            self.text = text
            self.image = image
            self.imageTintColor = imageTintColor
            self.numberOfLinesForText = numberOfLinesForText
            self.isActionable = isActionable
        }
    }

    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var contentImageView: UIImageView!
    @IBOutlet private weak var titleAndTextStackView: UIStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureLabels()
        configureImageView()
        configureContentStackView()
        configureTitleAndTextStackView()
        applyDefaultBackgroundStyle()
    }
}

// MARK: Updates
//
extension ImageAndTitleAndTextTableViewCell {
    func updateUI(viewModel: ViewModel) {
        titleLabel.text = viewModel.title
        titleLabel.isHidden = viewModel.title == nil || viewModel.title?.isEmpty == true
        titleLabel.textColor = viewModel.text?.isEmpty == false ? .text: .textSubtle
        descriptionLabel.text = viewModel.text
        descriptionLabel.isHidden = viewModel.text == nil || viewModel.text?.isEmpty == true
        descriptionLabel.numberOfLines = viewModel.numberOfLinesForText
        contentImageView.image = viewModel.image
        contentImageView.isHidden = viewModel.image == nil
        accessoryType = viewModel.isActionable ? .disclosureIndicator: .none
        selectionStyle = viewModel.isActionable ? .default: .none

        if let imageTintColor = viewModel.imageTintColor {
            contentImageView.tintColor = imageTintColor
        }
    }
}

// MARK: Configurations
//
private extension ImageAndTitleAndTextTableViewCell {
    func configureLabels() {
        titleLabel.applyBodyStyle()
        titleLabel.textColor = .text

        descriptionLabel.applySubheadlineStyle()
        descriptionLabel.textColor = .textSubtle
    }

    func configureImageView() {
        contentImageView.contentMode = .center
        contentImageView.setContentHuggingPriority(.required, for: .horizontal)
    }

    func configureContentStackView() {
        contentStackView.alignment = .center
        contentStackView.spacing = 16
    }

    func configureTitleAndTextStackView() {
        titleAndTextStackView.spacing = 2
    }
}
