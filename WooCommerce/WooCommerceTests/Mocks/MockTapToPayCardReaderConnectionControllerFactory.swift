import Foundation
@testable import WooCommerce
import Yosemite

class MockTapToPayCardReaderConnectionControllerFactory: TapToPayCardReaderConnectionControllerBuilding {
    typealias AlertProvider = TapToPayReaderConnectionAlertsProvider
    typealias AlertPresenter = SilenceablePassthroughCardPresentPaymentAlertsPresenter<CardPresentPaymentAlertsPresenter>

    var spyCreateConnectionControllerSiteID: Int64? = nil
    var spyCreateConnectionControllerAlertsPresenter: AlertPresenter? = nil
    var spyCreateConnectionControllerConfiguration: CardPresentPaymentsConfiguration? = nil
    var spyCreateConnectionControllerAnalyticsTracker: CardReaderConnectionAnalyticsTracker? = nil
    var spyCreateConnectionControllerAllowTermsOfServiceAcceptance: Bool? = nil

    var onSearchAndConnectCalled: (() -> Void)? = nil

    var mockConnectionController: MockTapToPayCardReaderConnectionController? = nil

    func createConnectionController(forSiteID siteID: Int64,
                                    alertPresenter: AlertPresenter,
                                    configuration: CardPresentPaymentsConfiguration,
                                    analyticsTracker: CardReaderConnectionAnalyticsTracker,
                                    allowTermsOfServiceAcceptance: Bool) -> TapToPayCardReaderConnectionControlling {
        spyCreateConnectionControllerSiteID = siteID
        spyCreateConnectionControllerAlertsPresenter = alertPresenter
        spyCreateConnectionControllerConfiguration = configuration
        spyCreateConnectionControllerAnalyticsTracker = analyticsTracker
        spyCreateConnectionControllerAllowTermsOfServiceAcceptance = allowTermsOfServiceAcceptance

        let mockConnectionController = MockTapToPayCardReaderConnectionController(
            onSearchAndConnectCalled: onSearchAndConnectCalled)
        self.mockConnectionController = mockConnectionController
        connectionControllerCreated()
        return mockConnectionController
    }

    var connectionControllerCreated: () -> Void = {}
}

class MockTapToPayCardReaderConnectionController: TapToPayCardReaderConnectionControlling {
    let onSearchAndConnectCalled: (() -> Void)?

    init(onSearchAndConnectCalled: (() -> Void)?) {
        self.onSearchAndConnectCalled = onSearchAndConnectCalled
    }

    var didCallSearchAndConnect = false
    var spySearchAndConnectCompletion: ((Result<WooCommerce.CardReaderConnectionResult, Error>) -> Void)? = nil
    func searchAndConnect(onCompletion: @escaping (Result<WooCommerce.CardReaderConnectionResult, Error>) -> Void) {
        didCallSearchAndConnect = true
        spySearchAndConnectCompletion = onCompletion
        onSearchAndConnectCalled?()
    }
}
