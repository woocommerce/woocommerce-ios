import UIKit
import Yosemite


// MARK: - OrderTableViewCell
//
final class OrderTableViewCell: UITableViewCell & SearchResultCell {
    typealias SearchModel = OrderListCellViewModel

    /// Order's Title
    ///
    @IBOutlet private var titleLabel: UILabel!

    /// Order's Total
    ///
    @IBOutlet private var totalLabel: UILabel!

    /// Order's Creation Date
    ///
    @IBOutlet private var dateCreatedLabel: UILabel!

    /// Payment
    ///
    @IBOutlet private var paymentStatusLabel: PaddedLabel!

    /// Top-level stack view that contains the stack view of title and payment status labels, and total price label.
    ///
    @IBOutlet weak var contentStackView: UIStackView!

    static func register(for tableView: UITableView) {
        tableView.registerNib(for: self)
    }

    func configureCell(searchModel: OrderListCellViewModel) {
        configureCell(viewModel: searchModel)
    }

    /// Renders the specified Order ViewModel
    ///
    /// If the `viewModel` is not given, then the UI will be set to empty.
    ///
    func configureCell(viewModel: OrderListCellViewModel?) {
        guard let viewModel = viewModel else {
            resetLabels()
            return
        }

        titleLabel.text = viewModel.title
        totalLabel.text = viewModel.total
        dateCreatedLabel.text = viewModel.dateCreated
        accessibilityIdentifier = viewModel.title

        paymentStatusLabel.applyStyle(for: viewModel.status)
        paymentStatusLabel.text = viewModel.statusString

        accessoryType = .none
        accessoryView = viewModel.accessoryView

        // From iOS 15.0, a focus effect will be applied automatically to a selected cell
        // modifying its style (e.g: by adding a border)
        focusEffect = nil

    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.preferredContentSizeCategory > .extraExtraLarge {
            contentStackView.axis = .vertical
        } else {
            contentStackView.axis = .horizontal
        }
    }

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        preserveLabelColors {
            super.setSelected(selected, animated: animated)
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        preserveLabelColors {
            super.setHighlighted(highlighted, animated: animated)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        paymentStatusLabel.layer.borderColor = UIColor.clear.cgColor
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}


// MARK: - Private
//
private extension OrderTableViewCell {

    /// Reset the UI to a "no data" state.
    ///
    func resetLabels() {
        titleLabel.text = nil
        totalLabel.text = nil
        dateCreatedLabel.text = nil
        paymentStatusLabel.applyStyle(for: .failed)
        paymentStatusLabel.text = nil
    }

    /// Preserves the current Payment BG Color
    ///
    func preserveLabelColors(action: () -> Void) {
        let paymentColor = paymentStatusLabel.backgroundColor
        let borderColor = paymentStatusLabel.layer.borderColor

        action()

        paymentStatusLabel.backgroundColor = paymentColor
        paymentStatusLabel.layer.borderColor = borderColor
    }
}

// MARK: - Setup

private extension OrderTableViewCell {
    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        titleLabel.applyBodyStyle()
        totalLabel.applyBodyStyle()
        totalLabel.numberOfLines = 0
        paymentStatusLabel.applyFootnoteStyle()
        paymentStatusLabel.numberOfLines = 0

        dateCreatedLabel.applyCaption1Style()
    }
}
