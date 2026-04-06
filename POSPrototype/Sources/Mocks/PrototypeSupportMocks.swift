import Foundation
import Yosemite
import Networking
import PointOfSale
import struct Networking.PagedItems

// MARK: - Receipt Service

final class PrototypeReceiptService: POSReceiptServiceProtocol {
    func sendReceipt(orderID: Int64, recipientEmail: String, isEligibleForPOSReceipt: Bool, templateID: String?) async throws {
        // no-op for prototype
    }
}

// MARK: - Coupon Service

final class PrototypeCouponService: PointOfSaleCouponServiceProtocol {
    func provideLocalPointOfSaleCoupons(fetchStrategy: PointOfSaleCouponFetchStrategy) async throws -> [POSItem] {
        []
    }

    func providePointOfSaleCoupons(pageNumber: Int,
                                   fetchStrategy: PointOfSaleCouponFetchStrategy) async throws -> PagedItems<POSItem> {
        PagedItems(items: [], hasMorePages: false, totalItems: 0)
    }

    func enableCoupons() async throws {
        // no-op for prototype
    }
}

// MARK: - Settings Service

final class PrototypeSettingsService: PointOfSaleSettingsServiceProtocol {
    private let storeName: String

    init(storeName: String = "Prototype Store") {
        self.storeName = storeName
    }

    func retrievePointOfSaleSettings() async throws -> POSReceiptInformation {
        POSReceiptInformation(
            storeName: storeName,
            storeAddress: "123 Prototype Street",
            phone: "555-0100",
            email: "prototype@example.com",
            refundReturnsPolicy: "No refunds on prototype orders"
        )
    }
}

// MARK: - Plugins Service

final class PrototypePluginsService: PluginsServiceProtocol {
    @MainActor
    func loadPluginInStorage(siteID: Int64, plugin: Plugin, isActive: Bool?) -> SystemPlugin? {
        nil
    }
}

// MARK: - Refunds Service

final class PrototypeRefundsService: POSRefundsServiceProtocol {
    func providePointOfSaleRefunds(for order: POSOrder) async throws -> POSRefundsResult {
        POSRefundsResult(refunds: [], isFullyRefunded: false, supportsAutomaticRefund: false)
    }

    func calculateRefundAmounts(for items: [POSRefundableItem]) -> POSRefundAmounts {
        POSRefundAmounts(subtotal: 0, tax: 0)
    }

    func createRefund(orderID: Int64, items: [POSRefundableItem], reason: String?, isAutomaticRefund: Bool) async throws {
        // no-op for prototype
    }

    func loadOrderRefunds(for order: POSOrder) async throws -> [POSOrderRefund] {
        []
    }
}

// MARK: - Collect Order Payment Analytics

final class PrototypeCollectOrderPaymentAnalytics: POSCollectOrderPaymentAnalyticsTracking {
    func trackCustomerInteractionStarted() {}
    func trackOrderSyncSuccess() {}
    func trackCardReaderReady() {}
    func trackCardReaderTapped() {}
    func trackCheckoutTapped() {}
    func trackSuccessfulCashPayment() {}
}

// MARK: - Entry Point Eligibility Checker

final class PrototypeEntryPointEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    func checkEligibility() async -> POSEligibilityState {
        .eligible
    }

    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState {
        .eligible
    }
}

// MARK: - Catalog Sync Coordinator

final class PrototypeCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    let fullSyncStateModel = POSCatalogSyncStateModel()

    func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval, regenerateCatalog: Bool) async throws {
        // no-op for prototype
    }

    func performIncrementalSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {
        // no-op for prototype
    }

    func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval, incrementalSyncMaxAge: TimeInterval) async throws {
        // no-op for prototype
    }

    func loadLastFullSyncState(for siteID: Int64) async -> POSCatalogSyncState {
        .syncCompleted(siteID: siteID)
    }

    func isSyncStale(for siteID: Int64, maxDays: Int) async -> Bool {
        false
    }

    func hoursSinceLastSync(for siteID: Int64) async -> Int? {
        0
    }

    func stopOngoingSyncs(for siteID: Int64) async {
        // no-op for prototype
    }

    func processBackgroundDownload(fileURL: URL, siteID: Int64) async throws {
        // no-op for prototype
    }

    func deleteProductsFromCatalog(_ productIDs: [Int64], variationIDs: [Int64], siteID: Int64) async throws {
        // no-op for prototype
    }

    func startBackgroundFTSRebuildIfNeeded(for siteID: Int64) async {
        // no-op for prototype
    }
}
