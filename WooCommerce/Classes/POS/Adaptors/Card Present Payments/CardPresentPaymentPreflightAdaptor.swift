import Foundation
import Combine
import enum Yosemite.CardReaderDiscoveryMethod

protocol CardPresentPaymentPreflightControllerFacade {
    func attemptConnection(discoveryMethod: CardReaderDiscoveryMethod) async throws -> CardReaderPreflightResult
}

final class CardPresentPaymentPreflightAdaptor: CardPresentPaymentPreflightControllerFacade {
    private let preflightController: any CardPresentPaymentPreflightControllerProtocol

    init(preflightController: any CardPresentPaymentPreflightControllerProtocol) {
        self.preflightController = preflightController
    }

    @MainActor
    func attemptConnection(discoveryMethod: CardReaderDiscoveryMethod) async throws -> CardReaderPreflightResult {
        return try await withTaskCancellationHandler {
            async let preflightResult = firstPreflightResult(
                from: preflightController.readerConnection
                    .compactMap { $0 }
                    .values
            )

            // This isn't a great async method... it would be better if it returned its result,
            // but it actually returns before connection is finished.
            // To get around this, we use the subscription above.
            await preflightController.start(discoveryMethod: discoveryMethod)

            return try await preflightResult
        } onCancel: {
            preflightController.cancelConnectionAttempt()
        }
    }

    private func firstPreflightResult<Results: AsyncSequence>(
        from results: Results
    ) async throws -> CardReaderPreflightResult where Results.Element == CardReaderPreflightResult {
        for try await result in results {
            return result
        }

        throw CancellationError()
    }
}
