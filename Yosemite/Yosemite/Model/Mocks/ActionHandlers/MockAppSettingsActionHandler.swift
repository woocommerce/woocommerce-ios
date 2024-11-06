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
        case .loadLastSelectedPerformanceTimeRange(let siteId, let onCompletion):
            onCompletion(StatsTimeRangeV4.thisMonth)
        case .resetEligibilityErrorInfo,
                .setTelemetryAvailability,
                .loadOrdersSettings,
                .upsertProductsSettings,
                .loadLastSelectedTopPerformersTimeRange,
                .loadLastSelectedMostActiveCouponsTimeRange,
                .loadLastSelectedStockType,
                .loadLastSelectedOrderStatus,
                .loadFavoriteProductIDs,
                .loadCardReader,
                .loadDashboardCards:
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
}
