import UIKit

final class TitleAndSubtitleAndDetailTableViewCell: UITableViewCell, SearchResultCell {
    typealias SearchModel = ViewModel

    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var titleLabel: UILabel!

    @IBOutlet weak var detailLabel: UILabel!

    static func register(for tableView: UITableView) {
        tableView.registerNib(for: self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
    }

    func configureCell(searchModel: ViewModel) {
        configureCell(viewModel: searchModel)
    }

    func configureCell(viewModel: ViewModel) {
        titleLabel.text = viewModel.title.trimmingCharacters(in: .whitespaces).isEmpty ? viewModel.placeholderTitle : viewModel.title
        subtitleLabel.text = viewModel.subtitle.isEmpty ? viewModel.placeholderSubtitle : viewModel.subtitle
        accessibilityLabel = viewModel.accessibilityLabel
        detailLabel.text = viewModel.detail.isEmpty ? "" : " • \(viewModel.detail)"

        configureLabels(with: viewModel)
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
        let placeholderSubtitle: String
        let accessibilityLabel: String
        let detail: String
    }
}

// MARK: - Setup
//
private extension TitleAndSubtitleAndDetailTableViewCell {
    func configureBackground() {
        backgroundColor = .listForeground(modal: false)
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
    }

    /// Setup: Labels
    ///
    func configureLabels(with viewModel: ViewModel) {
        subtitleLabel.text == viewModel.placeholderSubtitle ? subtitleLabel.applyCaption1Style() : subtitleLabel.applyStrongCaption1Style()
        titleLabel.text == viewModel.placeholderTitle ? titleLabel.applyBodySubtleStyle() : titleLabel.applyBodyStyle()
        detailLabel.applyBodySubtleStyle()

        titleLabel.sizeToFit()
    }
}
