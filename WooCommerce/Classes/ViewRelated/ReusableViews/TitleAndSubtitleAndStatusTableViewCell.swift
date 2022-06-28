import UIKit

final class TitleAndSubtitleAndStatusTableViewCell: UITableViewCell, SearchResultCell {
    typealias SearchModel = ViewModel

    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var statusContainerView: UIView!
    @IBOutlet private var statusLabel: PaddedLabel!

    static func register(for tableView: UITableView) {
        tableView.registerNib(for: self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
    }

    func configureCell(searchModel: ViewModel) {
        configureCell(viewModel: searchModel)
    }

    func configureCell(viewModel: ViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        accessibilityLabel = viewModel.accessibilityLabel
        statusLabel.text = viewModel.status
        statusLabel.backgroundColor = viewModel.statusBackgroundColor
    }

}

// MARK: - CellViewModel subtype
//
extension TitleAndSubtitleAndStatusTableViewCell {
    struct ViewModel: Hashable {
        /// A unique ID to avoid duplicated identifier for the view model in diffable datasource.
        /// Please make sure to override this variable with a value corresponding to the content of the cell if you use diffable datasource,
        /// to avoid unnecessary animation when reloading the table view.
        var id: String = UUID().uuidString
        let title: String
        let subtitle: String
        let accessibilityLabel: String
        let status: String
        let statusBackgroundColor: UIColor
    }
}

// MARK: - Setup
//
private extension TitleAndSubtitleAndStatusTableViewCell {
    func configureBackground() {
        backgroundColor = .listForeground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        subtitleLabel.applyCaption1Style()
        titleLabel.applyBodyStyle()
        statusLabel.applyFootnoteStyle()
        statusLabel.numberOfLines = 0
        statusLabel.textColor = .black // constant because there will always background color on the label
        statusLabel.layer.cornerRadius = CGFloat(4.0)
        statusLabel.layer.masksToBounds = true
    }
}
