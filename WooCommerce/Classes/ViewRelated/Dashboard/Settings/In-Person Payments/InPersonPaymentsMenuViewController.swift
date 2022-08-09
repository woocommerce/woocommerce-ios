import UIKit
import SwiftUI
import Yosemite
import Experiments

final class InPersonPaymentsMenuViewController: UITableViewController {
    private let stores: StoresManager
    private let pluginState: CardPresentPaymentsPluginState?
    private var sections = [Section]()
    private let configurationLoader: CardPresentConfigurationLoader
    private let onPluginSelected: ((CardPresentPaymentsPlugin) -> Void)?
    private let onPluginSelectionCleared: (() -> Void)?
    private let featureFlagService: FeatureFlagService

    init(
        pluginState: CardPresentPaymentsPluginState?,
        onPluginSelected: ((CardPresentPaymentsPlugin) -> Void)?,
        onPluginSelectionCleared: ( () -> Void)?,
        stores: StoresManager = ServiceLocator.stores,
        featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService
    ) {
        self.pluginState = pluginState
        self.onPluginSelected = onPluginSelected
        self.onPluginSelectionCleared = onPluginSelectionCleared
        self.stores = stores
        self.featureFlagService = featureFlagService
        configurationLoader = CardPresentConfigurationLoader()
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureSections()
        configureTableView()
        registerTableViewCells()
    }
}

// MARK: - View configuration
//
private extension InPersonPaymentsMenuViewController {
    func configureSections() {
        sections = [
            actionsSection,
            cardReadersSection,
            paymentOptionsSection
        ].compactMap { $0 }
    }

    var actionsSection: Section? {
        guard featureFlagService.isFeatureFlagEnabled(.paymentsHubMenuSection) else {
            return nil
        }

        return Section(header: Localization.paymentActionsSectionTitle, rows: [.collectPayment])
    }

    var cardReadersSection: Section? {
        let rows: [Row] = [
                .orderCardReader,
                .manageCardReader,
                .cardReaderManuals
            ]
        return Section(header: Localization.cardReaderSectionTitle, rows: rows)
    }

    var paymentOptionsSection: Section? {
        guard pluginState?.available.containsMoreThanOne ?? false else {
            return nil
        }
        return Section(header: Localization.paymentOptionsSectionTitle, rows: [.managePaymentGateways])
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as LeftImageTableViewCell where row == .orderCardReader:
            configureOrderCardReader(cell: cell)
        case let cell as LeftImageTableViewCell where row == .manageCardReader:
            configureManageCardReader(cell: cell)
        case let cell as LeftImageTitleSubtitleTableViewCell where row == .managePaymentGateways:
            configureManagePaymentGateways(cell: cell)
        case let cell as LeftImageTableViewCell where row == .cardReaderManuals:
            configureCardReaderManuals(cell: cell)
        case let cell as LeftImageTableViewCell where row == .collectPayment:
            configureCollectPayment(cell: cell)
        default:
            fatalError()
        }
    }

    func configureOrderCardReader(cell: LeftImageTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.configure(image: .shoppingCartIcon, text: Localization.orderCardReader)
    }

    func configureManageCardReader(cell: LeftImageTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.configure(image: .creditCardIcon, text: Localization.manageCardReader)
    }

    func configureManagePaymentGateways(cell: LeftImageTitleSubtitleTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.configure(image: .rectangleOnRectangleAngled, text: Localization.managePaymentGateways, subtitle: pluginState?.preferred.pluginName ?? "")
    }

    func configureCardReaderManuals(cell: LeftImageTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.configure(image: .cardReaderManualIcon, text: Localization.cardReaderManuals)
    }

    func configureCollectPayment(cell: LeftImageTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.configure(image: .moneyIcon, text: Localization.collectPayment)
    }
}

// MARK: - Convenience methods
//
private extension InPersonPaymentsMenuViewController {
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        sections[indexPath.section].rows[indexPath.row]
    }
}

// MARK: - Actions
//
extension InPersonPaymentsMenuViewController {
    func orderCardReaderWasPressed() {
        WebviewHelper.launch(configurationLoader.configuration.purchaseCardReaderUrl(), with: self)
    }

