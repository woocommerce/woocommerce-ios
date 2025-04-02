import SwiftUI

extension View {
    func posCouponCreationSheet(
        isPresented: Binding<Bool>,
        onSuccess: @escaping () -> Void
    ) -> some View {
        modifier(POSCouponCreationSheetModifier(isPresented: isPresented, onSuccess: onSuccess))
    }
}

private struct POSCouponCreationSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onSuccess: () -> Void

    @State private var selectedType: POSCouponDiscountType?

    func body(content: Content) -> some View {
        content
            .sheet(item: $selectedType) { (posDiscountType: POSCouponDiscountType) in
                var view = AddEditCoupon(.init(discountType: posDiscountType.discountType, onSuccess: { _ in
                    onSuccess()
                }))

                view.dismissHandler = {
                    selectedType = nil
                }

                view.onDisappear = {
                    selectedType = nil
                }

                return view
            }
            .sheet(isPresented: $isPresented) {
                let viewProperties = BottomSheetListSelectorViewProperties(subtitle: Localization.createNewCouponTitle)
                let command = DiscountTypeBottomSheetListSelectorCommand(selected: nil) { type in
                    selectedType = POSCouponDiscountType(discountType: type)
                }
                BottomSheetListSelector(
                    viewProperties: viewProperties,
                    command: command,
                    onDismiss: { _ in
                        isPresented = false
                    }
                )
            }
    }
}

private enum Localization {
    static let createNewCouponTitle = NSLocalizedString(
        "pos.itemlistview.couponCreation.title",
        value: "Create New Coupon",
        comment: "A title for the view that creates a new coupon"
    )
}
