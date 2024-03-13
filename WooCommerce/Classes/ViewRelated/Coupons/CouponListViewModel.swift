import Combine
import Yosemite
import protocol Storage.StorageManagerType
import class AutomatticTracks.CrashLogging
import UIKit
import Experiments

enum CouponListState {
    case initialized // ViewModel ready to receive actions
    case loading // View should show ghost cells
    case empty // View should display the empty state
    case couponsDisabled // View should display the error state
    case coupons // View should display the contents of `couponViewModels`
    case refreshing // View should display the refresh control
    case loadingNextPage // View should display a bottom loading indicator and contents of `couponViewModels`

    var shouldShowTopBanner: Bool {
        switch self {
        case .initialized, .loading, .empty, .couponsDisabled:
            return false
        case .coupons, .refreshing, .loadingNextPage:
            return true
        }
    }
}

final class CouponListViewModel: ObservableObject {

    typealias CellViewModel = TitleAndSubtitleAndStatusTableViewCell.ViewModel

    /// Active state
    ///
    @Published private(set) var state: CouponListState = .initialized

    @Published private(set) var shouldDisplayFeedbackBanner: Bool = false

    @Published private var isFeedbackBannerEnabledInAppSettings: Bool = false

    /// couponViewModels: ViewModels for the cells representing Coupons
    ///
    @Published private(set) var couponViewModels: [CellViewModel] = []

    /// siteID: siteID of the currently active site, used for fetching and storing coupons
    ///
    private let siteID: Int64

    /// resultsController: provides models from storage used for creation of cell ViewModels
    ///
    private let resultsController: ResultsController<StorageCoupon>

    /// syncingCoordinator: Keeps tracks of which pages have been refreshed, and
    /// encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator: SyncingCoordinatorProtocol

    /// storesManager: provides the store for handling actions
    ///
    private let storesManager: StoresManager

    /// storageManager: provides the storage for the results controller to fetch from
    ///
    private let storageManager: StorageManagerType

    // MARK: - Initialization and setup
    //
    init(siteID: Int64,
         showFeedbackBannerIfAppropriate: Bool = true,
         syncingCoordinator: SyncingCoordinatorProtocol = SyncingCoordinator(),
         storesManager: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         featureFlags: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteID = siteID
        self.syncingCoordinator = syncingCoordinator
        self.storesManager = storesManager
        self.storageManager = storageManager
        self.resultsController = Self.createResultsController(siteID: siteID,
                                                              storageManager: storageManager)

        configureSyncingCoordinator()
        configureResultsController()

        if showFeedbackBannerIfAppropriate {
            configureFeedbackBannerVisibility()
        }
    }

    func buildCouponViewModels() {
        couponViewModels = resultsController.fetchedObjects.map { coupon in
            CellViewModel(id: "\(coupon.couponID)",
                          title: coupon.code,
                          subtitle: coupon.summary(), // to be updated after UI is finalized
                          accessibilityLabel: coupon.description.isEmpty ? coupon.description : coupon.code,
                          status: coupon.expiryStatus().localizedName,
                          statusBackgroundColor: coupon.expiryStatus().statusBackgroundColor)
        }

        if couponViewModels.isNotEmpty {
            state = .coupons
        } else {
            state = .empty
        }
    }

    // MARK: - ViewController actions
    //
    /// The ViewController calls `viewDidLoad` to notify the view model it's ready to receive results
    ///
    func viewDidLoad() {
        syncingCoordinator.synchronizeFirstPage(reason: nil, onCompletion: nil)
    }

    /// The ViewController may use this method to retrieve a coupon for navigation purposes
    ///
    func coupon(at indexPath: IndexPath) -> Coupon? {
        return resultsController.safeObject(at: indexPath)
    }

    /// Triggers a refresh of loaded coupons
    ///
    func refreshCoupons() {
        syncingCoordinator.resynchronize(reason: nil, onCompletion: nil)
    }

    /// The ViewController can trigger loading of the next page when the user scrolls to the bottom
    ///
    func tableWillDisplayCell(at indexPath: IndexPath) {
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: indexPath.row)
    }

    /// Mark feedback request as dismissed and update banner visibility
    ///
    func dismissFeedbackBanner() {
        let action = AppSettingsAction.updateFeedbackStatus(type: .couponManagement,
                                                            status: .dismissed) { [weak self] result in
            if let error = result.failure {
                DDLogError("⛔️ Error updating feedback visibility for coupon management: \(error)")
            }
            self?.isFeedbackBannerEnabledInAppSettings = false
        }
        storesManager.dispatch(action)
    }

    /// Enable coupons for the store
    ///
    func enableCoupons() {
        ServiceLocator.analytics.track(.couponSettingEnabled)

        state = .loading
        let action = SettingAction.enableCouponSetting(siteID: siteID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.syncingCoordinator.synchronizeFirstPage(reason: nil, onCompletion: nil)
            case .failure(let error):
                DDLogError("⛔️ Error enabling coupon setting: \(error)")
                self.state = .couponsDisabled
            }
        }
        storesManager.dispatch(action)
    }
}

