import Foundation
import Storage
import Networking

struct MockPaymentActionHandler: MockActionHandler {

    typealias ActionType = PaymentAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    init(objectGraph: MockObjectGraph, storageManager: StorageManagerType) {
        self.objectGraph = objectGraph
        self.storageManager = storageManager
    }

    func handle(action: PaymentAction) {
        switch action {
        case .loadSiteCurrentPlan(siteID: _, completion: let completion):
            let mockPlan = WPComSitePlan(
                id: "mock_plan_id",
                hasDomainCredit: true,
                expiryDate: nil,
                subscribedDate: Date(),
                name: "Mock Plan",
                slug: "mock-plan"
            )
            completion(.success(mockPlan))

        default:
            break
        }
    }
}
