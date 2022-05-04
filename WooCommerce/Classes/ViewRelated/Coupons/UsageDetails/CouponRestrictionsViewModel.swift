import Combine
import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View Model for `CouponRestriction`
///
final class CouponRestrictionsViewModel: ObservableObject {

    let currencySymbol: String

    @Published var minimumSpend: String

    @Published var maximumSpend: String

    @Published var usageLimitPerCoupon: String

    @Published var usageLimitPerUser: String

    @Published var limitUsageToXItems: String

    @Published var allowedEmails: String

    @Published var individualUseOnly: Bool

    @Published var excludeSaleItems: Bool

    @Published private var excludedProductOrVariationIDs: [Int64]

    @Published private var excludedCategoryIDs: [Int64]

    /// View model for the product selector
    ///
    lazy var productSelectorViewModel = {
        ProductSelectorViewModel(siteID: siteID, selectedItemIDs: excludedProductOrVariationIDs, onMultipleSelectionCompleted: { [weak self] ids in
            self?.excludedProductOrVariationIDs = ids
        })
    }()

    /// View model for the category selector
    ///
    lazy var categorySelectorViewModel = {
        ProductCategorySelectorViewModel(siteID: siteID,
                                         selectedCategories: excludedCategoryIDs,
                                         storesManager: stores,
                                         storageManager: storageManager) { [weak self] categories in
            self?.excludedCategoryIDs = categories.map { $0.categoryID }
        }
    }()

    private let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType

    init(coupon: Coupon,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        currencySymbol = currencySettings.symbol(from: currencySettings.currencyCode)
        siteID = coupon.siteID
        self.stores = stores
        self.storageManager = storageManager

        minimumSpend = coupon.minimumAmount
        maximumSpend = coupon.maximumAmount
        if let perCoupon = coupon.usageLimit {
            usageLimitPerCoupon = "\(perCoupon)"
        } else {
            usageLimitPerCoupon = ""
        }

        if let perUser = coupon.usageLimitPerUser {
            usageLimitPerUser = "\(perUser)"
        } else {
            usageLimitPerUser = ""
        }

        if let limitUsageItemCount = coupon.limitUsageToXItems {
            limitUsageToXItems = "\(limitUsageItemCount)"
        } else {
            limitUsageToXItems = ""
        }

        if coupon.emailRestrictions.isNotEmpty {
            allowedEmails = coupon.emailRestrictions.joined(separator: ", ")
        } else {
            allowedEmails = ""
        }

        individualUseOnly = coupon.individualUse
        excludeSaleItems = coupon.excludeSaleItems
        excludedProductOrVariationIDs = coupon.excludedProductIds
        excludedCategoryIDs = coupon.excludedProductCategories
    }

    init(siteID: Int64,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        currencySymbol = currencySettings.symbol(from: currencySettings.currencyCode)
        minimumSpend = ""
        maximumSpend = ""
        usageLimitPerCoupon = ""
        usageLimitPerUser = ""
        limitUsageToXItems = ""
        allowedEmails = ""
        individualUseOnly = false
        excludeSaleItems = false
        excludedProductOrVariationIDs = []
        excludedCategoryIDs = []
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
    }
}