// MARK: - Setup view model
private extension CouponListViewModel {
    static func createResultsController(siteID: Int64,
                                                storageManager: StorageManagerType) -> ResultsController<StorageCoupon> {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageCoupon.dateCreated,
                                          ascending: false)

        return ResultsController<StorageCoupon>(storageManager: storageManager,
                                                matching: predicate,
                                                sortedBy: [descriptor])
    }

    /// Setup: Results Controller
    ///
    func configureResultsController() {
        resultsController.onDidChangeContent = buildCouponViewModels
        resultsController.onDidResetContent = buildCouponViewModels

        do {
            try resultsController.performFetch()
            buildCouponViewModels()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    /// Setup: Syncing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }

    func configureFeedbackBannerVisibility() {
        checkAppSettingsForFeedbackBannerVisibility()
        $state.combineLatest($isFeedbackBannerEnabledInAppSettings)
            .map { state, feedbackBannerVisibility -> Bool in
                state.shouldShowTopBanner && feedbackBannerVisibility
            }
            .assign(to: &$shouldDisplayFeedbackBanner)
    }

    func checkAppSettingsForFeedbackBannerVisibility() {
        let action = AppSettingsAction.loadFeedbackVisibility(type: .couponManagement) { [weak self] result in
            switch result {
            case .success(let visible):
                self?.isFeedbackBannerEnabledInAppSettings = visible
            case.failure(let error):
                self?.isFeedbackBannerEnabledInAppSettings = false
                DDLogError("⛔️ Error load feedback visibility for coupon management: \(error)")
            }
        }
        storesManager.dispatch(action)
    }

    /// Check whether coupons are enabled for this store.
    ///
    func loadCouponSetting(completionHandler: @escaping ((Result<Bool, Error>) -> Void)) {
        let action = SettingAction.retrieveCouponSetting(siteID: siteID) { result in
            if let isEnabled = try? result.get(), !isEnabled {
                ServiceLocator.analytics.track(.couponSettingDisabled)
            }
            completionHandler(result)
        }
        storesManager.dispatch(action)
    }
}

// MARK: - SyncingCoordinatorDelegate
//
extension CouponListViewModel: SyncingCoordinatorDelegate {
    /// Syncs the specified page of coupons from the API
    /// - Parameters:
    ///   - pageNumber: 1-indexed page number
    ///   - pageSize: Number of coupons per page
    ///   - reason: A string originating from a call to the coordinator's sync request methods,
    ///   to identify the type of sync required
    ///   - onCompletion: Completion handler to call passing whether the sync was successful
    func sync(pageNumber: Int,
              pageSize: Int,
              reason: String?,
              onCompletion: ((Bool) -> Void)?) {
        transitionToSyncingState(pageNumber: pageNumber, hasData: couponViewModels.isNotEmpty)
        let action = CouponAction
            .synchronizeCoupons(siteID: siteID,
                                pageNumber: pageNumber,
                                pageSize: pageSize) { [weak self] result in
                guard let self = self else { return }
                self.handleCouponSyncResult(result: result, pageNumber: pageNumber)
                onCompletion?(result.isSuccess)
        }

        storesManager.dispatch(action)
    }

    func handleCouponSyncResult(result: Result<Bool, Error>, pageNumber: Int) {
        switch result {
        case .success:
            DDLogInfo("Synchronized coupons")
            ServiceLocator.analytics.track(.couponsLoaded,
                                           withProperties: ["is_loading_more": pageNumber != SyncingCoordinator.Defaults.pageFirstIndex])
            transitionToResultsUpdatedState(hasData: couponViewModels.isNotEmpty)
        case .failure(let error):
            DDLogError("⛔️ Error synchronizing coupons: \(error)")
            ServiceLocator.analytics.track(.couponsLoadedFailed, withError: error)
            loadCouponSetting { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let isEnabled):
                    if isEnabled {
                        self.transitionToResultsUpdatedState(hasData: self.couponViewModels.isNotEmpty)
                    } else {
                        self.state = .couponsDisabled
                    }
                case .failure(let error):
                    DDLogError("⛔️ Error retrieving coupon setting: \(error)")
                    self.transitionToResultsUpdatedState(hasData: self.couponViewModels.isNotEmpty)
                }
            }
        }
    }
}

// MARK: - Pagination
//
private extension CouponListViewModel {
    func transitionToSyncingState(pageNumber: Int, hasData: Bool) {
        if pageNumber == 1 {
            state = hasData ? .refreshing : .loading
        } else {
            state = .loadingNextPage
        }
    }

    func transitionToResultsUpdatedState(hasData: Bool) {
        if hasData {
            state = .coupons
        } else {
            state = .empty
        }
    }
}
