import UIKit

/// Displays an optional image, title and text.
///
final class ImageAndTitleAndTextTableViewCell: UITableViewCell {
    struct ViewModel {
        let title: String?
        let text: String?
        let textTintColor: UIColor?
        let image: UIImage?
        let imageTintColor: UIColor?
        let numberOfLinesForTitle: Int
        let numberOfLinesForText: Int
        let isActionable: Bool

        init(title: String?,
             text: String?,
             textTintColor: UIColor? = nil,
             image: UIImage? = nil,
             imageTintColor: UIColor? = nil,
             numberOfLinesForTitle: Int = 1,
             numberOfLinesForText: Int = 1,
             isActionable: Bool = true) {
            self.title = title
            self.text = text
            self.textTintColor = textTintColor
            self.image = image
            self.imageTintColor = imageTintColor
            self.numberOfLinesForTitle = numberOfLinesForTitle
            self.numberOfLinesForText = numberOfLinesForText
            self.isActionable = isActionable
        }
    }

    /// View model with a switch in the cell's accessory view.
    struct SwitchableViewModel {
        let viewModel: ViewModel
        let isSwitchOn: Bool
        let isActionable: Bool
        let onSwitchChange: (_ isOn: Bool) -> Void

        init(viewModel: ViewModel, isSwitchOn: Bool, isActionable: Bool, onSwitchChange: @escaping (_ isOn: Bool) -> Void) {
            self.viewModel = viewModel
            self.isSwitchOn = isSwitchOn
            self.isActionable = isActionable
            self.onSwitchChange = onSwitchChange
        }
    }

    /// View model for warning UI.
    struct WarningViewModel {
        let icon: UIImage
        let title: String?
    }

    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var contentImageStackView: UIStackView!
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
        titleLabel.numberOfLines = viewModel.numberOfLinesForTitle
        descriptionLabel.text = viewModel.text
        descriptionLabel.textColor = .textSubtle
        descriptionLabel.isHidden = viewModel.text == nil || viewModel.text?.isEmpty == true
        descriptionLabel.numberOfLines = viewModel.numberOfLinesForText
        contentImageView.image = viewModel.image
        contentImageStackView.isHidden = viewModel.image == nil
        accessoryType = viewModel.isActionable ? .disclosureIndicator: .none
        selectionStyle = viewModel.isActionable ? .default: .none
        accessoryView = nil

        if let textTintColor = viewModel.textTintColor {
            titleLabel.textColor = textTintColor
            descriptionLabel.textColor = textTintColor
        }

        if let imageTintColor = viewModel.imageTintColor {
            contentImageView.tintColor = imageTintColor
        }
        contentView.backgroundColor = nil
    }

    func updateUI(switchableViewModel: SwitchableViewModel) {
        updateUI(viewModel: switchableViewModel.viewModel)
        titleLabel.textColor = .text

        let toggleSwitch = UISwitch()
        toggleSwitch.onTintColor = switchableViewModel.isActionable ? .primary: .switchDisabledColor
        toggleSwitch.isOn = switchableViewModel.isSwitchOn
        toggleSwitch.isUserInteractionEnabled = switchableViewModel.isActionable
        if switchableViewModel.isActionable {
            toggleSwitch.on(.touchUpInside) { visibilitySwitch in
                switchableViewModel.onSwitchChange(visibilitySwitch.isOn)
            }
        }
        accessoryView = toggleSwitch
        contentView.backgroundColor = nil
    }

    func updateUI(warningViewModel: WarningViewModel) {
        let viewModel = ViewModel(title: warningViewModel.title,
                                  text: nil,
                                  textTintColor: .warning,
                                  image: warningViewModel.icon,
                                  imageTintColor: .warning,
                                  isActionable: false)
        updateUI(viewModel: viewModel)

        titleLabel.textColor = .text
        titleLabel.numberOfLines = 0
        contentView.backgroundColor = .warningBackground
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
