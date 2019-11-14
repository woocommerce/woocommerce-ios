import UIKit

/// Displays an optional image, title and text.
///
final class ImageAndTitleAndTextTableViewCell: UITableViewCell {
    struct ViewModel {
        let title: String
        let text: String
        let image: UIImage?

        init(title: String, text: String, image: UIImage? = nil) {
            self.title = title
            self.text = text
            self.image = image
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
    }
}

// MARK: Updates
//
extension ImageAndTitleAndTextTableViewCell {
    func updateUI(viewModel: ViewModel) {
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.text
        contentImageView.image = viewModel.image
        contentImageView.isHidden = viewModel.image == nil
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
        titleAndTextStackView.spacing = 6
    }
}
