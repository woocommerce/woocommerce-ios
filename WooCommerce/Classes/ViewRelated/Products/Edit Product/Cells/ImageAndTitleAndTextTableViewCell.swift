import Combine
import UIKit

/// Displays an optional image, title and text.
///
final class ImageAndTitleAndTextTableViewCell: UITableViewCell {
    /// Supported font styles.
    enum FontStyle {
        case body
        case footnote
    }

    /// Use cases where an image, title, and text could be displayed.
    /// TODO-3419: add support for other use cases that are currently configured with individual `*ViewModel`.
    enum Style {
        /// Only the image and title label are displayed with a given font style for the title.
        case imageAndTitleOnly(fontStyle: FontStyle)
        /// The cell's title, image, and background color are set to warning style.
        case warning
    }

    /// Contains configurable properties for the cell.
    struct DataConfiguration {
        let title: String?
        let text: String?
        let textTintColor: UIColor?
        let image: UIImage?
        let imageTintColor: UIColor?
        let numberOfLinesForTitle: Int
        let numberOfLinesForText: Int
        let isActionable: Bool
        let showsSeparator: Bool

        init(title: String?,
             text: String? = nil,
             textTintColor: UIColor? = nil,
             image: UIImage? = nil,
             imageTintColor: UIColor? = nil,
             numberOfLinesForTitle: Int = 1,
             numberOfLinesForText: Int = 1,
             isActionable: Bool = true,
             showsSeparator: Bool = true) {
            self.title = title
            self.text = text
            self.textTintColor = textTintColor
            self.image = image
            self.imageTintColor = imageTintColor
            self.numberOfLinesForTitle = numberOfLinesForTitle
            self.numberOfLinesForText = numberOfLinesForText
            self.isActionable = isActionable
            self.showsSeparator = showsSeparator
        }
    }

    struct ViewModel: Equatable {
        let title: String?
        let text: String?
        let textTintColor: UIColor?
        let image: UIImage?
        let imageTintColor: UIColor?
        let numberOfLinesForTitle: Int
        let numberOfLinesForText: Int
        let isActionable: Bool
        let showsSeparator: Bool

        init(title: String?,
             text: String?,
             textTintColor: UIColor? = nil,
             image: UIImage? = nil,
             imageTintColor: UIColor? = nil,
             numberOfLinesForTitle: Int = 1,
             numberOfLinesForText: Int = 1,
             isActionable: Bool = true,
             showsSeparator: Bool = true) {
            self.title = title
            self.text = text
            self.textTintColor = textTintColor
            self.image = image
            self.imageTintColor = imageTintColor
            self.numberOfLinesForTitle = numberOfLinesForTitle
            self.numberOfLinesForText = numberOfLinesForText
            self.isActionable = isActionable
            self.showsSeparator = showsSeparator
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

    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var contentImageStackView: UIStackView!
    @IBOutlet private weak var contentImageView: UIImageView!
    @IBOutlet private weak var titleAndTextStackView: UIStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    /// Disabled by default. When active, image is constrained to 24pt
    @IBOutlet private var contentImageViewWidthConstraint: NSLayoutConstraint!

    private var cancellable: AnyCancellable?

    override func awakeFromNib() {
        super.awakeFromNib()
        configureLabels()
        configureImageView()
        configureContentStackView()
        configureTitleAndTextStackView()
        applyDefaultBackgroundStyle()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellable = nil
    }
}

// MARK: Updates
//
extension ImageAndTitleAndTextTableViewCell {
    func updateUI(viewModel: ViewModel) {
        titleLabel.text = viewModel.title
        titleLabel.isHidden = viewModel.title == nil || viewModel.title?.isEmpty == true
        titleLabel.applyBodyStyle()
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

        contentImageViewWidthConstraint.isActive = false

        if viewModel.showsSeparator {
            showSeparator()
        } else {
            hideSeparator()
        }
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

    /// Updates cell with the given style and data configuration.
    func update(with style: Style, data: DataConfiguration) {
        switch style {
        case .imageAndTitleOnly(let fontStyle):
            applyImageAndTitleOnlyStyle(fontStyle: fontStyle, data: data)
        case .warning:
            applyWarningStyle(data: data)
        }
        applyAccessibilityChanges(contentSizeCategory: traitCollection.preferredContentSizeCategory)
        observeContentSizeCategoryChanges()
    }
}

// MARK: Private update helpers
//
private extension ImageAndTitleAndTextTableViewCell {
    func observeContentSizeCategoryChanges() {
        cancellable = NotificationCenter.default
                .publisher(for: UIContentSizeCategory.didChangeNotification)
                .sink { [weak self] notification in
                    guard let self = self,
                          let contentSizeCategory = notification.userInfo?[UIContentSizeCategory.newValueUserInfoKey] as? UIContentSizeCategory else {
                        return
                    }
                    self.applyAccessibilityChanges(contentSizeCategory: contentSizeCategory)
                }
    }

    func applyImageAndTitleOnlyStyle(fontStyle: FontStyle, data: DataConfiguration) {
        switch fontStyle {
        case .body:
            titleLabel.applyBodyStyle()
        case .footnote:
            titleLabel.applyFootnoteStyle()
        }
        applyDefaultStyle(data: data)
        contentImageViewWidthConstraint.isActive = true
    }

    func applyWarningStyle(data: DataConfiguration) {
        applyDefaultStyle(data: data)

        titleLabel.textColor = .text
        contentImageView.tintColor = .warning
        contentView.backgroundColor = .warningBackground
    }

    func applyDefaultStyle(data: DataConfiguration) {
        let viewModel = ViewModel(title: data.title,
                                  text: data.text,
                                  textTintColor: data.textTintColor,
                                  image: data.image,
                                  imageTintColor: data.imageTintColor,
                                  numberOfLinesForTitle: data.numberOfLinesForTitle,
                                  numberOfLinesForText: data.numberOfLinesForText,
                                  isActionable: data.isActionable,
                                  showsSeparator: data.showsSeparator)
        updateUI(viewModel: viewModel)
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
        contentStackView.alignment = .firstBaseline
        contentStackView.spacing = 16
    }

    func configureTitleAndTextStackView() {
        titleAndTextStackView.spacing = 2
    }
}

// MARK: Accessibility
//
private extension ImageAndTitleAndTextTableViewCell {
    func applyAccessibilityChanges(contentSizeCategory: UIContentSizeCategory) {
        adjustContentStackViewAxis(contentSizeCategory: contentSizeCategory)
    }

    /// Changes the image view width according to the base image dimension.
    func adjustContentStackViewAxis(contentSizeCategory: UIContentSizeCategory) {
        let isVerticalStack = contentSizeCategory >= .accessibilityMedium
        contentStackView.axis = isVerticalStack ? .vertical: .horizontal
        contentStackView.alignment = isVerticalStack ? .leading: .firstBaseline
        contentStackView.spacing = isVerticalStack ? 5: 16
    }
}
