import UIKit

final class CustomerNoteTableViewCell: UITableViewCell {

    @IBOutlet private weak var headlineLabel: UILabel!

    @IBOutlet private weak var bodyLabel: UILabel!

    @IBOutlet private weak var editButton: UIButton!

    /// Headline label text
    ///
    var headline: String? {
        get {
            return headlineLabel.text
        }
        set {
            headlineLabel.text = newValue
        }
    }

    /// Body label text
    ///
    var body: String? {
        get {
            return bodyLabel.text
        }
        set {
            bodyLabel.text = newValue
        }
    }

    /// Closure to be invoked when the edit icon is tapped
    ///
    var onEditTapped: (() -> Void)? {
        didSet {
            editButton.isHidden = onEditTapped == nil
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
        configureEditButton()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        headlineLabel.text = nil
        bodyLabel.text = nil
        onEditTapped = nil
    }
}


// MARK: - Private Methods
//
private extension CustomerNoteTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureLabels() {
        headlineLabel.applyHeadlineStyle()
        bodyLabel.applyBodyStyle()
    }

    func configureEditButton() {
        editButton.applyIconButtonStyle(icon: .pencilImage)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }

    @objc func editButtonTapped() {
        onEditTapped?()
    }
}


/// MARK: - Testability
extension CustomerNoteTableViewCell {
    func getHeadlineLabel() -> UILabel {
        return headlineLabel
    }

    func getBodyLabel() -> UILabel {
        return bodyLabel
    }
}
