import Foundation
import StoreKit

enum WPComPlanProductTransactionStatus {
    case notStarted // Neither purchased through Apple nor the WPCom plan was unlocked
    case pending // In-App purchase was successful but the WPCom plan unlock request failed
    case finished // In-App purchase and WPCom plan unlock succesful
}

struct WPComPlanProduct {
    let localizedTitle: String
    let localizedDescription: String
    let price: String
    let currency: String
    let status: WPComPlanProductTransactionStatus
}

protocol InAppPurchasesForWPComPlansProtocol {
    func fetchProducts() async throws -> [WPComPlanProduct]
    func purchase(product: WPComPlanProduct, for remoteSiteId: Int64) async throws
    func inAppPurchasesAreSupported() async -> Bool
}

final class InAppPurchasesForWPComPlansManager: InAppPurchasesForWPComPlansProtocol {
    func fetchProducts() async throws -> [WPComPlanProduct] {
        []
    }

    func purchase(product: WPComPlanProduct, for remoteSiteId: Int64) async throws {
    }

    func inAppPurchasesAreSupported() async -> Bool {
        await Storefront.current?.countryCode == "USA"
    }
}
