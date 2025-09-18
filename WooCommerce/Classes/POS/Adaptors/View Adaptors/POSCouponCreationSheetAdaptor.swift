import SwiftUI
import struct Yosemite.Coupon

/// Provide access to AddEditCouponView and ViewModel for POS without making it as an explicit type dependency
/// AddEditCouponView cannot be easily moved and reused in a shared module due to multiple dependencies
/// This is used as a workaround to enable POS modularization without requiring a larger refactoring effort
///

struct POSCouponCreationViewAdaptor: View {
    @StateObject private var viewModel: AddEditCouponViewModel
    @Binding private var showTypeSelection: Bool
    private let dismissHandler: () -> Void
    private let onDisappear: () -> Void

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
    }
}

struct POSDiscountTypeSelectionSheetAdaptor: View {
    @Binding var isPresented: Bool
    let title: String
    let cancelButtonTitle: String
    let onSelection: (Coupon.DiscountType) -> Void

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
