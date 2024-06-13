import Foundation
@testable import WooCommerce
import Yosemite

class MockBuiltInCardReaderConnectionControllerFactory: BuiltInCardReaderConnectionControllerBuilding {
    typealias AlertProvider = BuiltInReaderConnectionAlertsProvider
    typealias AlertPresenter = SilenceablePassthroughCardPresentPaymentAlertsPresenter<CardPresentPaymentAlertsPresenter>

    var spyCreateConnectionControllerSiteID: Int64? = nil
    var spyCreateConnectionControllerAlertsPresenter: AlertPresenter? = nil
    var spyCreateConnectionControllerConfiguration: CardPresentPaymentsConfiguration? = nil
    var spyCreateConnectionControllerAnalyticsTracker: CardReaderConnectionAnalyticsTracker? = nil
    var spyCreateConnectionControllerAllowTermsOfServiceAcceptance: Bool? = nil

    var onSearchAndConnectCalled: (() -> Void)? = nil

    var mockConnectionController: MockBuiltInCardReaderConnectionController? = nil

    func createConnectionController(forSiteID siteID: Int64,
                                    alertPresenter: AlertPresenter,
                                    configuration: CardPresentPaymentsConfiguration,
                                    analyticsTracker: CardReaderConnectionAnalyticsTracker,
                                    allowTermsOfServiceAcceptance: Bool) -> BuiltInCardReaderConnectionControlling {
        spyCreateConnectionControllerSiteID = siteID
        spyCreateConnectionControllerAlertsPresenter = alertPresenter
        spyCreateConnectionControllerConfiguration = configuration
        spyCreateConnectionControllerAnalyticsTracker = analyticsTracker
        spyCreateConnectionControllerAllowTermsOfServiceAcceptance = allowTermsOfServiceAcceptance

        let mockConnectionController = MockBuiltInCardReaderConnectionController(
            onSearchAndConnectCalled: onSearchAndConnectCalled)
        self.mockConnectionController = mockConnectionController
        connectionControllerCreated()
        return mockConnectionController
    }

    var connectionControllerCreated: () -> Void = {}
}

class MockBuiltInCardReaderConnectionController: BuiltInCardReaderConnectionControlling {
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
