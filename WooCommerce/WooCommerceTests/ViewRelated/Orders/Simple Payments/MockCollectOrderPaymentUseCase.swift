import Foundation
@testable import WooCommerce

/// Mock type for `LegacyCollectOrderPaymentProtocol`
///
struct MockCollectOrderPaymentUseCase: LegacyCollectOrderPaymentProtocol {

    /// Assign to be returned on `onCollect` closure.
    ///
    var onCollectResult: Result<Void, Error>

    /// Calls `onCollect` and `onCompleted` secuencially.
    ///
    func collectPayment(onCollect: @escaping (Result<Void, Error>) -> (), onCancel: @escaping () -> (), onCompleted: @escaping () -> ()) {
        onCollect(onCollectResult)
        if onCollectResult.isSuccess {
            onCompleted()
        }
    }
}
