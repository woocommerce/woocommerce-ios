import Foundation
import Storage

struct MockAppSettingsActionHandler: MockActionHandler {
    typealias ActionType = AppSettingsAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .loadFeedbackVisibility(let type, let onCompletion):
            loadFeedbackVisibility(type: type, onCompletion: onCompletion)
        case .setInstallationDateIfNecessary(let date, let onCompletion):
            setInstallationDateIfNecessary(date: date, onCompletion: onCompletion)
        case .loadProductsSettings(let siteId, let onCompletion):
            loadProductSettings(siteId: siteId, onCompletion: onCompletion)
        case .loadEligibilityErrorInfo(let onCompletion):
            onCompletion(.failure(AppSettingsStoreErrors.noEligibilityErrorInfo))
        case .loadOrderAddOnsSwitchState(let onCompletion):
            onCompletion(.failure(AppSettingsStoreErrors.noEligibilityErrorInfo))
        case .loadJetpackBenefitsBannerVisibility(_, _, let onCompletion):
            onCompletion(false)
        case .getFeatureAnnouncementVisibility(_, let onCompletion):
            onCompletion(.success(false))
        case .getSkippedCashOnDeliveryOnboardingStep(_, let onCompletion):
            onCompletion(false)
        case .loadSiteHasAtLeastOneIPPTransactionFinished(_, let onCompletion):
            onCompletion(false)
        case .loadLastSelectedPerformanceTimeRange(_, let onCompletion):
            onCompletion(StatsTimeRangeV4.thisMonth)
        case .loadLastSelectedTopPerformersTimeRange(_, let onCompletion):
            onCompletion(StatsTimeRangeV4.thisMonth)
        case .loadLastSelectedMostActiveCouponsTimeRange(_, let onCompletion):
            onCompletion(StatsTimeRangeV4.thisMonth)
        case .loadLastSelectedStockType(_, let onCompletion):
            onCompletion(nil)
        case .loadLastSelectedOrderStatus(_, let onCompletion):
            onCompletion(nil)
        case .loadFavoriteProductIDs(_, let onCompletion):
            onCompletion([])
        case .loadCardReader(let onCompletion):
            onCompletion(.success(nil))
        case .loadDashboardCards(let siteId, let onCompletion):
            loadDashboardCards(siteId: siteId, onCompletion: onCompletion)
        case .loadFirstInPersonPaymentsTransactionDate(_, _, let onCompletion):
            onCompletion(nil)
        case .loadSelectedTaxRateID(_, let onCompletion):
            onCompletion(nil)
        case .loadOrdersSettings(let siteID, let onCompletion):
            onCompletion(.success(.init(siteID: siteID,
                                        orderStatusesFilter: nil,
                                        dateRangeFilter: nil,
                                        productFilter: nil,
                                        customerFilter: nil)))
        case .upsertProductsSettings(_, _, _, _, _, _, _, let onCompletion):
            onCompletion(nil)
        case .resetEligibilityErrorInfo,
                .setTelemetryAvailability
            :
            break
        default: unimplementedAction(action: action)
        }
    }

    func loadFeedbackVisibility(type: FeedbackType, onCompletion: (Result<Bool, Error>) -> Void) {
        onCompletion(.success(true))
    }

    func setInstallationDateIfNecessary(date: Date, onCompletion: (Result<Bool, Error>) -> Void) {
        onCompletion(.success(true))
    }

    func loadProductSettings(siteId: Int64, onCompletion: (Result<StoredProductSettings.Setting, Error>) -> Void) {
        let emptySetting = StoredProductSettings.Setting(siteID: siteId,
                                                         sort: nil,
                                                         stockStatusFilter: nil,
                                                         productStatusFilter: nil,
                                                         productTypeFilter: nil,
                                                         productCategoryFilter: nil,
                                                         favoriteProduct: false)
        onCompletion(.success(emptySetting))
    }

    func loadDashboardCards(siteId: Int64, onCompletion: ([DashboardCard]?) -> Void) {
        var cards = [DashboardCard]()
        // Some cards intentionally not shown here as they require further action mocking.
        cards.append(DashboardCard(type: .performance, availability: .show, enabled: true))
        cards.append(DashboardCard(type: .reviews, availability: .show, enabled: true))
        cards.append(DashboardCard(type: .lastOrders, availability: .show, enabled: true))
        onCompletion(cards)
    }
}
