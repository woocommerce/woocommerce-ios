import UIKit
import Yosemite


// MARK: - OrderTableViewCell
//
final class OrderTableViewCell: UITableViewCell & SearchResultCell {
    typealias SearchModel = OrderSearchCellViewModel

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

    func configureCell(searchModel: OrderSearchCellViewModel) {
        configureCell(viewModel: searchModel.orderDetailsViewModel,
                      orderStatus: searchModel.orderStatus)
    }

    /// Renders the specified Order ViewModel
    ///
    /// If the `viewModel` is not given, then the UI will be set to empty.
    ///
    func configureCell(viewModel: OrderDetailsViewModel?, orderStatus: OrderStatus?) {
        guard let viewModel = viewModel else {
            resetLabels()
            return
        }

        titleLabel.text = title(for: viewModel.order)
        totalLabel.text = viewModel.totalFriendlyString
        dateCreatedLabel.text = viewModel.formattedDateCreated

        if let orderStatus = orderStatus {
            paymentStatusLabel.applyStyle(for: orderStatus.status)
            paymentStatusLabel.text = orderStatus.name
        } else {
            // There are unsupported extensions with even more statuses available.
            // So let's use the order.status to display those as slugs.
            let status = viewModel.order.status
            paymentStatusLabel.applyStyle(for: status)
            paymentStatusLabel.text = status.rawValue
        }
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

    /// For example, #560 Pamela Nguyen
    ///
    func title(for order: Order) -> String {
        let customerName: String = {
            if let fullName = order.billingAddress?.fullName, fullName.isNotEmpty {
                return fullName
            }
            return Localization.guestName
        }()

        return Localization.title(orderNumber: order.number, customerName: customerName)
    }
}

// MARK: - Setup

private extension OrderTableViewCell {
    func configureBackground() {
        backgroundColor = .listForeground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
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

// MARK: - Constants

private extension OrderTableViewCell {
    enum Localization {
        static func title(orderNumber: String, customerName: String) -> String {
            let format = NSLocalizedString("#%@ %@", comment: "In Order List,"
                + " the pattern to show the order number. For example, “#123456”."
                + " The %@ placeholder is the order number.")

            return String.localizedStringWithFormat(format, orderNumber, customerName)
        }

        static let guestName = NSLocalizedString("Guest", comment: "In Order List, the name of the billed person when there are no name and last name.")
    }
}
