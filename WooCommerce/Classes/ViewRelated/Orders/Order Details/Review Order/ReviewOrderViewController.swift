import UIKit
import Yosemite

/// View Control for Review Order screen
/// This screen is shown when Mark Order Complete button is tapped
///
final class ReviewOrderViewController: UIViewController {

    /// View model to provide order info for review
    ///
    private let viewModel: ReviewOrderViewModel

    /// Image service needed for order item cells
    ///
    private let imageService: ImageService = ServiceLocator.imageService

    /// Table view to display order details
    ///
    @IBOutlet private var tableView: UITableView!

    init(viewModel: ReviewOrderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureTableView()

        viewModel.syncTrackingsHidingAddButtonIfNecessary { [weak self] in
            self?.tableView.reloadData()
        }
    }

}

// MARK: - UI Configuration
//
private extension ReviewOrderViewController {
    func configureNavigation() {
        title = Localization.screenTitle
    }

    func configureTableView() {
        for headerType in viewModel.allHeaderTypes {
            tableView.register(headerType.loadNib(), forHeaderFooterViewReuseIdentifier: headerType.reuseIdentifier)
        }

        for cellType in viewModel.allCellTypes {
            tableView.registerNib(for: cellType)
        }

        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
    }
}

// MARK: - UITableViewDatasource conformance
//
extension ReviewOrderViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.cellType.reuseIdentifier, for: indexPath)
        setup(cell: cell, for: row, at: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate conformance
//
extension ReviewOrderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = viewModel.sections[safe: section] else {
            return nil
        }

        let reuseIdentifier = section.headerType.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier) else {
            assertionFailure("Could not find section header view for reuseIdentifier \(reuseIdentifier)")
            return nil
        }

        switch headerView {
        case let headerView as PrimarySectionHeaderView:
            switch section.category {
            case .products:
                let sectionTitle = viewModel.order.items.count > 1 ? Localization.productsSectionTitle : Localization.productSectionTitle
                headerView.configure(title: sectionTitle)
            case .customerInformation, .tracking:
                assertionFailure("Unexpected category of type \(headerView.self)")
            }
        case let headerView as TwoColumnSectionHeaderView:
            switch section.category {
            case .customerInformation:
                headerView.leftText = Localization.customerSectionTitle
                headerView.rightText = nil
            case .tracking:
                headerView.leftText = Localization.trackingSectionTitle
                headerView.rightText = nil
            case .products:
                assertionFailure("Unexpected category of type \(headerView.self)")
            }
        default:
            assertionFailure("Unexpected headerView type \(headerView.self)")
            return nil
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = viewModel.sections[safe: indexPath.section]?.rows[safe: indexPath.row] else {
            return
        }
        switch row {
        case .billingDetail:
            billingInformationTapped()
        default:
            break
        }
    }
}

// MARK: - Setup cells for the table view
//
private extension ReviewOrderViewController {
    /// Setup a given UITableViewCell instance to actually display the specified Row's Payload.
    ///
    func setup(cell: UITableViewCell, for row: ReviewOrderViewModel.Row, at indexPath: IndexPath) {
        switch row {
        case .orderItem(let item):
            setupOrderItemCell(cell, with: item)
        case .customerNote(let text):
            setupCustomerNoteCell(cell, with: text)
        case .shippingAddress(let address):
            setupAddressCell(cell, with: address)
        case .shippingMethod(let method):
            setupShippingMethodCell(cell, method: method)
        case .billingDetail:
            setupBillingDetail(cell)
        case .trackingAdd:
            setupTrackingAddCell(cell)
        case .tracking:
            // TODO: UPDATE!!!
            break
        }
    }

    /// Setup: Order item Cell
    ///
    private func setupOrderItemCell(_ cell: UITableViewCell, with item: OrderItem) {
        guard let cell = cell as? ProductDetailsTableViewCell else {
            fatalError("⛔ Incorrect cell type for Product Details cell")
        }

        let itemViewModel = viewModel.productDetailsCellViewModel(for: item)
        cell.configure(item: itemViewModel, imageService: imageService)
        cell.onViewAddOnsTouchUp = { [weak self] in
            guard let self = self else { return }
            self.itemAddOnsButtonTapped(addOns: self.viewModel.filterAddons(for: item))
        }
    }

    /// Setup: Customer Note Cell
    ///
    private func setupCustomerNoteCell(_ cell: UITableViewCell, with note: String) {
        guard let cell = cell as? CustomerNoteTableViewCell else {
            fatalError("⛔ Incorrect cell type for Customer Note cell")
        }

        cell.headline = Localization.customerNoteTitle
        let localizedBody = String.localizedStringWithFormat(
            NSLocalizedString("“%@”",
                              comment: "Customer note, wrapped in quotes"),
            note)
        cell.body = localizedBody
        cell.selectionStyle = .none
    }

