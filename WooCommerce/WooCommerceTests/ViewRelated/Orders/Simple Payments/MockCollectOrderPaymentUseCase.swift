import Foundation
@testable import WooCommerce
import Yosemite

/// Mock type for `LegacyCollectOrderPaymentProtocol`
///
struct MockCollectOrderPaymentUseCase: CollectOrderPaymentProtocol {
    /// Assign to configure `collectPayment` behaviour.
    ///
    var onCollectResult: Result<Void, Error>

    /// Calls `onCompleted` for a successful collect result, and `onFailure` for an errer .
    ///
    func collectPayment(using: Yosemite.CardReaderDiscoveryMethod,
                        onFailure: @escaping (Error) -> (),
                        onCancel: @escaping () -> (),
                        onCompleted: @escaping () -> ()) {
        switch onCollectResult {
        case .success:
            onCompleted()
        case .failure(let error):
            onFailure(error)
        }
    }
}
