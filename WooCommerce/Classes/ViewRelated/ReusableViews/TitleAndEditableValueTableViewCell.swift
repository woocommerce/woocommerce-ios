import UIKit

final class TitleAndEditableValueTableViewCell: UITableViewCell {
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var value: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureAsNonSelectable()
        styleTitle()
        styleValue()
        configureStackView()
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
