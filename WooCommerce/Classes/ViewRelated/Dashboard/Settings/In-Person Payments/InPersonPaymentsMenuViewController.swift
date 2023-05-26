import UIKit
import SwiftUI
import Yosemite
import Experiments
import Combine

final class InPersonPaymentsMenuViewController: UIViewController {
    private let stores: StoresManager
    private var pluginState: CardPresentPaymentsPluginState?
    private var sections = [Section]()
    private let featureFlagService: FeatureFlagService
    private let cardPresentPaymentsOnboardingUseCase: CardPresentPaymentsOnboardingUseCase
    private var cancellables: Set<AnyCancellable> = []
    private lazy var learnMoreViewModel: LearnMoreViewModel = {
        LearnMoreViewModel(url: WooConstants.URLs.wcPayCashOnDeliveryLearnMore.asURL(),
                           linkText: Localization.toggleEnableCashOnDeliveryLearnMoreLink,
                           formatText: Localization.toggleEnableCashOnDeliveryLearnMoreFormat,
                           tappedAnalyticEvent: WooAnalyticsEvent.InPersonPayments.cardPresentOnboardingLearnMoreTapped(
                            reason: "reason",
                            countryCode: viewModel.cardPresentPaymentsConfiguration.countryCode))
    }()

    private lazy var inPersonPaymentsLearnMoreViewModel = LearnMoreViewModel.inPersonPayments(source: .paymentsMenu)

    private let viewModel: InPersonPaymentsMenuViewModel

    private let cashOnDeliveryToggleRowViewModel: InPersonPaymentsCashOnDeliveryToggleRowViewModel

    private var enableManageCardReaderCell: Bool {
        cardPresentPaymentsOnboardingUseCase.state.isCompleted
    }

    private var enableSetUpTapToPayOnIPhoneCell: Bool {
        cardPresentPaymentsOnboardingUseCase.state.isCompleted
    }

    private let setUpFlowOnlyEnabledAfterOnboardingComplete: Bool

    /// Main TableView
    ///
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        return tableView
    }()

    private lazy var permanentNoticePresenter: PermanentNoticePresenter = {
        PermanentNoticePresenter()
    }()

    private var activityIndicator: UIActivityIndicatorView?

    private var inPersonPaymentsLearnMoreButton: UIButton {
        let button = UIButton()
        button.addTarget(self, action: #selector(learnMoreAboutInPersonPaymentsButtonWasTapped), for: .touchUpInside)
        button.setAttributedTitle(inPersonPaymentsLearnMoreViewModel.learnMoreAttributedString, for: .normal)
        button.naturalContentHorizontalAlignment = .leading
        button.configuration = UIButton.Configuration.plain()

        return button
    }

    private let viewDidLoadAction: ((InPersonPaymentsMenuViewController) -> Void)?

    /// In Person Payments Menu View Controller contains the menu for managing and accepting payments with a card reader or Tap to Pay
    /// - Parameters:
    ///   - stores: stores manager – for handling actions
    ///   - featureFlagService: feature flags which affect the view controller's behaviour will be loaded from here
    ///   - viewDidLoadAction: Provided as a one-time callback on viewDidLoad, originally to handle universal link navigation correctly.
    init(stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker,
         viewDidLoadAction: ((InPersonPaymentsMenuViewController) -> Void)? = nil) {
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.viewModel = InPersonPaymentsMenuViewModel(dependencies: .init(tapToPayBadgePromotionChecker: tapToPayBadgePromotionChecker))
        self.cardPresentPaymentsOnboardingUseCase = CardPresentPaymentsOnboardingUseCase()
        self.cashOnDeliveryToggleRowViewModel = InPersonPaymentsCashOnDeliveryToggleRowViewModel()
        self.setUpFlowOnlyEnabledAfterOnboardingComplete = !featureFlagService.isFeatureFlagEnabled(.tapToPayOnIPhoneMilestone2)
        self.viewDidLoadAction = viewDidLoadAction

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad()

        registerUserActivity()

        setupNavigationBar()
        configureSections()
        configureTableView()
        registerTableViewCells()
        configureTableReload()
        runCardPresentPaymentsOnboardingIfPossible()
        configureWebViewPresentation()
        viewDidLoadAction?(self)
    }
}

