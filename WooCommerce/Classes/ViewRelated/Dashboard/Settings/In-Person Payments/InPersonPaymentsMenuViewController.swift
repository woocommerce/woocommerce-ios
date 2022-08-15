import UIKit
import SwiftUI
import Yosemite
import Experiments
import Combine

final class InPersonPaymentsMenuViewController: UIViewController {
    private let stores: StoresManager
    private var pluginState: CardPresentPaymentsPluginState?
    private var sections = [Section]()
    private let configurationLoader: CardPresentConfigurationLoader
    private let onPluginSelected: ((CardPresentPaymentsPlugin) -> Void)?
    private let onPluginSelectionCleared: (() -> Void)?
    private let featureFlagService: FeatureFlagService
    private let cardPresentPaymentsOnboardingUseCase: CardPresentPaymentsOnboardingUseCase
    private var cancellables: Set<AnyCancellable> = []

    /// Main TableView
    ///
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        return tableView
    }()

    private lazy var permanentNoticePresenter: PermanentNoticePresenter = {
        PermanentNoticePresenter()
    }()

    private var activityIndicator: UIActivityIndicatorView?

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
        self.cardPresentPaymentsOnboardingUseCase = CardPresentPaymentsOnboardingUseCase()
        configurationLoader = CardPresentConfigurationLoader()

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureSections()
        configureTableView()
        registerTableViewCells()

        if featureFlagService.isFeatureFlagEnabled(.paymentsHubMenuSection) {
            runCardPresentPaymentsOnboarding()
        }
    }
}

// MARK: - Card Present Payments Readiness