    func manageCardReaderWasPressed() {
        ServiceLocator.analytics.track(.settingsCardReadersTapped)
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: CardReaderSettingsPresentingViewController.self) else {
            fatalError("Cannot instantiate `CardReaderSettingsPresentingViewController` from Dashboard storyboard")
        }

        let viewModelsAndViews = CardReaderSettingsViewModelsOrderedList(configuration: configurationLoader.configuration)
        viewController.configure(viewModelsAndViews: viewModelsAndViews)
        show(viewController, sender: self)
    }

    func cardReaderManualsWasPressed() {
        let view = UIHostingController(rootView: CardReaderManualsView())
        navigationController?.pushViewController(view, animated: true)
    }

    func managePaymentGatewaysWasPressed() {
        ServiceLocator.analytics.track(.settingsCardPresentSelectedPaymentGatewayTapped)
        onPluginSelectionCleared?()
    }

    func collectPaymentWasPressed() {
        guard let siteID = stores.sessionManager.defaultStoreID,
              let navigationController = navigationController else {
            return
        }

        SimplePaymentsAmountFlowOpener.openSimplePaymentsAmountFlow(from: navigationController, siteID: siteID)
    }
}

// MARK: - UITableViewDataSource
extension InPersonPaymentsMenuViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate
//
extension InPersonPaymentsMenuViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // listed in the order they are displayed
        switch rowAtIndexPath(indexPath) {
        case .orderCardReader:
            orderCardReaderWasPressed()
        case .manageCardReader:
            manageCardReaderWasPressed()
        case .cardReaderManuals:
            cardReaderManualsWasPressed()
        case .managePaymentGateways:
            managePaymentGatewaysWasPressed()
        case .collectPayment:
            collectPaymentWasPressed()
        }
    }
}

// MARK: - Localizations
//
private extension InPersonPaymentsMenuViewController {
    enum Localization {
        static let cardReaderSectionTitle = NSLocalizedString(
            "Card readers",
            comment: "Title for the section related to card readers inside In-Person Payments settings")

        static let paymentOptionsSectionTitle = NSLocalizedString(
            "Payment options",
            comment: "Title for the section related to payments inside In-Person Payments settings")

        static let paymentActionsSectionTitle = NSLocalizedString(
            "Actions",
            comment: "Title for the section related to actions inside In-Person Payments settings")

        static let orderCardReader = NSLocalizedString(
            "Order card reader",
            comment: "Navigates to Card Reader ordering screen"
        )

        static let manageCardReader = NSLocalizedString(
            "Manage card reader",
            comment: "Navigates to Card Reader management screen"
        )

        static let managePaymentGateways = NSLocalizedString(
            "Payment Provider",
            comment: "Navigates to Payment Gateway management screen"
        )

        static let cardReaderManuals = NSLocalizedString(
            "Card Reader Manuals",
            comment: "Navigates to Card Reader Manuals screen"
        )

        static let collectPayment = NSLocalizedString(
            "Collect Payment",
            comment: "Navigates to Collect a payment via the Simple Payment screen"
        )
    }
}

private struct Section {
    let header: String
    let rows: [Row]
}

private enum Row: CaseIterable {
    case orderCardReader
    case manageCardReader
    case cardReaderManuals
    case managePaymentGateways
    case collectPayment

    var type: UITableViewCell.Type {
        switch self {
        case .managePaymentGateways:
            return LeftImageTitleSubtitleTableViewCell.self
        default:
            return LeftImageTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

// MARK: - SwiftUI compatibility
//

/// SwiftUI wrapper for CardReaderSettingsPresentingViewController
///
struct InPersonPaymentsMenu: UIViewControllerRepresentable {
    let pluginState: CardPresentPaymentsPluginState?
    let onPluginSelected: ((CardPresentPaymentsPlugin) -> Void)?
    let onPluginSelectionCleared: (() -> Void)?

    func makeUIViewController(context: Context) -> some UIViewController {
        InPersonPaymentsMenuViewController(pluginState: pluginState, onPluginSelected: onPluginSelected, onPluginSelectionCleared: onPluginSelectionCleared)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}
