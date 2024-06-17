import Foundation
import Combine
import enum Yosemite.CardReaderDiscoveryMethod

protocol CardPresentPaymentPreflightControllerFacade {
    func attemptConnection(discoveryMethod: CardReaderDiscoveryMethod) async throws -> CardReaderPreflightResult
}

final class CardPresentPaymentPreflightAdaptor: CardPresentPaymentPreflightControllerFacade {
    private let preflightController: CardPresentPaymentPreflightController<CardPresentPaymentBuiltInReaderConnectionAlertsProvider,
                                                                           CardPresentPaymentBluetoothReaderConnectionAlertsProvider,
                                                                           CardPresentPaymentsAlertPresenterAdaptor>

    init(preflightController: CardPresentPaymentPreflightController<CardPresentPaymentBuiltInReaderConnectionAlertsProvider,
         CardPresentPaymentBluetoothReaderConnectionAlertsProvider,
         CardPresentPaymentsAlertPresenterAdaptor>) {
        self.preflightController = preflightController
    }

    @MainActor
    func attemptConnection(discoveryMethod: CardReaderDiscoveryMethod) async throws -> CardReaderPreflightResult {
        async let preflightResult: CardReaderPreflightResult = try preflightController.readerConnection
            .compactMap { $0 }
            .eraseToAnyPublisher()
            .async()

        // This isn't a great async method... it would be better if it returned its result,
        // but it actually returns before connection is finished.
        // To get around this, we use the subscription above.
        await preflightController.start(discoveryMethod: discoveryMethod)

        return try await preflightResult
    }
}

// From https://medium.com/geekculture/from-combine-to-async-await-c08bf1d15b77
fileprivate extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = first()
                .sink { result in
                    switch result {
                    case .finished:
                        break
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    continuation.resume(with: .success(value))
                }
        }
    }
}
