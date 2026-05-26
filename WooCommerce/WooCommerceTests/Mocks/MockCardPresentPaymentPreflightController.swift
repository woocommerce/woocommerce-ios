import Foundation
@testable import WooCommerce
import Yosemite
import Combine

final class MockCardPresentPaymentPreflightController: CardPresentPaymentPreflightControllerProtocol {
    private(set) var startCallCount = 0
    private(set) var cancelConnectionAttemptCallCount = 0
    var onStart: (() -> Void)?

    func start(discoveryMethod: CardReaderDiscoveryMethod?) async {
        startCallCount += 1
        onStart?()
    }

    func cancelConnectionAttempt() {
        cancelConnectionAttemptCallCount += 1
    }

    private let readerConnectionSubject = CurrentValueSubject<CardReaderPreflightResult?, Never>(nil)

    var readerConnection: AnyPublisher<CardReaderPreflightResult?, Never> {
        readerConnectionSubject.eraseToAnyPublisher()
    }

    // Mock scenarios
    func cancelConnection(readerModel: String?, gatewayID: String?, source: WooAnalyticsEvent.InPersonPayments.CancellationSource) {
        readerConnectionSubject.send(.canceled(source, .fake().copy(gatewayID: gatewayID)))
    }

    func completeConnection(reader: CardReader, gatewayID: String?) {
        readerConnectionSubject.send(.completed(reader, .fake().copy(gatewayID: gatewayID)))
    }
}
