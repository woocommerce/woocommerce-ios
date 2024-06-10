import Foundation
import WooFoundation
import Combine
import struct Yosemite.Order
import struct Yosemite.CardPresentPaymentsConfiguration

struct CardPresentPaymentCollectOrderPaymentUseCaseAdaptor {
    private let currencyFormatter: CurrencyFormatter

    init(currencyFormatter: CurrencyFormatter = .init(currencySettings: ServiceLocator.currencySettings)) {
        self.currencyFormatter = currencyFormatter
    }

    func collectPaymentTask(for order: Order,
                            using connectionMethod: CardReaderConnectionMethod,
                            siteID: Int64,
                            preflightController: CardPresentPaymentPreflightController,
                            onboardingPresenter: CardPresentPaymentsOnboardingPresenting,
                            configuration: CardPresentPaymentsConfiguration,
                            alertsPresenter: CardPresentPaymentAlertsPresenting,
                            paymentEventSubject: any Subject<CardPresentPaymentEvent, Never>) -> Task<CardPresentPaymentAdaptedCollectOrderPaymentResult, Error> {
        return Task {
            guard let formattedAmount = currencyFormatter.formatAmount(order.total, with: order.currency) else {
                throw CardPresentPaymentServiceError.invalidAmount
            }

            let orderPaymentUseCase = CollectOrderPaymentUseCase(siteID: siteID,
                                                                 order: order,
                                                                 formattedAmount: formattedAmount,
                                                                 rootViewController: NullViewControllerPresenting(),
                                                                 onboardingPresenter: onboardingPresenter,
                                                                 configuration: configuration,
                                                                 alertsPresenter: alertsPresenter,
                                                                 preflightController: preflightController)

            return try await withTaskCancellationHandler {
                return try await withCheckedThrowingContinuation { continuation in
                    // The nillableContinuation prevents us accidentally resuming it twice.
                    var nillableContinuation: CheckedContinuation<CardPresentPaymentAdaptedCollectOrderPaymentResult, Error>? = continuation

                    orderPaymentUseCase.collectPayment(
                        using: connectionMethod.discoveryMethod,
                        onFailure: { error in
                            guard let continuation = nillableContinuation else { return }
                            nillableContinuation = nil

                            if let error = error as? CardPaymentErrorProtocol {
                                continuation.resume(throwing: error)
                                // TODO: Some of these errors are retriable with the same payment intent.
                                // This isn't catered for yet. Perhaps those should not be thrown as errors,
                                // but sent to `paymentEventSubject` as events with retry/cancel handlers.
                                // if we do that, we shouldn't nil the continuation until we're definitely calling it,
                                // i.e. in those handlers.
                            } else {
                                continuation.resume(throwing: CardPresentPaymentServiceError.unknownPaymentError(underlyingError: error))
                            }
                        },
                        onCancel: {
                            guard let continuation = nillableContinuation else { return }
                            nillableContinuation = nil
                            paymentEventSubject.send(.idle)
                            continuation.resume(returning: CardPresentPaymentAdaptedCollectOrderPaymentResult.cancellation)
                        },
                        onPaymentCompletion: {
                            // This isn't required for our use case yet.
                        },
                        onCompleted: {
                            guard let continuation = nillableContinuation else { return }
                            nillableContinuation = nil
                            paymentEventSubject.send(.idle)
                            continuation.resume(returning: CardPresentPaymentAdaptedCollectOrderPaymentResult.success)
                        }
                    )
                }
            } onCancel: {
                // TODO: cancel any in-progress discovery, connection, or payment. #12869
            }
        }
    }
}

enum CardPresentPaymentAdaptedCollectOrderPaymentResult {
    case success
    case cancellation
}
