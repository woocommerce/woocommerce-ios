import Combine
import Foundation
import struct Yosemite.Order
import struct Yosemite.CardPresentPaymentsConfiguration

import UIKit // TODO: remove after update to `ViewControllerPresenting` when #12864 is done

final class CardPresentPaymentService: CardPresentPaymentFacade {
    let paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never>

    var connectedReaderPublisher: AnyPublisher<CardPresentPaymentCardReader?, Never> {
        connectedReaderSubject.eraseToAnyPublisher()
    }

    // I don't actually think we need this, but just in case the service needs to send its own events
    private let paymentEventSubject = PassthroughSubject<CardPresentPaymentEvent, Never>()
    private let connectedReaderSubject = CurrentValueSubject<CardPresentPaymentCardReader?, Never>(nil)

    private let onboardingAdaptor: CardPresentPaymentsOnboardingPresenterAdaptor

    private let paymentAlertsPresenterAdaptor: CardPresentPaymentAlertsPresenting
    private let connectionControllerManager: CardPresentPaymentsConnectionControllerManager

    private let siteID: Int64

    private var cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration {
        CardPresentConfigurationLoader().configuration
    }

    init(siteID: Int64) {
        self.siteID = siteID
        let onboardingAdaptor = CardPresentPaymentsOnboardingPresenterAdaptor()
        self.onboardingAdaptor = onboardingAdaptor
        let paymentAlertsPresenterAdaptor = CardPresentPaymentsAlertPresenterAdaptor()
        self.paymentAlertsPresenterAdaptor = paymentAlertsPresenterAdaptor
        connectionControllerManager = CardPresentPaymentsConnectionControllerManager(
            siteID: siteID,
            configuration: CardPresentConfigurationLoader().configuration,
            alertsPresenter: paymentAlertsPresenterAdaptor)

        paymentEventPublisher = onboardingAdaptor.onboardingScreenViewModelPublisher
            .map { onboardingEvent -> CardPresentPaymentEvent in
                switch onboardingEvent {
                case .showOnboarding(let onboardingViewModel):
                    return .showOnboarding(onboardingViewModel)
                case .onboardingComplete:
                    return .idle
                }
            }
            .merge(with: paymentAlertsPresenterAdaptor.paymentAlertPublisher)
            .merge(with: paymentEventSubject)
            .eraseToAnyPublisher()
    }

    @MainActor
    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
        // What happens if this gets called while there's another connection ongoing?
        let preflightController = createPreflightController()

        await preflightController.start(discoveryMethod: connectionMethod.discoveryMethod)

        // TODO: replace it with reader connection
        let mockReader = CardPresentPaymentCardReader(name: "Test Reader", batteryLevel: 0.5)
        connectedReaderSubject.send(mockReader)
        return .connected(mockReader)
    }

    func disconnectReader() {
    }

    func collectPayment(for order: Order, using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentResult {
        // TODO: replace it with payment collection
        .cancellation
    }

    func cancelPayment() {
    }
}

private extension CardPresentPaymentService {
    func createPreflightController() -> CardPresentPaymentPreflightController {
        CardPresentPaymentPreflightController(
            siteID: siteID,
            configuration: cardPresentPaymentsConfiguration,
            rootViewController: UIViewController(), // TODO: update to `ViewControllerPresenting` when #12864 is done
            alertsPresenter: paymentAlertsPresenterAdaptor,
            onboardingPresenter: onboardingAdaptor,
            externalReaderConnectionController: connectionControllerManager.externalReaderConnectionController,
            tapToPayConnectionController: connectionControllerManager.tapToPayConnectionController)
    }
}
