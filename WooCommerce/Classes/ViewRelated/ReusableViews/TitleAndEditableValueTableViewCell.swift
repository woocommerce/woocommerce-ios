import UIKit

final class TitleAndEditableValueTableViewCell: UITableViewCell {
    @IBOutlet private weak var stackView: UIStackView!
    // TODO Make this private and use `update()` instead.
    @IBOutlet weak var title: UILabel!
    // TODO Make this private and use `update()` instead.
    @IBOutlet weak var value: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureAsNonSelectable()
        styleTitle()
        styleValue()
        configureStackView()
    }

    /// Updates the values for the labels.
    func update(title: String?, placeholder: String?) {
        self.title.text = title
        self.value.placeholder = placeholder
    }
}


private extension TitleAndEditableValueTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureAsNonSelectable() {
        selectionStyle = .none
    }

    func configureStackView() {
        stackView.spacing = Constants.stackViewSpacing
    }

    func styleTitle() {
        title.applyFootnoteStyle()
    }

    func styleValue() {
        value.applyBodyStyle()
    }
}

// MARK: - Constants!
//
private extension TitleAndEditableValueTableViewCell {

    enum Constants {
        static let stackViewSpacing: CGFloat = 7
    }
}
