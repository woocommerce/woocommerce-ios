import Storage
import UIKit
import Yosemite

/// Contains UI for Beta features that can be turned on and off.
///
final class BetaFeaturesViewController: UIViewController {

    /// Main TableView
    ///
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        return tableView
    }()

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overridden Methods
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureMainView()
        configureSections()
        configureTableView()
        registerTableViewCells()
    }
}

// MARK: - View Configuration
//
private extension BetaFeaturesViewController {

    /// Set the title.
    ///
    func configureNavigationBar() {
        title = NSLocalizedString("Experimental Features", comment: "Experimental features navigation title")
    }

    /// Apply Woo styles.
    ///
    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    /// Configure common table properties.
    ///
    func configureTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(tableView)

        tableView.dataSource = self

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
    }

    /// Configure sections for table view.
    ///
    func configureSections() {
        self.sections = [
            productsSection(),
            orderCreationSection(),
            inPersonPaymentsSection(),
            productSKUInputScannerSection(),
            couponManagementSection()
        ].compactMap { $0 }
    }

    func productsSection() -> Section {
        return Section(rows: [.orderAddOns,
                              .orderAddOnsDescription])
    }

    func orderCreationSection() -> Section? {
        return Section(rows: [.orderCreation,
                              .orderCreationDescription])
    }

    func inPersonPaymentsSection() -> Section? {
        var rows: [Row] = []

        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.stripeExtensionInPersonPayments) {
            rows += [.stripeExtensionInPersonPayments, .stripeExtensionInPersonPaymentsDescription]
        }

        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.canadaInPersonPayments) {
            rows += [.canadaInPersonPayments, .canadaInPersonPaymentsDescription]
        }

        guard rows.isNotEmpty else {
            return nil
        }

        return Section(rows: rows)
    }

    func productSKUInputScannerSection() -> Section? {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productSKUInputScanner), UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return nil
        }

        return Section(rows: [.productSKUInputScanner,
                              .productSKUInputScannerDescription])
    }

    func couponManagementSection() -> Section? {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.couponManagement) else {
            return nil
        }
        return Section(rows: [.couponManagement,
                              .couponManagementDescription])
    }

    /// Register table cells.
    ///
    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        guard type(of: cell) == row.type else {
            assertionFailure("The type of cell (\(type(of: cell)) does not match the type (\(row.type)) for row: \(row)")
            return
        }

        switch cell {
        // Product list
        case let cell as SwitchTableViewCell where row == .orderAddOns:
            configureOrderAddOnsSwitch(cell: cell)
        case let cell as BasicTableViewCell where row == .orderAddOnsDescription:
            configureOrderAddOnsDescription(cell: cell)
        // Orders
        case let cell as SwitchTableViewCell where row == .orderCreation:
            configureOrderCreationSwitch(cell: cell)
        case let cell as BasicTableViewCell where row == .orderCreationDescription:
            configureOrderCreationDescription(cell: cell)
        // WooCommerce Stripe Payment Gateway extension In-Person Payments
        case let cell as SwitchTableViewCell where row == .stripeExtensionInPersonPayments:
            configureStripeExtensionInPersonPaymentsSwitch(cell: cell)
        case let cell as BasicTableViewCell where row == .stripeExtensionInPersonPaymentsDescription:
            configureStripeExtensionInPersonPaymentsDescription(cell: cell)
        // In-Person Payments in Canada
        case let cell as SwitchTableViewCell where row == .canadaInPersonPayments:
            configureCanadaInPersonPaymentsSwitch(cell: cell)
        case let cell as BasicTableViewCell where row == .canadaInPersonPaymentsDescription:
            configureCanadaInPersonPaymentsDescription(cell: cell)
        // Product SKU Input Scanner
        case let cell as SwitchTableViewCell where row == .productSKUInputScanner:
            configureProductSKUInputScannerSwitch(cell: cell)
        case let cell as BasicTableViewCell where row == .productSKUInputScannerDescription:
            configureProductSKUInputScannerDescription(cell: cell)
        case let cell as SwitchTableViewCell where row == .couponManagement:
            configureCouponManagementSwitch(cell: cell)
        case let cell as BasicTableViewCell where row == .couponManagementDescription:
            configureCouponManagementDescription(cell: cell)
        default:
            fatalError()
        }
    }

    // MARK: - Product List feature

    func configureOrderAddOnsSwitch(cell: SwitchTableViewCell) {
        configureCommonStylesForSwitchCell(cell)
        cell.title = Localization.orderAddOnsTitle

        // Fetch switch's state stored value.
        let action = AppSettingsAction.loadOrderAddOnsSwitchState() { result in
            guard let isEnabled = try? result.get() else {
                return cell.isOn = false
            }
            cell.isOn = isEnabled
        }
        ServiceLocator.stores.dispatch(action)

        // Change switch's state stored value
        cell.onChange = { isSwitchOn in
            ServiceLocator.analytics.track(event: WooAnalyticsEvent.OrderDetailAddOns.betaFeaturesSwitchToggled(isOn: isSwitchOn))

            let action = AppSettingsAction.setOrderAddOnsFeatureSwitchState(isEnabled: isSwitchOn, onCompletion: { result in
                // Roll back toggle if an error occurred
                if result.isFailure {
                    cell.isOn.toggle()
                }
            })
            ServiceLocator.stores.dispatch(action)
        }
        cell.accessibilityIdentifier = "beta-features-order-add-ons-cell"
    }

    func configureOrderAddOnsDescription(cell: BasicTableViewCell) {
        configureCommonStylesForDescriptionCell(cell)
        cell.textLabel?.text = Localization.orderAddOnsDescription
    }

    func configureOrderCreationSwitch(cell: SwitchTableViewCell) {
        configureCommonStylesForSwitchCell(cell)
        cell.title = Localization.orderCreationTitle

        // Fetch switch's state stored value.
        let action = AppSettingsAction.loadOrderCreationSwitchState() { result in
            guard let isEnabled = try? result.get() else {
                return cell.isOn = false
            }
            cell.isOn = isEnabled
        }
        ServiceLocator.stores.dispatch(action)

        // Change switch's state stored value
        cell.onChange = { isSwitchOn in
            let action = AppSettingsAction.setOrderCreationFeatureSwitchState(isEnabled: isSwitchOn, onCompletion: { result in
                // Roll back toggle if an error occurred
                if result.isFailure {
                    cell.isOn.toggle()
                }
            })
            ServiceLocator.stores.dispatch(action)
        }
        cell.accessibilityIdentifier = "beta-features-order-order-creation-cell"
    }

    func configureOrderCreationDescription(cell: BasicTableViewCell) {
        configureCommonStylesForDescriptionCell(cell)
        cell.textLabel?.text = Localization.orderCreationDescription
    }

    func configureStripeExtensionInPersonPaymentsSwitch(cell: SwitchTableViewCell) {
        configureCommonStylesForSwitchCell(cell)
        cell.title = Localization.stripeExtensionInPersonPaymentsTitle

        // Fetch switch's state stored value.
        let action = AppSettingsAction.loadStripeInPersonPaymentsSwitchState { result in
            guard let isEnabled = try? result.get() else {
                return cell.isOn = false
            }
            cell.isOn = isEnabled
        }
        ServiceLocator.stores.dispatch(action)

        // Change switch's state stored value
        cell.onChange = { isSwitchOn in
            let action = AppSettingsAction.setStripeInPersonPaymentsSwitchState(isEnabled: isSwitchOn, onCompletion: { result in
                // Roll back toggle if an error occurred
                if result.isFailure {
                    cell.isOn.toggle()
                }
            })
            ServiceLocator.stores.dispatch(action)
        }
        cell.accessibilityIdentifier = "beta-features-stripe-extension-in-person-payments-cell"
    }

    func configureStripeExtensionInPersonPaymentsDescription(cell: BasicTableViewCell) {
        configureCommonStylesForDescriptionCell(cell)
        cell.textLabel?.text = Localization.stripeExtensionInPersonPaymentsDescription
    }

    func configureCanadaInPersonPaymentsSwitch(cell: SwitchTableViewCell) {
        configureCommonStylesForSwitchCell(cell)
        cell.title = Localization.canadaExtensionInPersonPaymentsTitle

        // Fetch switch's state stored value.
        let action = AppSettingsAction.loadCanadaInPersonPaymentsSwitchState { result in
            guard let isEnabled = try? result.get() else {
                return cell.isOn = false
            }
            cell.isOn = isEnabled
        }
        ServiceLocator.stores.dispatch(action)

        // Change switch's state stored value
        cell.onChange = { isSwitchOn in
            let action = AppSettingsAction.setCanadaInPersonPaymentsSwitchState(isEnabled: isSwitchOn, onCompletion: { result in
                // Roll back toggle if an error occurred
                if result.isFailure {
                    cell.isOn.toggle()
                }
            })
            ServiceLocator.stores.dispatch(action)
        }
        cell.accessibilityIdentifier = "beta-features-canada-in-person-payments-cell"
    }

    func configureCanadaInPersonPaymentsDescription(cell: BasicTableViewCell) {
        configureCommonStylesForDescriptionCell(cell)
        cell.textLabel?.text = Localization.canadaExtensionInPersonPaymentsDescription
    }

    func configureProductSKUInputScannerSwitch(cell: SwitchTableViewCell) {
        configureCommonStylesForSwitchCell(cell)
        cell.title = Localization.productSKUInputScannerTitle

        // Fetch switch's state stored value.
        let action = AppSettingsAction.loadProductSKUInputScannerFeatureSwitchState { result in
            guard let isEnabled = try? result.get() else {
                return cell.isOn = false
            }
            cell.isOn = isEnabled
        }
        ServiceLocator.stores.dispatch(action)

        // Change switch's state stored value
        cell.onChange = { isSwitchOn in
            let action = AppSettingsAction.setProductSKUInputScannerFeatureSwitchState(isEnabled: isSwitchOn, onCompletion: { result in
                // Roll back toggle if an error occurred
                if result.isFailure {
                    cell.isOn.toggle()
                }
            })
            ServiceLocator.stores.dispatch(action)
        }
        cell.accessibilityIdentifier = "beta-features-product-sku-input-scanner-cell"
    }

    func configureProductSKUInputScannerDescription(cell: BasicTableViewCell) {
        configureCommonStylesForDescriptionCell(cell)
        cell.textLabel?.text = Localization.productSKUInputScannerDescription
    }

    func configureCouponManagementSwitch(cell: SwitchTableViewCell) {
        configureCommonStylesForSwitchCell(cell)
        cell.title = Localization.couponManagementTitle

        // Fetch switch's state stored value.
        let action = AppSettingsAction.loadCouponManagementFeatureSwitchState { result in
            guard let isEnabled = try? result.get() else {
                return cell.isOn = false
            }
            cell.isOn = isEnabled
        }
        ServiceLocator.stores.dispatch(action)

        // Change switch's state stored value
        cell.onChange = { isSwitchOn in
            let action = AppSettingsAction.setCouponManagementFeatureSwitchState(isEnabled: isSwitchOn, onCompletion: { result in
                // Roll back toggle if an error occurred
                if result.isFailure {
                    cell.isOn.toggle()
                }
            })
            ServiceLocator.stores.dispatch(action)
        }
        cell.accessibilityIdentifier = "beta-features-coupon-management-cell"
    }

    func configureCouponManagementDescription(cell: BasicTableViewCell) {
        configureCommonStylesForDescriptionCell(cell)
        cell.textLabel?.text = Localization.couponManagementDescription
    }
}

