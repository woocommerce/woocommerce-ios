import Combine
import Yosemite
import protocol Storage.StorageManagerType
import Experiments

/// View model for `CouponSelectorView
/// `
final class CouponSelectorViewModel: ObservableObject {
    private let siteID: Int64

    /// Storage to fetch product list
    ///
    private let storageManager: StorageManagerType

    /// Stores to sync product list
    ///
    private let stores: StoresManager

    /// All active coupons
    ///
    @Published private var coupons: [Coupon] = []

    /// View models for each coupon row
    ///
    @Published private(set) var couponRows: [CouponRowViewModel] = []

    /// Selected coupon to be added to an order
    ///
    @Published private var selectedCoupon: Coupon?

    /// Closure to be invoked when a coupon is selected
    ///
    private let onCouponSelected: ((Coupon) -> Void)?


    /// Coupons Results Controller.
    ///
    private lazy var couponResultsController: ResultsController<StorageCoupon> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageCoupon.dateCreated,
                                          ascending: false)

        return ResultsController<StorageCoupon>(storageManager: storageManager,
                                                matching: predicate,
                                                sortedBy: [descriptor])
    }()

    /// Initializer for single selection
    ///
    init(siteID: Int64,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         onCouponSelected: ((Coupon) -> Void)? = nil) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.stores = stores
        self.onCouponSelected = onCouponSelected

        configureCouponResultsController()
    }

    func selectCoupon(_ coupon: Coupon) {
        selectedCoupon = coupon
    }
}

// MARK: - Configuration
private extension CouponSelectorViewModel {
    /// Configure results controller
    ///
    func configureCouponResultsController() {
        do {
            try couponResultsController.performFetch()
            loadCoupons()
        } catch {
            DDLogError("⛔️ Error fetching coupons for new order: \(error)")
        }
    }


    /// Fetch coupons from storage and loads only active coupons
    func loadCoupons() {
        let activeCoupons = couponResultsController.fetchedObjects.filter { coupon in
            coupon.expiryStatus() == .active
        }

        couponRows = activeCoupons.map { coupon in
            CouponRowViewModel(couponCode: coupon.code,
                               summary: coupon.summary())
        }
    }
}
