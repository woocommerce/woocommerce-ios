import UIKit

final class UnderlineableTitleAndSubtitleAndDetailTableViewCell: UITableViewCell, SearchResultCell {
    typealias SearchModel = ViewModel

    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var titleLabel: UILabel!

    static func register(for tableView: UITableView) {
        tableView.registerNib(for: self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
    }

    func configureCell(searchModel: ViewModel) {
        accessibilityLabel = searchModel.accessibilityLabel
        setupTitleLabelText(with: searchModel)
        subtitleLabel.attributedText = subtitleAttributedString(from: searchModel)
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}

// MARK: - CellViewModel subtype
//
extension UnderlineableTitleAndSubtitleAndDetailTableViewCell {
    struct ViewModel: Hashable {
        /// A unique ID to avoid duplicated identifier for the view model in diffable datasource.
        /// Please make sure to override this variable with a value corresponding to the content of the cell if you use diffable datasource,
        /// to avoid unnecessary animation when reloading the table view.
        var id: String = UUID().uuidString
        let title: String
        let placeholderTitle: String
        let placeholderSubtitle: String
        let subtitle: String
        let accessibilityLabel: String
        let detail: String
        let underlinedText: String?
    }
}

// MARK: - Setup
//
private extension UnderlineableTitleAndSubtitleAndDetailTableViewCell {
    func subtitleAttributedString(from viewModel: ViewModel) -> NSAttributedString {
        guard viewModel.subtitle.trimmingCharacters(in: .whitespaces).isNotEmpty else {
            return NSMutableAttributedString(string: viewModel.placeholderSubtitle,
                                             attributes: [.font: UIFont.caption1, .foregroundColor: UIColor.textTertiary])
        }

        let subtitle = NSMutableAttributedString(string: viewModel.subtitle, attributes: [.font: UIFont.caption1, .foregroundColor: UIColor.text])

        if let underlinedText = viewModel.underlinedText {
            subtitle.underlineSubstring(underlinedText: underlinedText)
        }

        return subtitle
    }

    func setupTitleLabelText(with viewModel: ViewModel) {
        let titleAndDetail: NSMutableAttributedString = NSMutableAttributedString(attributedString: titleAttributedString(from: viewModel))
        titleAndDetail.append(detailAttributedString(from: viewModel))

        titleLabel.attributedText = titleAndDetail
    }

    func titleAttributedString(from viewModel: ViewModel) -> NSAttributedString {
        let titleFont = UIFont.font(forStyle: .callout, weight: .medium)

        guard viewModel.title.trimmingCharacters(in: .whitespaces).isNotEmpty else {
            return NSMutableAttributedString(string: viewModel.placeholderTitle, attributes: [.font: titleFont, .foregroundColor: UIColor.textTertiary])
        }

        let title = NSMutableAttributedString(string: viewModel.title, attributes: [.font: titleFont, .foregroundColor: UIColor.text])

        if let underlinedText = viewModel.underlinedText {
            title.underlineSubstring(underlinedText: underlinedText)
        }

        return title
    }

    func detailAttributedString(from viewModel: ViewModel) -> NSAttributedString {
        let detailFont = UIFont.font(forStyle: .callout, weight: .regular)

        guard viewModel.detail.isNotEmpty else {
            return NSAttributedString(string: "")
        }

        let composedDetail = " • \(viewModel.detail)"
        let detail = NSMutableAttributedString(string: composedDetail, attributes: [.font: detailFont, .foregroundColor: UIColor.textSubtle])

        if let underlinedText = viewModel.underlinedText {
            detail.underlineSubstring(underlinedText: underlinedText)
        }

        return detail
    }

    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }
}
