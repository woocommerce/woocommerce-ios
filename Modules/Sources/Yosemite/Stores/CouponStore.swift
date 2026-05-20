import Foundation
import Networking
import Storage

// MARK: - CouponStore
//
public final class CouponStore: Store {
    private let methods: CouponStoreMethods

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: CouponsRemoteProtocol) {
        self.methods = CouponStoreMethods(storageManager: storageManager, remote: remote)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Initialize a new CouponStore
    /// - Parameters:
    ///   - dispatcher: The dispatcher used to subscribe to `CouponActions`.
    ///   - storageManager: The storage layer used to store and retrieve persisted coupons.
    ///   - network: The network layer used to fetch Coupons
    ///
    override public convenience init(dispatcher: Dispatcher,
                                     storageManager: StorageManagerType,
                                     network: Network) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  remote: CouponsRemote(network: network))
    }

    // MARK: - Actions

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: CouponAction.self)
    }

    /// Receives and executes Actions.
    /// - Parameters:
    ///   - action: An action to handle. Must be a `CouponAction`
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? CouponAction else {
            assertionFailure("CouponStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeCoupons(let siteID, let pageNumber, let pageSize, let onCompletion):
            methods.synchronizeCoupons(siteID: siteID,
                                       pageNumber: pageNumber,
                                       pageSize: pageSize,
                                       onCompletion: onCompletion)
        case .deleteCoupon(let siteID, let couponID, let onCompletion):
            methods.deleteCoupon(siteID: siteID, couponID: couponID, onCompletion: onCompletion)
        case .updateCoupon(let coupon, let siteTimezone, let onCompletion):
            methods.updateCoupon(coupon, siteTimezone: siteTimezone, onCompletion: onCompletion)
        case .createCoupon(let coupon, let siteTimezone, let onCompletion):
            methods.createCoupon(coupon, siteTimezone: siteTimezone, onCompletion: onCompletion)
        case .loadCouponReport(let siteID, let couponID, let startDate, let onCompletion):
            methods.loadCouponReport(siteID: siteID, couponID: couponID, startDate: startDate, onCompletion: onCompletion)
        case .loadMostActiveCoupons(let siteID, let numberOfCouponsToLoad, let timeRange, let siteTimezone, let onCompletion):
            methods.loadMostActiveCoupons(siteID: siteID,
                                          numberOfCouponsToLoad: numberOfCouponsToLoad,
                                          timeRange: timeRange,
                                          siteTimezone: siteTimezone,
                                          onCompletion: onCompletion)
        case .searchCoupons(let siteID, let keyword, let pageNumber, let pageSize, let onCompletion):
            methods.searchCoupons(siteID: siteID,
                                  keyword: keyword,
                                  pageNumber: pageNumber,
                                  pageSize: pageSize,
                                  onCompletion: onCompletion)
        case .retrieveCoupon(let siteID, let couponID, let onCompletion):
            methods.retrieveCoupon(siteID: siteID, couponID: couponID, onCompletion: onCompletion)
        case .validateCouponCode(let code, let siteID, let onCompletion):
            methods.validateCouponCode(code: code, siteID: siteID, onCompletion: onCompletion)
        case .loadCoupons(let siteID, let couponIDs, let onCompletion):
            methods.loadCoupons(siteID: siteID, couponIDs: couponIDs, onCompletion: onCompletion)
        }
    }
}
