import SwiftUI
import struct Yosemite.Coupon

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
    @State private var showCouponSelectionSheet: Bool = false

    func body(content: Content) -> some View {
        content
            .sheet(item: $selectedType) { (posDiscountType: POSCouponDiscountType) in
                let viewModel = AddEditCouponViewModel(discountType: posDiscountType.discountType, onSuccess: { _ in
                    onSuccess()
                })
                var view = AddEditCoupon(viewModel)

                view.dismissHandler = {
                    selectedType = nil
                }

                view.onDisappear = { success in
                    if success {
                        selectedType = nil
                    }
                }

                view.discountTypeHandler = { _ in
                    showCouponSelectionSheet = true
                }

                return view
                    .interactiveDismissDisabled()
                    .discountTypeSelectionSheet(isPresented: $showCouponSelectionSheet) { type in
                        showCouponSelectionSheet = false
                        viewModel.discountType = type.discountType
                    }
            }
            .discountTypeSelectionSheet(isPresented: $isPresented) { type in
                selectedType = type
            }
    }
}

private extension View {
    func discountTypeSelectionSheet(
        isPresented: Binding<Bool>,
        onSelection: @escaping (POSCouponDiscountType) -> Void
    ) -> some View {
        sheet(isPresented: isPresented) {
            let command = DiscountTypeBottomSheetListSelectorCommand(selected: nil) { type in
                onSelection(.init(discountType: type))
            }

            NavigationView {
                BottomSheetListSelector(
                    viewProperties: BottomSheetListSelectorViewProperties(),
                    command: command,
                    onDismiss: { _ in
                        isPresented.wrappedValue = false
                    }
                )
                .navigationBarTitleDisplayMode(.large)
                .navigationTitle(Localization.selectCouponTypeTitle)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Localization.selectCouponCancelButtonTitle) {
                            isPresented.wrappedValue = false
                        }
                    }
                }
            }
            .navigationViewStyle(.stack)
            .interactiveDismissDisabled()
        }
    }
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
