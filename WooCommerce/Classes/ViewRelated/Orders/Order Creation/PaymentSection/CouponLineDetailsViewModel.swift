import SwiftUI
import Yosemite

enum CouponValidationError: Error {
    case couponNotFound
}

final class CouponLineDetailsViewModel: ObservableObject {

    /// Closure to be invoked when the coupon line is updated.
    ///
    var didSelectSave: ((OrderCouponLine?) -> Void)

    /// Stores the coupon code entered by the merchant.
    ///
    @Published var code: String = ""

    /// Returns true when existing coupon line is edited.
    ///
    let isExistingCouponLine: Bool

    /// Returns true when there are no valid pending changes.
    ///
    var shouldDisableDoneButton: Bool {
        guard !code.isEmpty else {
            return true
        }

        return code == initialCode
    }

    @Published var notice: Notice?

    private let initialCode: String?

    private let siteID: Int64

    private let stores: StoresManager

    init(isExistingCouponLine: Bool,
         code: String,
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         didSelectSave: @escaping ((OrderCouponLine?) -> Void)) {
        self.isExistingCouponLine = isExistingCouponLine
        self.code = code
        self.siteID = siteID
        self.stores = stores
        self.initialCode = code
        self.didSelectSave = didSelectSave
    }

    func saveData() {
        let couponLine = OrderFactory.newOrderCouponLine(code: code)
        didSelectSave(couponLine)
    }

    func validateAndSaveData(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let action = CouponAction.validateCouponCode(code: code, siteID: siteID) { [weak self] result in
            switch result {
            case let .success(couponExistsRemotely):
                if couponExistsRemotely {
                    self?.saveData()
                    onCompletion(.success(()))
                } else {
                    self?.notice = Notice(title: Localization.scannedProductErrorNoticeMessage,
                                          feedbackType: .error)
                    onCompletion(.failure(CouponValidationError.couponNotFound))
                }
            case let .failure(error):
                self?.notice = Notice(title: Localization.scannedProductErrorNoticeMessage,
                                      feedbackType: .error)
                onCompletion(.failure(error))
            }
        }

        Task { @MainActor in
            stores.dispatch(action)
        }
    }
}
