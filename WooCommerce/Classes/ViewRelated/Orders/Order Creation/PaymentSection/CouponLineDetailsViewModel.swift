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

    func validateAndSaveData(onCompletion: @escaping (Bool) -> Void) {
        let action = CouponAction.validateCouponCode(code: code, siteID: siteID) { [weak self] result in
            switch result {
            case let .success(couponExistsRemotely):
                if couponExistsRemotely {
                    self?.saveData()
                    onCompletion(true)
                } else {
                    self?.notice = Notice(title: Localization.couponNotFoundNoticeTitle,
                                          feedbackType: .error)
                    onCompletion(false)
                }
            case .failure(_):
                self?.notice = Notice(title: Localization.couponNotValidatedNoticeTitle,
                                      feedbackType: .error)
                onCompletion(false)
            }
        }

        Task { @MainActor in
            stores.dispatch(action)
        }
    }
}

private extension CouponLineDetailsViewModel {
    enum Localization {
        static let couponNotFoundNoticeTitle = NSLocalizedString("We couldn't find a coupon with that code. Please try again",
                                                                 comment: "Title for the error notice when we couldn't find" +
                                                                 "a coupon with the given code to add to an order.")
        static let couponNotValidatedNoticeTitle = NSLocalizedString("Something when wrong when validating your coupon code. Please try again",
                                                                     comment: "Notice title when validating a coupon code fails.")
    }
}
