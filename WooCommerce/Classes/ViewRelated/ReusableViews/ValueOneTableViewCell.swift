import UIKit

class ValueOneTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureTextLabel()
        configureDetailTextLabel()
    }

    func configure(with viewModel: ViewModel) {
        textLabel?.text = viewModel.text
        detailTextLabel?.text = viewModel.detailText
    }
}

// MARK: - CellViewModel subtype
//
extension ValueOneTableViewCell {
    struct ViewModel {
        let text: String
        let detailText: String
    }
}

private extension ValueOneTableViewCell {
    enum Constants {
        static let cellValueTextColor = UIColor.systemColor(.secondaryLabel)
    }

    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureTextLabel() {
        textLabel?.applyBodyStyle()
    }

    func configureDetailTextLabel() {
        detailTextLabel?.applySubheadlineStyle()
        detailTextLabel?.textColor = Constants.cellValueTextColor
        detailTextLabel?.lineBreakMode = .byWordWrapping
        detailTextLabel?.numberOfLines = 0
    }
}
