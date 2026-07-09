import SwiftUI
import class WooFoundation.CurrencySettings
import struct Yosemite.Coupon
import enum Yosemite.POSItem
import struct Yosemite.POSItemIdentifier
import struct Yosemite.POSCoupon
import struct Yosemite.POSStaffAuth

extension View {
    /// Presents the coupon-creation sheet.
    /// - Parameter auth: when non-nil, the resulting `POST /wc/v3/coupons` request carries the
    ///   `X-WC-POS-Staff-Id` header attributing the coupon to the operator who created it.
    func posCouponCreationSheet(
        isPresented: Binding<Bool>,
        auth: POSStaffAuth? = nil,
        currencySettings: CurrencySettings,
        onSuccess: @escaping (POSItem) -> Void
    ) -> some View {
        modifier(POSCouponCreationSheetModifier(isPresented: isPresented,
                                                auth: auth,
                                                currencySettings: currencySettings,
                                                onSuccess: onSuccess))
    }
}

private struct POSCouponCreationSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let auth: POSStaffAuth?
    let currencySettings: CurrencySettings
    let onSuccess: (POSItem) -> Void

    @Environment(\.posExternalViews) private var externalViews
    @State private var selectedType: POSCouponDiscountType?
    @State private var showCouponSelectionSheet: Bool = false
    @State private var addedCouponItem: POSItem?

    func body(content: Content) -> some View {
        content
            .posSheet(item: $selectedType) { (posDiscountType: POSCouponDiscountType) in
                externalViews.createCouponCreationView(
                    discountType: posDiscountType.discountType,
                    showTypeSelection: $showCouponSelectionSheet,
                    auth: auth,
                    onSuccess: { coupon in
                        let id = POSItemIdentifier(underlyingType: .coupon, itemID: coupon.couponID)
                        addedCouponItem = .coupon(.init(id: id, code: coupon.code, summary: coupon.summary(currencySettings: currencySettings)))
                    },
                    dismissHandler: {
                        selectedType = nil
                    },
                    onDisappear: {
                        if let couponItem = addedCouponItem {
                            selectedType = nil
                            onSuccess(couponItem)
                            addedCouponItem = nil
                        }
                    }
                )
                .posSheet(isPresented: $showCouponSelectionSheet) {
                    externalViews.createDiscountTypeSelectionSheet(
                        isPresented: $showCouponSelectionSheet,
                        title: Localization.selectCouponTypeTitle,
                        cancelButtonTitle: Localization.selectCouponCancelButtonTitle
                    ) { type in
                        showCouponSelectionSheet = false
                        selectedType = POSCouponDiscountType(discountType: type)
                    }
                }
            }
            .posSheet(isPresented: $isPresented) {
                externalViews.createDiscountTypeSelectionSheet(
                    isPresented: $isPresented,
                    title: Localization.selectCouponTypeTitle,
                    cancelButtonTitle: Localization.selectCouponCancelButtonTitle
                ) { type in
                    selectedType = POSCouponDiscountType(discountType: type)
                }
            }
    }
}

private struct POSCouponDiscountType: Identifiable, Equatable {
    var id: String { discountType.rawValue }
    let discountType: Coupon.DiscountType
}

private enum Localization {
    static let selectCouponTypeTitle = NSLocalizedString(
        "pos.couponCreationSheet.selectCoupon.title",
        value: "Create coupon",
        comment: "A title for the view that selects the type of coupon to create"
    )

    static let selectCouponCancelButtonTitle = NSLocalizedString(
        "pos.couponCreationSheet.selectCoupon.cancel",
        value: "Cancel",
        comment: "A button that dismisses coupon creation sheet"
    )
}
