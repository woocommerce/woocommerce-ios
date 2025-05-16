import SwiftUI
import struct Yosemite.Coupon
import enum Yosemite.POSItem
import struct Yosemite.POSCoupon

extension View {
    func posCouponCreationSheet(
        isPresented: Binding<Bool>,
        onSuccess: @escaping (POSItem) -> Void
    ) -> some View {
        modifier(POSCouponCreationSheetModifier(isPresented: isPresented, onSuccess: onSuccess))
    }
}

private struct POSCouponCreationSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onSuccess: (POSItem) -> Void

    @State private var selectedType: POSCouponDiscountType?
    @State private var showCouponSelectionSheet: Bool = false
    @State private var addedCouponItem: POSItem?

    func body(content: Content) -> some View {
        content
            .sheet(item: $selectedType) { (posDiscountType: POSCouponDiscountType) in
                POSCouponCreationView(
                    discountType: posDiscountType.discountType,
                    showTypeSelection: $showCouponSelectionSheet,
                    onSuccess: { coupon in
                        addedCouponItem = .coupon(.init(id: UUID(), code: coupon.code, summary: coupon.summary()))
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
            }
            .discountTypeSelectionSheet(isPresented: $isPresented) { type in
                selectedType = type
            }
    }
}

private struct POSCouponCreationView: View {
    @StateObject private var viewModel: AddEditCouponViewModel
    @Binding var showTypeSelection: Bool
    let dismissHandler: () -> Void
    let onDisappear: () -> Void

    init(discountType: Coupon.DiscountType,
         showTypeSelection: Binding<Bool>,
         onSuccess: @escaping (Coupon) -> Void,
         dismissHandler: @escaping () -> Void,
         onDisappear: @escaping () -> Void) {
        _showTypeSelection = showTypeSelection
        self.dismissHandler = dismissHandler
        self.onDisappear = onDisappear
        _viewModel = StateObject(wrappedValue: AddEditCouponViewModel(
            discountType: discountType,
            onSuccess: onSuccess
        ))
    }

    var body: some View {
        var view = AddEditCoupon(viewModel)
        view.dismissHandler = dismissHandler
        view.onDisappear = onDisappear
        view.discountTypeHandler = { _ in
            showTypeSelection = true
        }

        return view
            .interactiveDismissDisabled()
            .discountTypeSelectionSheet(isPresented: $showTypeSelection) { type in
                showTypeSelection = false
                viewModel.discountType = type.discountType
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
