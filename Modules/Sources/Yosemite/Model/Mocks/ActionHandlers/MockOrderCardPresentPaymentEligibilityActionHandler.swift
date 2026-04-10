import Foundation
import Storage
import Networking

struct MockOrderCardPresentPaymentEligibilityActionHandler: MockActionHandler {
    typealias ActionType = OrderCardPresentPaymentEligibilityAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case let .orderIsEligibleForCardPresentPayment(_, _, _, onCompletion):
            onCompletion(.success(true))
        }
    }
}
