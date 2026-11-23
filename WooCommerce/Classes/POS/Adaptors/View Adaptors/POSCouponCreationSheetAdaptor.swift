import SwiftUI
import struct Yosemite.Coupon
import typealias Yosemite.CouponDiscountType

/// Provide access to AddEditCouponView and ViewModel for POS without making it as an explicit type dependency
/// AddEditCouponView cannot be easily moved and reused in a shared module due to multiple dependencies
/// This is used as a workaround to enable POS modularization without requiring a larger refactoring effort
///

@MainActor
struct POSCouponCreationViewAdaptor: View {
    @StateObject private var viewModel: AddEditCouponViewModel
    @Binding private var showTypeSelection: Bool
    private let onSuccess: (Coupon) -> Void
    private let dismissHandler: () -> Void

    init(discountType: CouponDiscountType,
         showTypeSelection: Binding<Bool>,
         onSuccess: @escaping (Coupon) -> Void,
         dismissHandler: @escaping () -> Void) {
        _showTypeSelection = showTypeSelection
        self.onSuccess = onSuccess
        self.dismissHandler = dismissHandler
        _viewModel = StateObject(wrappedValue: AddEditCouponViewModel(discountType: discountType, onSuccess: { _ in }))
    }

    var body: some View {
        var view = AddEditCoupon(viewModel)
        view.dismissHandler = dismissHandler
        view.onDisappear = {
            if let coupon = viewModel.coupon { onSuccess(coupon) }
        }
        view.discountTypeHandler = { _ in
            showTypeSelection = true
        }

        return view
            .interactiveDismissDisabled()
    }
}

@MainActor
struct POSDiscountTypeSelectionSheetAdaptor: View {
    @Binding var isPresented: Bool
    let title: String
    let cancelButtonTitle: String
    let onSelection: (CouponDiscountType) -> Void

    var body: some View {
        let command = DiscountTypeBottomSheetListSelectorCommand(selected: nil) { type in
            onSelection(type)
        }

        NavigationView {
            BottomSheetListSelector(
                viewProperties: BottomSheetListSelectorViewProperties(),
                command: command,
                onDismiss: { _ in
                    isPresented = false
                }
            )
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(cancelButtonTitle) {
                        isPresented = false
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .interactiveDismissDisabled()
    }
}
