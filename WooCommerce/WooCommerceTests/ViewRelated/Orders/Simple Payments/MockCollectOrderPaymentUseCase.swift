import Foundation
@testable import WooCommerce
import Yosemite

/// Mock type for `CollectOrderPaymentProtocol`
///
struct MockCollectOrderPaymentUseCase: CollectOrderPaymentProtocol {
    /// Assign to configure `collectPayment` behaviour.
    ///
    var onCollectResult: Result<Void, Error>

    /// Calls `onCompleted` for a successful collect result, and `onFailure` for an errer .
    ///
    func collectPayment(using: Yosemite.CardReaderDiscoveryMethod,
                        onFailure: @escaping (Error) -> Void,
                        onCancel: @escaping () -> Void,
                        onPaymentCompletion: @escaping () -> Void,
                        onCompleted: @escaping () -> Void) {
        switch onCollectResult {
        case .success:
            onCompleted()
        case .failure(let error):
            onFailure(error)
        }
    }
}
