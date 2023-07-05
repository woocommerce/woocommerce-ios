import SwiftUI
import Yosemite

enum CouponValidationError: Error {
    case couponNotFound
}

enum CouponLineDetailsResult {
    case removed(code: String)
    case edited(oldCode: String, newCode: String)
    case added(newCode: String)
}

final class CouponLineDetailsViewModel: Identifiable, ObservableObject {

    /// Closure to be invoked when the coupon line is updated.
    ///
    var didSelectSave: ((CouponLineDetailsResult) -> Void)

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
         code: String? = nil,
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         didSelectSave: @escaping ((CouponLineDetailsResult) -> Void)) {
        self.isExistingCouponLine = isExistingCouponLine
        self.code = code ?? ""
        self.siteID = siteID
        self.stores = stores
        self.initialCode = code
        self.didSelectSave = didSelectSave
    }

    func removeCoupon() {
        guard let initialCode = initialCode else {
            return
        }

        didSelectSave(.removed(code: initialCode))
    }

    func validateAndSaveData(onCompletion: @escaping (Bool) -> Void) {
        let action = CouponAction.validateCouponCode(code: code.lowercased(), siteID: siteID) { [weak self] result in
            switch result {
            case .success(true):
                self?.saveData()
                onCompletion(true)
            case .success(false):
                self?.notice = Notice(title: Localization.couponNotFoundNoticeTitle,
                                      feedbackType: .error)
                onCompletion(false)
            case .failure(_):
                self?.notice = Notice(title: Localization.couponNotValidatedNoticeTitle,
                                      feedbackType: .error)
                onCompletion(false)
            }
        }

        stores.dispatch(action)
    }
}

private extension CouponLineDetailsViewModel {
    func saveData() {
        guard isExistingCouponLine,
             let initialCode = initialCode,
             initialCode.isNotEmpty else {
            return didSelectSave(.added(newCode: code))
        }

        didSelectSave(.edited(oldCode: initialCode, newCode: code))
    }
}

private extension CouponLineDetailsViewModel {
    enum Localization {
        static let couponNotFoundNoticeTitle = NSLocalizedString("We couldn't find a coupon with that code. Please try again",
                                                                 comment: "Title for the error notice when we couldn't find" +
                                                                 "a coupon with the given code to add to an order.")
        static let couponNotValidatedNoticeTitle = NSLocalizedString("Something went wrong when validating your coupon code. Please try again",
                                                                     comment: "Notice title when validating a coupon code fails.")
    }
}