// MARK: - Card Present Payments Readiness

private extension InPersonPaymentsMenuViewController {
    func runCardPresentPaymentsOnboardingIfPossible() {
        guard viewModel.isEligibleForCardPresentPayments else {
            return
        }

        cardPresentPaymentsOnboardingUseCase.refreshIfNecessary()

        cardPresentPaymentsOnboardingUseCase.$state
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] state in
                self?.refreshAfterNewOnboardingState(state)
        }).store(in: &cancellables)
    }

    func refreshAfterNewOnboardingState(_ state: CardPresentPaymentOnboardingState) {
        pluginState = nil

        guard state != .loading else {
            self.activityIndicator?.startAnimating()
            return
        }

        switch state {
        case let .completed(newPluginState):
            pluginState = newPluginState
            dismissCardPresentPaymentsOnboardingNoticeIfPresent()
            dismissOnboardingIfPresented()
        case let .selectPlugin(pluginSelectionWasCleared):
            // If it was cleared it means that we triggered it manually (e.g by tapping in this view on the plugin selection row)
            // No need to show the onboarding notice
            if !pluginSelectionWasCleared {
                showCardPresentPaymentsOnboardingNotice()
            }
        default:
            showCardPresentPaymentsOnboardingNotice()
        }

        updateViewModelSelectedPlugin(state: state)

        activityIndicator?.stopAnimating()
        configureSections()
        tableView.reloadData()
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

    func updateViewModelSelectedPlugin(state: CardPresentPaymentOnboardingState) {
        switch state {
        case let .completed(pluginState):
            cashOnDeliveryToggleRowViewModel.selectedPlugin = pluginState.preferred
        case let .codPaymentGatewayNotSetUp(plugin):
            cashOnDeliveryToggleRowViewModel.selectedPlugin = plugin
        default:
            cashOnDeliveryToggleRowViewModel.selectedPlugin = nil
        }
    }

    func showOnboarding() {
        // Instead of using `CardPresentPaymentsOnboardingPresenter` we create the view directly because we already have the onboarding state in the use case.
        // That way we avoid triggering the onboarding check again that comes with the presenter.
        let onboardingViewModel = InPersonPaymentsViewModel(useCase: cardPresentPaymentsOnboardingUseCase)

        let onboardingViewController = InPersonPaymentsViewController(viewModel: onboardingViewModel,
                                                                      onWillDisappear: nil)
        show(onboardingViewController, sender: self)
    }

    func dismissOnboardingIfPresented() {
        if navigationController?.visibleViewController is InPersonPaymentsViewController {
            navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - View configuration
//
private extension InPersonPaymentsMenuViewController {
    func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationItem.title = InPersonPaymentsView.Localization.title
    }


    /// Sets up the sections for the table view. As the sections/rows are dynamically built and change over time, this will be called repeatedly
    /// - Parameters:
    ///   - isEligibleForTapToPayOnIPhone: Used to determine whether the `Set up Tap to Pay on iPhone` row is shown.
    ///     If not set, this function will fetch the value from the viewModel, however, when called in response to a @Published update,
    ///     the viewModel value may not yet be up to date.
    ///   - shouldShowTapToPayOnIPhoneFeedback: Used to determine whether the `Share Tap to Pay on iPhone Feedback` row is shown.
    ///     If not set, this function will fetch the value from the viewModel, however, when called in response to a @Published update,
    ///     the viewModel value may not yet be up to date.
    func configureSections(isEligibleForTapToPayOnIPhone: Bool? = nil,
                           shouldShowTapToPayOnIPhoneFeedback: Bool? = nil) {
        var composingSections: [Section?] = [actionsSection]

        if isEligibleForTapToPayOnIPhone ?? viewModel.isEligibleForTapToPayOnIPhone {
            composingSections.append(tapToPayOnIPhoneSection(
                shouldShowFeedbackRow: shouldShowTapToPayOnIPhoneFeedback ?? viewModel.shouldShowTapToPayOnIPhoneFeedbackRow))
        }

        if viewModel.isEligibleForCardPresentPayments {
            composingSections.append(contentsOf: [cardReadersSection, paymentOptionsSection])
        }

        sections = composingSections.compactMap { $0 }
    }

    var actionsSection: Section? {
        return Section(header: Localization.paymentActionsSectionTitle, rows: [.collectPayment, .toggleEnableCashOnDelivery])
    }

    func tapToPayOnIPhoneSection(shouldShowFeedbackRow: Bool) -> Section? {
        guard featureFlagService.isFeatureFlagEnabled(.tapToPayOnIPhone) else {
            return nil
        }
        var rows: [Row] = [.setUpTapToPayOnIPhone]

        if shouldShowFeedbackRow {
            rows.append(.tapToPayOnIPhoneFeedback)
        }

        return Section(header: nil, rows: rows)
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

        setupBottomActivityIndicator()
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
        case let cell as LeftImageTitleSubtitleToggleTableViewCell where row == .toggleEnableCashOnDelivery:
            configureToggleEnableCashOnDelivery(cell: cell)
        case let cell as BadgedLeftImageTableViewCell where row == .setUpTapToPayOnIPhone:
            configureSetUpTapToPayOnIPhone(cell: cell)
        case let cell as LeftImageTableViewCell where row == .tapToPayOnIPhoneFeedback:
            configureTapToPayOnIPhoneFeedback(cell: cell)
        default:
            fatalError()
        }
    }

    func configureOrderCardReader(cell: LeftImageTableViewCell) {
        prepareForReuse(cell)
        cell.accessibilityIdentifier = "order-card-reader"
        cell.configure(image: .shoppingCartIcon, text: Localization.orderCardReader.localizedCapitalized)
    }

    func configureManageCardReader(cell: LeftImageTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = enableManageCardReaderCell ? .disclosureIndicator : .none
        cell.selectionStyle = enableManageCardReaderCell ? .default : .none
        cell.accessibilityIdentifier = "manage-card-reader"
        cell.configure(image: .creditCardIcon, text: Localization.manageCardReader.localizedCapitalized)

        updateEnabledState(in: cell, shouldBeEnabled: enableManageCardReaderCell)
    }

    func configureManagePaymentGateways(cell: LeftImageTitleSubtitleTableViewCell) {
        prepareForReuse(cell)
        cell.accessibilityIdentifier = "manage-payment-gateways"
        cell.configure(image: .rectangleOnRectangleAngled,
                       text: Localization.managePaymentGateways.localizedCapitalized,
                       subtitle: pluginState?.preferred.pluginName ?? "")
    }

    func configureCardReaderManuals(cell: LeftImageTableViewCell) {
        prepareForReuse(cell)
        cell.accessibilityIdentifier = "card-reader-manuals"
        cell.configure(image: .cardReaderManualIcon, text: Localization.cardReaderManuals.localizedCapitalized)
    }

    func configureCollectPayment(cell: LeftImageTableViewCell) {
        prepareForReuse(cell)
        cell.accessibilityIdentifier = "collect-payment"
        cell.configure(image: .moneyIcon, text: Localization.collectPayment.localizedCapitalized)
    }

    func configureToggleEnableCashOnDelivery(cell: LeftImageTitleSubtitleToggleTableViewCell) {
        prepareForReuse(cell)
        cell.leftImageView?.tintColor = .text
        cell.accessoryType = .none
        cell.selectionStyle = .none
        cell.accessibilityIdentifier = "pay-in-person"
        cell.configure(image: .creditCardIcon,
                       text: Localization.toggleEnableCashOnDelivery,
                       subtitle: learnMoreViewModel.learnMoreAttributedString,
                       switchState: cashOnDeliveryToggleRowViewModel.cashOnDeliveryEnabledState,
                       switchAction: cashOnDeliveryToggleRowViewModel.updateCashOnDeliverySetting(enabled:),
                       subtitleTapAction: { [weak self] in
            guard let self = self else { return }
            self.cashOnDeliveryToggleRowViewModel.learnMoreTapped(from: self)
        })
    }

    func configureSetUpTapToPayOnIPhone(cell: BadgedLeftImageTableViewCell) {
        prepareForReuse(cell)
        cell.accessibilityIdentifier = "set-up-tap-to-pay"
        cell.configure(image: .tapToPayOnIPhoneIcon,
                       text: Localization.tapToPayOnIPhone,
                       showBadge: viewModel.shouldBadgeTapToPayOnIPhone)

        if setUpFlowOnlyEnabledAfterOnboardingComplete {
            cell.accessoryType = enableSetUpTapToPayOnIPhoneCell ? .disclosureIndicator : .none
            cell.selectionStyle = enableSetUpTapToPayOnIPhoneCell ? .default : .none
            updateEnabledState(in: cell, shouldBeEnabled: enableSetUpTapToPayOnIPhoneCell)
        }
    }

    func configureTapToPayOnIPhoneFeedback(cell: LeftImageTableViewCell) {
        prepareForReuse(cell)
        cell.accessibilityIdentifier = "tap-to-pay-feedback"
        cell.configure(image: UIImage(color: .clear, havingSize: CGSize(width: 24, height: 24)),
                       text: Localization.tapToPayOnIPhoneFeedback)
        cell.textLabel?.textColor = .primary
        cell.accessoryType = .none
    }

    private func prepareForReuse(_ cell: UITableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.textColor = .text
        cell.accessibilityIdentifier = ""
        updateEnabledState(in: cell)
    }

    func updateEnabledState(in cell: UITableViewCell, shouldBeEnabled: Bool = true) {
        let alpha = shouldBeEnabled ? 1 : 0.3
        cell.imageView?.alpha = alpha
        cell.textLabel?.alpha = alpha
    }

    func configureTableReload() {
        cashOnDeliveryToggleRowViewModel.$cashOnDeliveryEnabledState.sink { [weak self] _ in
            self?.configureSections()
            self?.tableView.reloadData()
        }.store(in: &cancellables)

        viewModel.$isEligibleForTapToPayOnIPhone.sink { [weak self] eligibleForTapToPay in
            self?.configureSections(isEligibleForTapToPayOnIPhone: eligibleForTapToPay)
            self?.tableView.reloadData()
        }.store(in: &cancellables)

        viewModel.$shouldShowTapToPayOnIPhoneFeedbackRow.sink { [weak self] shouldShowFeedbackRow in
            self?.configureSections(shouldShowTapToPayOnIPhoneFeedback: shouldShowFeedbackRow)
            self?.tableView.reloadData()
        }.store(in: &cancellables)

        viewModel.$shouldBadgeTapToPayOnIPhone.sink { [weak self] _ in
            self?.configureSections()
            // ensures that the cell will be configured with the correct value for the badge
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }.store(in: &cancellables)
    }

    private func configureWebViewPresentation() {
        viewModel.$showWebView.sink { viewModel in
            guard let viewModel = viewModel else {
                return
            }
            let connectionController = AuthenticatedWebViewController(viewModel: viewModel)
            self.navigationController?.show(connectionController, sender: nil)
        }.store(in: &cancellables)
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
        viewModel.orderCardReaderPressed()
    }

    func manageCardReaderWasPressed() {
        guard enableManageCardReaderCell else {
            return
        }
        guard let siteID = stores.sessionManager.defaultStoreID else {
            DDLogError("⛔️ Could not open card reader settings – StoreID could not be determined")
            return
        }

        ServiceLocator.analytics.track(.paymentsMenuManageCardReadersTapped)

        let viewModelsAndViews = CardReaderSettingsViewModelsOrderedList(configuration: viewModel.cardPresentPaymentsConfiguration,
                                                                         siteID: siteID)
        let viewController = PaymentSettingsFlowPresentingViewController(viewModelsAndViews: viewModelsAndViews)
        show(viewController, sender: self)
    }

    func cardReaderManualsWasPressed() {
        ServiceLocator.analytics.track(.paymentsMenuCardReadersManualsTapped)
        let view = UIHostingController(rootView: CardReaderManualsView())
        navigationController?.pushViewController(view, animated: true)
    }

    func managePaymentGatewaysWasPressed() {
        ServiceLocator.analytics.track(.paymentsMenuPaymentProviderTapped)
        navigateToInPersonPaymentsSelectPluginView()
    }

    func setUpTapToPayOnIPhoneWasPressed() {
        ServiceLocator.analytics.track(.setUpTapToPayOnIPhoneTapped)

        presentSetUpTapToPayOnIPhoneViewController()
    }

    func presentSetUpTapToPayOnIPhoneViewController() {
        if setUpFlowOnlyEnabledAfterOnboardingComplete {
            guard enableSetUpTapToPayOnIPhoneCell else {
                return
            }

            presentSetUpTapToPayOnIPhoneWithoutOnboarding()
        } else {
            presentSetUpTapToPayOnIPhoneWithOnboarding()
        }
    }

    private func presentSetUpTapToPayOnIPhoneWithoutOnboarding() {
        guard let siteID = stores.sessionManager.defaultStoreID,
              let _ = pluginState?.preferred else {
            return
        }

        let viewModelsAndViews = SetUpTapToPayViewModelsOrderedList(siteID: siteID,
                                                                    configuration: viewModel.cardPresentPaymentsConfiguration,
                                                                    onboardingUseCase: cardPresentPaymentsOnboardingUseCase)
        let setUpTapToPayViewController = PaymentSettingsFlowPresentingViewController(viewModelsAndViews: viewModelsAndViews)
        let controller = WooNavigationController(rootViewController: setUpTapToPayViewController)
        controller.navigationBar.isHidden = true

        navigationController?.present(controller, animated: true)
    }

    private func presentSetUpTapToPayOnIPhoneWithOnboarding() {
        guard let siteID = stores.sessionManager.defaultStoreID else {
            return
        }

        let viewModelsAndViews = SetUpTapToPayViewModelsOrderedList(siteID: siteID,
                                                                    configuration: viewModel.cardPresentPaymentsConfiguration,
                                                                    onboardingUseCase: cardPresentPaymentsOnboardingUseCase)
        let setUpTapToPayViewController = PaymentSettingsFlowPresentingViewController(viewModelsAndViews: viewModelsAndViews)
        let controller = WooNavigationController(rootViewController: setUpTapToPayViewController)
        controller.navigationBar.isHidden = true

        navigationController?.present(controller, animated: true)
    }

    func tapToPayOnIPhoneFeedbackWasPressed() {
        let surveyNavigation = SurveyCoordinatingController(survey: .tapToPayFirstPayment)
        navigationController?.present(surveyNavigation, animated: true)
    }

    func navigateToInPersonPaymentsSelectPluginView() {
        let view = InPersonPaymentsSelectPluginView(selectedPlugin: nil) { [weak self] plugin in
            self?.cardPresentPaymentsOnboardingUseCase.clearPluginSelection()
            self?.cardPresentPaymentsOnboardingUseCase.selectPlugin(plugin)
            self?.navigationController?.popViewController(animated: true)
        }

        navigationController?.pushViewController(InPersonPaymentsSelectPluginViewController(rootView: view), animated: true)
    }

    func openSimplePaymentsAmountFlow() {
        ServiceLocator.analytics.track(.paymentsMenuCollectPaymentTapped)

        guard let siteID = stores.sessionManager.defaultStoreID,
              let navigationController = navigationController else {
            return
        }

        SimplePaymentsAmountFlowOpener.openSimplePaymentsAmountFlow(from: navigationController, siteID: siteID)
    }

    @objc func learnMoreAboutInPersonPaymentsButtonWasTapped() {
        inPersonPaymentsLearnMoreViewModel.learnMoreTapped()
        WebviewHelper.launch(inPersonPaymentsLearnMoreViewModel.url, with: self)
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

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == sections.firstIndex(where: { $0 == cardReadersSection }) else {
            return nil
        }

        return inPersonPaymentsLearnMoreButton
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
            openSimplePaymentsAmountFlow()
        case .toggleEnableCashOnDelivery:
            break
        case .setUpTapToPayOnIPhone:
            setUpTapToPayOnIPhoneWasPressed()
        case .tapToPayOnIPhoneFeedback:
            tapToPayOnIPhoneFeedbackWasPressed()
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch rowAtIndexPath(indexPath) {
        case .toggleEnableCashOnDelivery:
            return nil
        default:
            return indexPath
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

        static let toggleEnableCashOnDelivery = NSLocalizedString(
            "Pay in Person",
            comment: "Title for a switch on the In-Person Payments menu to enable Cash on Delivery"
        )

        static let toggleEnableCashOnDeliveryLearnMoreFormat = NSLocalizedString(
            "The Pay in Person checkout option lets you accept payments for website orders, on collection or delivery. %1$@",
            comment: "A label prompting users to learn more about adding Pay in Person to their checkout. " +
            "%1$@ is a placeholder that always replaced with \"Learn more\" string, " +
            "which should be translated separately and considered part of this sentence.")

        static let toggleEnableCashOnDeliveryLearnMoreLink = NSLocalizedString(
            "Learn more",
            comment: "The \"Learn more\" string replaces the placeholder in a label prompting users to learn " +
            "more about adding Pay in Person to their checkout. ")

        static let cardReaderManuals = NSLocalizedString(
            "Card Reader Manuals",
            comment: "Navigates to Card Reader Manuals screen"
        )

        static let collectPayment = NSLocalizedString(
            "Collect Payment",
            comment: "Navigates to Collect a payment via the Simple Payment screen"
        )

        static let tapToPayOnIPhone = NSLocalizedString(
            "Set up Tap to Pay on iPhone",
            comment: "Navigates to the Tap to Pay on iPhone set up flow. The full name is expected by Apple. " +
            "The destination screen also allows for a test payment, after set up.")

        static let tapToPayOnIPhoneFeedback = NSLocalizedString(
            "Share Tap to Pay on iPhone Feedback",
            comment: "Navigates to a screen to share feedback about Tap to Pay on iPhone.")

        static let inPersonPaymentsSetupNotFinishedNotice = NSLocalizedString(
            "In-Person Payments setup is incomplete.",
            comment: "Shows a notice pointing out that the user didn't finish the In-Person Payments setup, so some functionalities are disabled."
        )

        static let inPersonPaymentsSetupNotFinishedNoticeButtonTitle = NSLocalizedString(
            "Continue setup",
            comment: "Call to Action to finish the setup of In-Person Payments in the Menu"
        )

        static let learnMoreLink = NSLocalizedString(
            "cardPresent.modalScanningForReader.learnMore.link",
            value: "Learn more",
            comment: """
                     A label prompting users to learn more about In-Person Payments.
                     This is the link to the website, and forms part of a longer sentence which it should be considered a part of.
                     """
        )
    }
}

private struct Section: Equatable {
    let header: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case orderCardReader
    case manageCardReader
    case cardReaderManuals
    case managePaymentGateways
    case collectPayment
    case toggleEnableCashOnDelivery
    case setUpTapToPayOnIPhone
    case tapToPayOnIPhoneFeedback

    var type: UITableViewCell.Type {
        switch self {
        case .managePaymentGateways:
            return LeftImageTitleSubtitleTableViewCell.self
        case .toggleEnableCashOnDelivery:
            return LeftImageTitleSubtitleToggleTableViewCell.self
        case .setUpTapToPayOnIPhone:
            return BadgedLeftImageTableViewCell.self
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
    let tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker

    func makeUIViewController(context: Context) -> some UIViewController {
        InPersonPaymentsMenuViewController(tapToPayBadgePromotionChecker: tapToPayBadgePromotionChecker)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}