// MARK: - Shared Configurations
//
private extension BetaFeaturesViewController {
    func configureCommonStylesForSwitchCell(_ cell: SwitchTableViewCell) {
        cell.accessoryType = .none
        cell.selectionStyle = .none
    }

    func configureCommonStylesForDescriptionCell(_ cell: BasicTableViewCell) {
        cell.accessoryType = .none
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
    }
}


// MARK: - Convenience Methods
//
private extension BetaFeaturesViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension BetaFeaturesViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - Private Types
//
private struct Constants {
    static let rowHeight = CGFloat(44)
}

private struct Section {
    let rows: [Row]
}

private enum Row: CaseIterable {
    // Products.
    case orderAddOns
    case orderAddOnsDescription

    // Orders.
    case orderCreation
    case orderCreationDescription

    // WooCommerce Stripe Payment Gateway extension In-Person Payments
    case stripeExtensionInPersonPayments
    case stripeExtensionInPersonPaymentsDescription

    // In-Person Payments in Canada
    case canadaInPersonPayments
    case canadaInPersonPaymentsDescription

    // Product SKU Input Scanner
    case productSKUInputScanner
    case productSKUInputScannerDescription

    // Coupon management
    case couponManagement
    case couponManagementDescription

    var type: UITableViewCell.Type {
        switch self {
        case .orderAddOns, .orderCreation, .stripeExtensionInPersonPayments, .canadaInPersonPayments, .productSKUInputScanner, .couponManagement:
            return SwitchTableViewCell.self
        case .orderAddOnsDescription, .orderCreationDescription, .stripeExtensionInPersonPaymentsDescription, .canadaInPersonPaymentsDescription,
                .productSKUInputScannerDescription, .couponManagementDescription:
            return BasicTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

private extension BetaFeaturesViewController {
    enum Localization {
        static let orderAddOnsTitle = NSLocalizedString(
            "View Add-Ons",
            comment: "Cell title on the beta features screen to enable the order add-ons feature")
        static let orderAddOnsDescription = NSLocalizedString(
            "Test out viewing Order Add-Ons as we get ready to launch",
            comment: "Cell description on the beta features screen to enable the order add-ons feature")

        static let orderCreationTitle = NSLocalizedString(
            "Order Creation",
            comment: "Cell title on the beta features screen to enable creating new orders")
        static let orderCreationDescription = NSLocalizedString(
            "Test out creating new manual orders as we get ready to launch",
            comment: "Cell description on the beta features screen to enable creating new orders")

        static let stripeExtensionInPersonPaymentsTitle = NSLocalizedString(
            "IPP with Stripe extension",
            comment: "Cell title on beta features screen to enable accepting in-person payments for stores with the " +
            "WooCommerce Stripe Payment Gateway extension")
        static let stripeExtensionInPersonPaymentsDescription = NSLocalizedString(
            "Test out In-Person Payments with the Stripe Payment Gateway extension",
            comment: "Cell description on beta features screen to enable accepting in-person payments for stores with " +
            "the WooCommerce Stripe Payment Gateway extension")

        static let canadaExtensionInPersonPaymentsTitle = NSLocalizedString(
            "In-Person Payments in Canada",
            comment: "Cell title on beta features screen to enable accepting in-person payments for stores in Canada ")
        static let canadaExtensionInPersonPaymentsDescription = NSLocalizedString(
            "Test out In-Person Payments in Canada",
            comment: "Cell description on beta features screen to enable accepting in-person payments for stores in Canada")

        static let productSKUInputScannerTitle = NSLocalizedString(
            "Product SKU Scanner",
            comment: "Cell title on beta features screen to enable product SKU input scanner in inventory settings.")
        static let productSKUInputScannerDescription = NSLocalizedString(
            "Test out scanning a barcode for a product SKU in the product inventory settings",
            comment: "Cell description on beta features screen to enable product SKU input scanner in inventory settings.")

        static let couponManagementTitle = NSLocalizedString("Coupon Management", comment: "Cell title on beta features screen to enable coupon management")
        static let couponManagementDescription = NSLocalizedString(
            "Test out coupon management as we get ready to launch",
            comment: "Cell description on beta features screen to enable coupon management"
        )
    }
}
