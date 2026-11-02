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

    /// Calls `onCompleted` for a successful collect result, and `onFailure` for an errer .
    ///
    func collectPayment(using: Yosemite.CardReaderDiscoveryMethod,
                        channel: PaymentChannel,
                        onFailure: @escaping (Error) -> Void,
                        onCancel: @escaping () -> Void,
                        onPaymentCompletion: @escaping () -> Void,
                        onCompleted: @escaping () -> Void) {
        switch onCollectResult {
        case .success:
            if let onSuccessfulPayment {
                onSuccessfulPayment(onPaymentCompletion, onCompleted)
            } else {
                onCompleted()
            }
        case .failure(let error):
            onFailure(error)
        }
    }
}
