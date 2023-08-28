import Foundation
@testable import WooCommerce
import Yosemite
import Combine

final class MockCardPresentPaymentPreflightController: CardPresentPaymentPreflightControllerProtocol {
    func start(discoveryMethod: CardReaderDiscoveryMethod?) async {

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
