import XCTest
import Fakes
import Storage
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
final class CardPresentPaymentPreflightControllerTests: XCTestCase {
    private let sampleSiteID: Int64 = 1234

    private var storageManager: MockStorageManager!
    private var stores: MockCardPresentPaymentsStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var onboardingPresenter: DelayedCardPresentPaymentsOnboardingPresenter!
    private var alertsPresenter: MockCardPresentPaymentAlertsPresenter!
    private var locationService: MockLocationService!
    private var sut: CardPresentPaymentPreflightController<
        TapToPayReaderConnectionAlertsProvider,
        MockCardReaderSettingsAlerts,
        MockCardPresentPaymentAlertsPresenter
    >!

    override func setUp() {
        super.setUp()

        storageManager = MockStorageManager()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        ServiceLocator.setAnalytics(analytics)

        stores = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance,
            storageManager: storageManager
        )

        let paymentGatewayAccount = PaymentGatewayAccount.fake().copy(
            siteID: sampleSiteID,
            gatewayID: "woocommerce-payments",
            isCardPresentEligible: true
        )
        stores.dispatch(CardPresentPaymentAction.use(paymentGatewayAccount: paymentGatewayAccount))

        let storagePaymentGateway = storageManager.viewStorage.insertNewObject(ofType: StoragePaymentGatewayAccount.self)
        storagePaymentGateway.update(with: paymentGatewayAccount)

        onboardingPresenter = DelayedCardPresentPaymentsOnboardingPresenter()
        alertsPresenter = MockCardPresentPaymentAlertsPresenter()
        locationService = MockLocationService(status: .authorized)

        let analyticsTracker = CardReaderConnectionAnalyticsTracker(
            configuration: Mocks.configuration,
            siteID: sampleSiteID,
            connectionType: .userInitiated,
            stores: stores,
            analytics: analytics
        )

        let bluetoothConnectionController = CardReaderConnectionController(
            forSiteID: sampleSiteID,
            storageManager: storageManager,
            stores: stores,
            knownReaderProvider: MockKnownReaderProvider(knownReader: nil),
            alertsPresenter: alertsPresenter,
            alertsProvider: MockCardReaderSettingsAlerts(mode: .connectFoundReader),
            configuration: Mocks.configuration,
            analyticsTracker: analyticsTracker,
            locationService: locationService
        )

        let tapToPayConnectionController = TapToPayCardReaderConnectionController(
            forSiteID: sampleSiteID,
            storageManager: storageManager,
            stores: stores,
            alertsPresenter: alertsPresenter,
            alertsProvider: TapToPayReaderConnectionAlertsProvider(),
            configuration: Mocks.configuration,
            analyticsTracker: analyticsTracker,
            locationService: locationService
        )

        sut = CardPresentPaymentPreflightController(
            siteID: sampleSiteID,
            configuration: Mocks.configuration,
            rootViewController: NullViewControllerPresenting(),
            alertsPresenter: alertsPresenter,
            onboardingPresenter: onboardingPresenter,
            tapToPayAlertProvider: TapToPayReaderConnectionAlertsProvider(),
            externalReaderConnectionController: bluetoothConnectionController,
            tapToPayConnectionController: tapToPayConnectionController,
            tapToPayReconnectionController: TapToPayReconnectionController(
                stores: stores,
                connectionControllerFactory: TapToPayCardReaderConnectionControllerFactory(
                    alertProvider: TapToPayReaderConnectionAlertsProvider()
                ),
                onboardingCache: CardPresentPaymentOnboardingStateCache()
            ),
            analyticsTracker: analyticsTracker,
            stores: stores,
            analytics: analytics
        )
    }

    func test_start_when_onboarding_completion_runs_after_cancellation_then_does_not_start_reader_discovery() async {
        let didStartDiscovery = expectation(description: "discovery started")
        didStartDiscovery.isInverted = true
        stores.onStartCardReaderDiscovery = {
            didStartDiscovery.fulfill()
        }

        await sut.start(discoveryMethod: .bluetoothScan)
        XCTAssertTrue(onboardingPresenter.spyShowOnboardingWasCalled)

        sut.cancelConnectionAttempt()
        onboardingPresenter.completeOnboarding()

        await fulfillment(of: [didStartDiscovery], timeout: 0.2)
    }

    func test_start_when_onboarding_completion_runs_without_cancellation_then_starts_reader_discovery() async {
        let didStartDiscovery = expectation(description: "discovery started")
        stores.onStartCardReaderDiscovery = {
            didStartDiscovery.fulfill()
        }

        await sut.start(discoveryMethod: .bluetoothScan)
        XCTAssertTrue(onboardingPresenter.spyShowOnboardingWasCalled)

        onboardingPresenter.completeOnboarding()

        await fulfillment(of: [didStartDiscovery], timeout: 1.0)
    }
}

private final class DelayedCardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting {
    private(set) var spyShowOnboardingWasCalled = false
    private var completion: (() -> Void)?

    func showOnboardingIfRequired(from viewController: ViewControllerPresenting,
                                  readyToCollectPayment completion: @escaping () -> Void) {
        spyShowOnboardingWasCalled = true
        self.completion = completion
    }

    func showOnboardingIfRequired(from: UIViewController) async {
        spyShowOnboardingWasCalled = true
    }

    func refresh() {
    }

    func completeOnboarding() {
        completion?()
        completion = nil
    }
}

private extension CardPresentPaymentPreflightControllerTests {
    enum Mocks {
        static let configuration = CardPresentPaymentsConfiguration(country: .US)
    }
}
