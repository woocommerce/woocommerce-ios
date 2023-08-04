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
        configureCell(viewModel: searchModel)
        subtitleLabel.applyStrongCaption1Style()
    }

    func configureCell(viewModel: ViewModel) {
        accessibilityLabel = viewModel.accessibilityLabel
        setupTitleLabelText(with: viewModel)
        setupSubtitleLabelText(with: viewModel)
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
        let subtitle: String
        let accessibilityLabel: String
        let detail: String
        let underlinedText: String?
    }
}

// MARK: - Setup
//
private extension UnderlineableTitleAndSubtitleAndDetailTableViewCell {
    func setupSubtitleLabelText(with viewModel: ViewModel) {
        let subtitle = NSMutableAttributedString(string: viewModel.subtitle, attributes: [.font: UIFont.caption1, .foregroundColor: UIColor.text])

        if let underlinedText = viewModel.underlinedText {
            subtitle.underlineSubstring(underlinedText: underlinedText)
        }

        subtitleLabel.attributedText = subtitle
    }

    func setupTitleLabelText(with viewModel: ViewModel) {
        var titleAndDetail: NSMutableAttributedString = NSMutableAttributedString(attributedString: titleAttributedString(from: viewModel))
        titleAndDetail.append(detailAttributedString(from: viewModel))

        titleLabel.attributedText = titleAndDetail
    }

    func titleAttributedString(from viewModel: ViewModel) -> NSAttributedString {
        var title: NSMutableAttributedString

        if viewModel.title.trimmingCharacters(in: .whitespaces).isEmpty {
            title = NSMutableAttributedString(string: viewModel.placeholderTitle, attributes: [.font: UIFont.body, .foregroundColor: UIColor.textSubtle])
        } else {
            title = NSMutableAttributedString(string: viewModel.title, attributes: [.font: UIFont.body, .foregroundColor: UIColor.text])

            if let underlinedText = viewModel.underlinedText {
                title.underlineSubstring(underlinedText: underlinedText)
            }
        }

        return title
    }

    func detailAttributedString(from viewModel: ViewModel) -> NSAttributedString {
        let detail: NSMutableAttributedString
        if viewModel.detail.isEmpty {
            detail = NSMutableAttributedString(string: "")
        } else {
            let composedDetail = " • \(viewModel.detail)"
            detail = NSMutableAttributedString(string: composedDetail, attributes: [.font: UIFont.body, .foregroundColor: UIColor.textSubtle])

            if let underlinedText = viewModel.underlinedText {
                detail.underlineSubstring(underlinedText: underlinedText)
            }
        }

        return detail
    }

    func configureBackground() {
        backgroundColor = .listForeground(modal: false)
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
    }
}
