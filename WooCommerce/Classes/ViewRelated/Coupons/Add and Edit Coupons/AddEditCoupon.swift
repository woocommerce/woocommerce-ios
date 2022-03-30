import SwiftUI
import Yosemite

/// A view for Adding or Editing a Coupon.
///
struct AddEditCoupon: View {

    @ObservedObject private var viewModel: AddEditCouponViewModel
    @Environment(\.presentationMode) var presentation

    init(_ viewModel: AddEditCouponViewModel) {
        self.viewModel = viewModel
        //TODO: add analytics
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack (alignment: .leading) {
                        ListHeaderView(text: Localization.headerCouponDetails.uppercased(), alignment: .left)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)

                        TitleAndTextFieldRow(title: Localization.couponAmountPercentage,
                                             placeholder: Localization.couponAmountPercentage,
                                             text: $viewModel.amountField,
                                             editable: false,
                                             fieldAlignment: .leading,
                                             keyboardType: .asciiCapableNumberPad)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                            .padding([.leading], insets: geometry.safeAreaInsets)
                        Text(Localization.footerCouponAmountPercentage)
                            .subheadlineStyle()
                            .padding(.horizontal, insets: geometry.safeAreaInsets)

                        TitleAndTextFieldRow(title: Localization.couponCode,
                                             placeholder: Localization.couponCode,
                                             text: $viewModel.codeField,
                                             editable: false,
                                             fieldAlignment: .leading,
                                             keyboardType: .asciiCapableNumberPad)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                            .padding([.leading], insets: geometry.safeAreaInsets)
                        Text(Localization.footerCouponCode)
                            .subheadlineStyle()
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                    }

                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton, action: {
                        presentation.wrappedValue.dismiss()
                    })
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.large)
            .wooNavigationBarStyle()
        }
    }
}

// MARK: - Constants
//
private extension AddEditCoupon {
    enum Localization {
        static let cancelButton = NSLocalizedString(
            "Cancel",
            comment: "Cancel button in the navigation bar of the view for adding or editing a coupon.")
        static let headerCouponDetails = NSLocalizedString(
            "Coupon details",
            comment: "Header of the coupon details in the view for adding or editing a coupon.")
        static let couponAmountPercentage = NSLocalizedString(
            "Amount (%)",
            comment: "Text field Amount in percentage in the view for adding or editing a coupon.")
        static let footerCouponAmountPercentage = NSLocalizedString(
            "Set the percentage of the discount you want to offer.",
            comment: "The footer of the text field Amount in percentage in the view for adding or editing a coupon.")
        static let couponCode = NSLocalizedString(
            "Coupon Code",
            comment: "Text field coupon code in the view for adding or editing a coupon.")
        static let footerCouponCode = NSLocalizedString(
            "Customers need to enter this code to use the coupon.",
            comment: "The footer of the text field coupon code in the view for adding or editing a coupon.")
    }
}

#if DEBUG
struct AddEditCoupon_Previews: PreviewProvider {
    static var previews: some View {

        /// Edit Coupon
        ///
        let editingViewModel = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon)
        AddEditCoupon(editingViewModel)
    }
}
#endif
