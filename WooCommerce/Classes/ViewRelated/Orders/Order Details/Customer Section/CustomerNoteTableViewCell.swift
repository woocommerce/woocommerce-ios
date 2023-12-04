import UIKit

final class CustomerNoteTableViewCell: UITableViewCell {

    @IBOutlet private weak var headlineLabel: UILabel!

    @IBOutlet private weak var bodyTextView: UITextView!

    @IBOutlet private weak var editButton: UIButton!

    @IBOutlet private weak var addButton: UIButton!

    /// Headline label text
    ///
    var headline: String? {
        get {
            return headlineLabel.text
        }
        set {
            headlineLabel.text = newValue
            headlineLabel.isHidden = newValue == nil || newValue?.isEmpty == true
        }
    }

    /// Body label text
    ///
    var body: String? {
        get {
            return bodyTextView.text
        }
        set {
            bodyTextView.text = newValue
            bodyTextView.isHidden = newValue == nil || newValue?.isEmpty == true
        }
    }

    /// Closure to be invoked when the edit icon is tapped
    /// Setting a value makes the button visible
    ///
    var onEditTapped: (() -> Void)? {
        didSet {
            let shouldHideEditButton = onEditTapped == nil
            editButton.isHidden = shouldHideEditButton
        }
    }

    /// Closure to be invoked when the add button is tapped
    /// Setting a value makes the button visible
    ///
    var onAddTapped: (() -> Void)? {
        didSet {
            let shouldHideAddButton = onAddTapped == nil
            addButton.isHidden = shouldHideAddButton
        }
    }

    /// Accessibility label to be used on the edit button, when shown
    ///
    var editButtonAccessibilityLabel: String? {
        get {
            editButton.accessibilityLabel
        }
        set {
            editButton.accessibilityLabel = newValue
        }
    }

    /// Title to be used on the add button, when shown
    ///
    var addButtonTitle: String? {
        get {
            addButton.currentTitle
        }
        set {
            addButton.setTitle(newValue, for: .normal)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureHeadlineLabel()
        configureBodyTextView()
        configureEditButton()
        configureAddButton()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        headlineLabel.text = nil
        bodyTextView.text = nil
        onEditTapped = nil
        onAddTapped = nil
        editButton.accessibilityLabel = nil
    }
}

// MARK: - Private Methods
//
private extension CustomerNoteTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureHeadlineLabel() {
        headlineLabel.applyHeadlineStyle()
    }

    func configureBodyTextView() {
        bodyTextView.font = .body
        bodyTextView.textColor = .text
        bodyTextView.backgroundColor = .listForeground(modal: false)
        bodyTextView.adjustsFontForContentSizeCategory = true

        // Remove padding from inside text view
        bodyTextView.contentInset = .zero
        bodyTextView.textContainerInset = .zero
        bodyTextView.textContainer.lineFragmentPadding = .zero
    }

    func configureEditButton() {
        editButton.applyIconButtonStyle(icon: .pencilImage)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }

    func configureAddButton() {
        addButton.applyLinkButtonStyle()
        addButton.setImage(.plusImage, for: .normal)
        addButton.contentHorizontalAlignment = .leading
        addButton.contentVerticalAlignment = .center
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = .init(.zero)
        configuration.imagePadding = Constants.buttonTitleAndImageSpacing
        addButton.configuration = configuration
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }

    @objc func editButtonTapped() {
        onEditTapped?()
    }

    @objc func addButtonTapped() {
        onAddTapped?()
    }
}


/// MARK: - Testability
extension CustomerNoteTableViewCell {
    func getHeadlineLabel() -> UILabel {
        return headlineLabel
    }

    func getBodyTextView() -> UITextView {
        return bodyTextView
    }
}

private extension CustomerNoteTableViewCell {
    enum Constants {
        static let buttonTitleAndImageSpacing: CGFloat = 16
    }
}
