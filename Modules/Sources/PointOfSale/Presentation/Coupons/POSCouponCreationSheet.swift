import SwiftUI
import class WooFoundation.CurrencySettings
import typealias Yosemite.CouponDiscountType
import enum Yosemite.POSItem
import struct Yosemite.POSItemIdentifier
import struct Yosemite.POSCoupon

extension View {
    func posCouponCreationSheet(
        isPresented: Binding<Bool>,
        currencySettings: CurrencySettings,
        onSuccess: @escaping (POSItem) -> Void
    ) -> some View {
        modifier(POSCouponCreationSheetModifier(isPresented: isPresented, currencySettings: currencySettings, onSuccess: onSuccess))
    }
}

private struct POSCouponCreationSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let currencySettings: CurrencySettings
    let onSuccess: (POSItem) -> Void

    @Environment(\.posExternalViews) private var externalViews
    @Environment(\.posAccessSession) private var session
    @State private var selectedType: POSCouponDiscountType?
    @State private var showCouponSelectionSheet: Bool = false
    @State private var addedCouponItem: POSItem?

    func body(content: Content) -> some View {
        content
            .posSheet(item: $selectedType) { (posDiscountType: POSCouponDiscountType) in
                let scope = session.accessScope
                externalViews.createCouponCreationView(
                    discountType: posDiscountType.discountType,
                    showTypeSelection: $showCouponSelectionSheet,
                    onSuccess: { coupon in
                        guard session.isCurrent(scope) else { return }
                        let id = POSItemIdentifier(underlyingType: .coupon, itemID: coupon.couponID)
                        addedCouponItem = .coupon(.init(id: id,
                                                        code: coupon.code,
                                                        summary: coupon.summary(currencySettings: currencySettings),
                                                        appliesToWholeCart: coupon.appliesToWholeCart))
                    },
                    dismissHandler: {
                        selectedType = nil
                    },
                    onDisappear: {
                        defer { addedCouponItem = nil }
                        guard session.isCurrent(scope), let couponItem = addedCouponItem else { return }
                        selectedType = nil
                        onSuccess(couponItem)
                    }
                )
                .posSheet(isPresented: $showCouponSelectionSheet) {
                    externalViews.createDiscountTypeSelectionSheet(
                        isPresented: $showCouponSelectionSheet,
                        title: Localization.selectCouponTypeTitle,
                        cancelButtonTitle: Localization.selectCouponCancelButtonTitle
                    ) { type in
                        guard session.isCurrent(scope) else { return }
                        showCouponSelectionSheet = false
                        selectedType = POSCouponDiscountType(discountType: type)
                    }
                }
            }
            .posSheet(isPresented: $isPresented) {
                let scope = session.accessScope
                externalViews.createDiscountTypeSelectionSheet(
                    isPresented: $isPresented,
                    title: Localization.selectCouponTypeTitle,
                    cancelButtonTitle: Localization.selectCouponCancelButtonTitle
                ) { type in
                    guard session.isCurrent(scope) else { return }
                    selectedType = POSCouponDiscountType(discountType: type)
                }
            }
    }
}

private struct POSCouponDiscountType: Identifiable, Equatable {
    var id: String { discountType.rawValue }
    let discountType: CouponDiscountType
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
