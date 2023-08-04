import UIKit

final class TitleAndSubtitleAndDetailTableViewCell: UITableViewCell, SearchResultCell {
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
        subtitleLabel.text = viewModel.subtitle
        accessibilityLabel = viewModel.accessibilityLabel
        setupTitleLabelText(with: viewModel)
    }
}

// MARK: - CellViewModel subtype
//
extension TitleAndSubtitleAndDetailTableViewCell {
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
    }
}

// MARK: - Setup
//
private extension TitleAndSubtitleAndDetailTableViewCell {
    func setupTitleLabelText(with viewModel: ViewModel) {
        let title = viewModel.title.trimmingCharacters(in: .whitespaces).isEmpty ?
        NSMutableAttributedString(string: viewModel.placeholderTitle, attributes: [.font: UIFont.body, .foregroundColor: UIColor.textSubtle]) :
        NSMutableAttributedString(string: viewModel.title, attributes: [.font: UIFont.body, .foregroundColor: UIColor.text])

        let detail = viewModel.detail.isEmpty ?
        NSAttributedString(string: "") :
        NSAttributedString(string: " • \(viewModel.detail)", attributes: [.font: UIFont.body, .foregroundColor: UIColor.textSubtle])

        title.append(detail)

        titleLabel.attributedText = title
    }

    func configureBackground() {
        backgroundColor = .listForeground(modal: false)
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
    }
}
