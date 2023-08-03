import Foundation
@testable import WooCommerce
import Yosemite
import Combine
import Fakes

final class MockCardPresentPaymentPreflightController: CardPresentPaymentPreflightControllerProtocol {
    func start(discoveryMethod: CardReaderDiscoveryMethod?) async {

    }

    private let readerConnectionSubject = CurrentValueSubject<CardReaderPreflightResult?, Never>(nil)

    var readerConnection: AnyPublisher<CardReaderPreflightResult?, Never> {
        readerConnectionSubject.eraseToAnyPublisher()
    }

    // Mock scenarios
    func cancelConnection(readerModel: String?, gatewayID: String?, source: WooAnalyticsEvent.InPersonPayments.CancellationSource) {
        readerConnectionSubject.send(.canceled(source, .fake(gatewayID: gatewayID)))
    }
}