    /// Setup: Address Cell
    ///
    private func setupAddressCell(_ cell: UITableViewCell, with address: Address?) {
        guard let cell = cell as? CustomerInfoTableViewCell else {
            fatalError("⛔ Incorrect cell type for Address cell")
        }
        cell.title = Localization.shippingAddressTitle
        cell.name = address?.fullNameWithCompany
        cell.address = address?.formattedPostalAddress ?? Localization.noAddressCellTitle
    }

    /// Setup: Shipping Method cell
    ///
    func setupShippingMethodCell(_ cell: UITableViewCell, method: String?) {
        guard let cell = cell as? CustomerNoteTableViewCell else {
            fatalError("⛔ Incorrect cell type for Shipping Method cell")
        }

        cell.headline = Localization.shippingMethodTitle
        cell.body = method?.strippedHTML
        cell.selectionStyle = .none
    }

    /// Setup: Billing Detail cell
    ///
    func setupBillingDetail(_ cell: UITableViewCell) {
        guard let cell = cell as? WooBasicTableViewCell else {
            fatalError("⛔ Incorrect cell type for Billing Detail cell")
        }
        cell.bodyLabel?.text = Localization.showBillingTitle
        cell.applyPlainTextStyle()
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = Localization.showBillingAccessibilityLabel
        cell.accessibilityHint = Localization.showBillingAccessibilityHint
    }

    /// Setup: Add Tracking Cell
    ///
    func setupTrackingAddCell(_ cell: UITableViewCell) {
        guard let cell = cell as? LeftImageTableViewCell else {
            fatalError()
        }

        let cellTextContent = Localization.addTrackingTitle
        cell.leftImage = .addOutlineImage
        cell.imageView?.tintColor = .accent
        cell.labelText = cellTextContent

        cell.isAccessibilityElement = true

        cell.accessibilityLabel = cellTextContent
        cell.accessibilityTraits = .button
        cell.accessibilityHint = Localization.addTrackingAccessibilityHint
    }
}

// MARK: - Actions
//
private extension ReviewOrderViewController {
    /// Show addon list screen
    ///
    func itemAddOnsButtonTapped(addOns: [OrderItemAttribute]) {
        let addOnsViewModel = OrderAddOnListI1ViewModel(attributes: addOns)
        let addOnsController = OrderAddOnsListViewController(viewModel: addOnsViewModel)
        let navigationController = WooNavigationController(rootViewController: addOnsController)
        present(navigationController, animated: true, completion: nil)
    }

    /// Show billing information screen
    ///
    func billingInformationTapped() {
        ServiceLocator.analytics.track(.orderDetailShowBillingTapped)
        let billingInformationViewController = BillingInformationViewController(order: viewModel.order)
        navigationController?.pushViewController(billingInformationViewController, animated: true)
    }
}

// MARK: - Miscellanous
//
private extension ReviewOrderViewController {
    /// Some magic numbers for table view UI 🪄
    ///
    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }

    /// Localized copies
    ///
    enum Localization {
        static let screenTitle = NSLocalizedString("Review Order", comment: "Title of Review Order screen")
        static let productSectionTitle = NSLocalizedString("Product", comment: "Product section title in Review Order screen if there is one product.")
        static let productsSectionTitle = NSLocalizedString("Products",
                                                            comment: "Product section title in Review Order screen if there is more than one product.")
        static let customerSectionTitle = NSLocalizedString("Customer", comment: "Customer info section title in Review Order screen")
                static let trackingSectionTitle = NSLocalizedString("Tracking", comment: "Tracking section title in Review Order screen")
                static let customerNoteTitle = NSLocalizedString("Customer Provided Note", comment: "Customer note row title")
                static let shippingAddressTitle = NSLocalizedString("Shipping Address", comment: "Shipping Address title for customer info section")
                static let noAddressCellTitle = NSLocalizedString(
                    "No address specified.",
                    comment: "Order details > customer info > shipping details. This is where the address would normally display."
                )
                static let shippingMethodTitle = NSLocalizedString("Shipping Method", comment: "Shipping method title for customer info section")
                static let showBillingTitle = NSLocalizedString("View Billing Information",
                                                                comment: "Button on bottom of Customer's information to show the billing details")
                static let showBillingAccessibilityLabel = NSLocalizedString(
                    "View Billing Information",
                    comment: "Accessibility label for the 'View Billing Information' button"
                )
                static let showBillingAccessibilityHint = NSLocalizedString(
                    "Show the billing details for this order.",
                    comment: "VoiceOver accessibility hint, informing the user that the button can be used to view billing information."
                )
        static let addTrackingTitle = NSLocalizedString("Add Tracking", comment: "Add Tracking row label")
        static let addTrackingAccessibilityHint = NSLocalizedString(
            "Adds tracking to an order.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to add tracking to an order. Should end with a period."
        )
    }
}