private extension InPersonPaymentsMenuViewController {
    func runCardPresentPaymentsOnboarding() {
        cardPresentPaymentsOnboardingUseCase.refresh()

        cardPresentPaymentsOnboardingUseCase.$state
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] state in
                self?.refreshAfterNewOnboardingState(state)
        }).store(in: &cancellables)
    }

    func refreshAfterNewOnboardingState(_ state: CardPresentPaymentOnboardingState) {
        self.pluginState = nil

        guard state != .loading else {
            self.activityIndicator?.startAnimating()
            return
        }

        switch state {
        case let .completed(newPluginState):
            self.pluginState = newPluginState
            self.dismissCardPresentPaymentsOnboardingNoticeIfPresent()
        case let .selectPlugin(pluginSelectionWasCleared):
            // If it was cleared it means that we triggered it manually (e.g by tapping in this view on the plugin selection row)
            // No need to show the onboarding notice
            if !pluginSelectionWasCleared {
                self.showCardPresentPaymentsOnboardingNotice()
            }
        default:
            self.showCardPresentPaymentsOnboardingNotice()
        }

        self.activityIndicator?.stopAnimating()
        self.configureSections()
        self.tableView.reloadData()
    }

    func showCardPresentPaymentsOnboardingNotice() {
        let permanentNotice = PermanentNotice(message: Localization.inPersonPaymentsSetupNotFinishedNotice,
                                              callToActionTitle: Localization.inPersonPaymentsSetupNotFinishedNoticeButtonTitle,
                                              callToActionHandler: { [weak self] in
            ServiceLocator.analytics.track(.paymentsMenuOnboardingErrorTapped)
            self?.showOnboarding()
        })

        permanentNoticePresenter.presentNotice(notice: permanentNotice, from: self)
    }

    func dismissCardPresentPaymentsOnboardingNoticeIfPresent() {
        permanentNoticePresenter.dismiss()
    }

    func showOnboarding() {
        guard let navigationController = self.navigationController else {
            return
        }

        // Instead of using `CardPresentPaymentsOnboardingPresenter` we create the view directly because we already have the onboarding state in the use case.
        // That way we avoid triggering the onboarding check again that comes with the presenter.
        let onboardingViewModel = InPersonPaymentsViewModel(useCase: cardPresentPaymentsOnboardingUseCase)
        onboardingViewModel.onOnboardingCompletion = { [weak self] plugin in
            self?.refreshAfterNewOnboardingState(.completed(plugin: plugin))
            if navigationController.visibleViewController is InPersonPaymentsViewController {
                navigationController.popViewController(animated: true)
            }
        }

        let onboardingViewController = InPersonPaymentsViewController(viewModel: onboardingViewModel)
        show(onboardingViewController, sender: self)
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
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(tableView)

        tableView.rowHeight = UITableView.automaticDimension

        tableView.dataSource = self
        tableView.delegate = self

        if featureFlagService.isFeatureFlagEnabled(.paymentsHubMenuSection) {
            setupBottomActivityIndicator()
        }
    }

    func setupBottomActivityIndicator() {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: Layout.tableViewFooterHeight))
        let newActivityIndicator = UIActivityIndicatorView(style: .medium)

        newActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(newActivityIndicator)
        containerView.pinSubviewAtCenter(newActivityIndicator)

        activityIndicator = newActivityIndicator
        tableView.tableFooterView = containerView
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
        let cellShouldBeEnabled = cardPresentPaymentsOnboardingUseCase.state.isCompleted
        cell.imageView?.tintColor = .text
        cell.accessoryType = cellShouldBeEnabled ? .disclosureIndicator : .none
        cell.selectionStyle = .default
        cell.configure(image: .creditCardIcon, text: Localization.manageCardReader)

        updateEnabledState(in: cell, shouldBeEnabled: cellShouldBeEnabled)
    }

    func configureManagePaymentGateways(cell: LeftImageTitleSubtitleTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.configure(image: .rectangleOnRectangleAngled, text: Localization.managePaymentGateways, subtitle: pluginState?.preferred.pluginName ?? "")

        updateEnabledState(in: cell)
    }

    func configureCardReaderManuals(cell: LeftImageTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.configure(image: .cardReaderManualIcon, text: Localization.cardReaderManuals)

        updateEnabledState(in: cell)
    }

    func configureCollectPayment(cell: LeftImageTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.configure(image: .moneyIcon, text: Localization.collectPayment)

        updateEnabledState(in: cell)
    }

    func updateEnabledState(in cell: UITableViewCell, shouldBeEnabled: Bool = true) {
        let alpha = shouldBeEnabled ? 1 : 0.3
        cell.imageView?.alpha = alpha
        cell.textLabel?.alpha = alpha
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
        ServiceLocator.analytics.track(.paymentsMenuOrderCardReaderTapped)
        WebviewHelper.launch(configurationLoader.configuration.purchaseCardReaderUrl(), with: self)
    }

    func manageCardReaderWasPressed() {
        ServiceLocator.analytics.track(.paymentsMenuManageCardReadersTapped)
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: CardReaderSettingsPresentingViewController.self) else {
            fatalError("Cannot instantiate `CardReaderSettingsPresentingViewController` from Dashboard storyboard")
        }

        let viewModelsAndViews = CardReaderSettingsViewModelsOrderedList(configuration: configurationLoader.configuration)
        viewController.configure(viewModelsAndViews: viewModelsAndViews)
        show(viewController, sender: self)
    }

    func cardReaderManualsWasPressed() {
        ServiceLocator.analytics.track(.paymentsMenuCardReadersManualsTapped)
        let view = UIHostingController(rootView: CardReaderManualsView())
        navigationController?.pushViewController(view, animated: true)
    }

    func managePaymentGatewaysWasPressed() {
        ServiceLocator.analytics.track(.paymentsMenuPaymentProviderTapped)
        onPluginSelectionCleared?()

        if featureFlagService.isFeatureFlagEnabled(.paymentsHubMenuSection) {
            navigateToInPersonPaymentsSelectPluginView()
        }
    }

    func navigateToInPersonPaymentsSelectPluginView() {
        let view = InPersonPaymentsSelectPluginView(selectedPlugin: nil) { [weak self] plugin in
            self?.cardPresentPaymentsOnboardingUseCase.clearPluginSelection()
            self?.cardPresentPaymentsOnboardingUseCase.selectPlugin(plugin)
            self?.navigationController?.popViewController(animated: true)
        }

        navigationController?.pushViewController(InPersonPaymentsSelectPluginViewController(rootView: view), animated: true)
    }

    func collectPaymentWasPressed() {
        ServiceLocator.analytics.track(.paymentsMenuCollectPaymentTapped)

        guard let siteID = stores.sessionManager.defaultStoreID,
              let navigationController = navigationController else {
            return
        }

        SimplePaymentsAmountFlowOpener.openSimplePaymentsAmountFlow(from: navigationController, siteID: siteID)
    }
}

// MARK: - UITableViewDataSource
extension InPersonPaymentsMenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate
//
extension InPersonPaymentsMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

        static let inPersonPaymentsSetupNotFinishedNotice = NSLocalizedString(
            "In-Person Payments Setup in incomplete.",
            comment: "Shows a notice pointing out that the user didn't finish the In-Person Payments setup, so some functionalities are disabled."
        )

        static let inPersonPaymentsSetupNotFinishedNoticeButtonTitle = NSLocalizedString(
            "Continue Setup",
            comment: "Call to Action to finish the setup of In-Person Payments in the Menu"
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

private extension InPersonPaymentsMenuViewController {
    enum Layout {
        static let tableViewFooterHeight = CGFloat(200)
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
