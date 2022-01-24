import UIKit

final class TitleAndSubtitleAndStatusTableViewCell: UITableViewCell {

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
    struct ViewModel {
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
