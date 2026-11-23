import Foundation
@testable import WooCommerce
import Yosemite

/// Mock type for `CollectOrderPaymentProtocol`
///
struct MockCollectOrderPaymentUseCase: CollectOrderPaymentProtocol {
    typealias SuccessfulPaymentHandler = (_ onPaymentCompletion: @escaping () -> Void, _ onCompleted: @escaping () -> Void) -> Void

    /// Assign to configure `collectPayment` behaviour.
    ///
    var onCollectResult: Result<Void, Error>

    var onSuccessfulPayment: SuccessfulPaymentHandler?

    /// Uses the no-receipt callback order unless the test controls when the receipt closes.
    ///
    func collectPayment(using: Yosemite.CardReaderDiscoveryMethod,
                        channel: PaymentChannel,
                        onFailure: @escaping (Error) -> Void,
                        onCancel: @escaping () -> Void,
                        onPaymentCompletion: @escaping (CardPresentReceiptParameters?) -> Void,
                        onCompleted: @escaping () -> Void) {
        switch onCollectResult {
        case .success:
            if let onSuccessfulPayment {
                onSuccessfulPayment({ onPaymentCompletion(nil) }, onCompleted)
            } else {
                onCompleted()
                onPaymentCompletion(nil)
            }
        case .failure(let error):
            onFailure(error)
        }
    }
}
