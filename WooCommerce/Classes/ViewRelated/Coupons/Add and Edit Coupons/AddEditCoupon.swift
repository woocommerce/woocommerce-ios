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
                        Group {
                            ListHeaderView(text: Localization.headerCouponDetails.uppercased(), alignment: .left)

                            Group {
                                TitleAndTextFieldRow(title: Localization.couponAmountPercentage,
                                                     placeholder: Localization.couponAmountPercentage,
                                                     text: $viewModel.amountField,
                                                     editable: false,
                                                     fieldAlignment: .leading,
                                                     keyboardType: .asciiCapableNumberPad)
                                Divider()
                                    .padding(.leading, Constants.margin)
                            }

                            Text(Localization.footerCouponAmountPercentage)
                                .subheadlineStyle()
                                .padding(.horizontal, Constants.margin)

                            Group {
                                TitleAndTextFieldRow(title: Localization.couponCode,
                                                     placeholder: Localization.couponCode,
                                                     text: $viewModel.codeField,
                                                     editable: false,
                                                     fieldAlignment: .leading,
                                                     keyboardType: .asciiCapableNumberPad)
                                Divider()
                                    .padding(.leading, Constants.margin)
                            }

                            Text(Localization.footerCouponCode)
                                .subheadlineStyle()
                                .padding(.horizontal, Constants.margin)

                            //TODO: leading aligning for this button
                            Button {
                                //TODO: handle action
                            } label: {
                                Text(Localization.regenerateCouponCodeButton)
                            }
                            .buttonStyle(LinkButtonStyle())
                            .padding(.horizontal, Constants.margin)

                            Button {
                                //TODO: handle action
                            } label: {
                                Text(Localization.addDescriptionButton)
                                    .bodyStyle()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.horizontal, Constants.margin)
                            .padding(.bottom, Constants.verticalSpacing)

                            Group {
                                TitleAndValueRow(title: Localization.couponExpiryDate,
                                                 value: .placeholder(Localization.couponExpiryDatePlaceholder),
                                                 selectionStyle: .disclosure, action: { })
                                Divider()
                                    .padding(.leading, Constants.margin)
                            }

                            Group {
                                TitleAndToggleRow(title: Localization.includeFreeShipping, isOn: .constant(false))
                                    .padding(.horizontal, Constants.margin)
                                Divider()
                                    .padding(.leading, Constants.margin)
                            }
                        }

                        Group {
                            ListHeaderView(text: Localization.headerApplyCouponTo.uppercased(), alignment: .left)

                            // TODO: add a new style with the icon on the left side
                            Button {
                                //TODO: handle action
                            } label: {
                                Text(Localization.editProductsButton)
                                    .bodyStyle()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.horizontal, Constants.margin)

                            // TODO: add a new style with the icon on the left side
                            Button {
                                //TODO: handle action
                            } label: {
                                Text(Localization.editProductCategoriesButton)
                                    .bodyStyle()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.horizontal, Constants.margin)
                        }

                        Group {
                            ListHeaderView(text: Localization.headerUsageDetails.uppercased(), alignment: .left)

                            TitleAndValueRow(title: Localization.usageRestrictions,
                                             value: .placeholder(""),
                                             selectionStyle: .disclosure, action: { })
                            Divider()
                                .padding(.leading, Constants.margin)
                        }

                        Button {
                            //TODO: handle action
                        } label: {
                            Text(Localization.saveButton)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, Constants.margin)
                        .padding(.top, Constants.verticalSpacing)
                    }
                }
                .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
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

    enum Constants {
        static let margin: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
    }

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
        static let regenerateCouponCodeButton = NSLocalizedString(
            "Regenerate Coupon Code",
            comment: "Button in the view for adding or editing a coupon.")
        static let addDescriptionButton = NSLocalizedString(
            "+ Add Description (Optional)",
            comment: "Button for adding a description to a coupon in the view for adding or editing a coupon.")
        static let couponExpiryDate = NSLocalizedString(
            "Coupon Expiry Date",
            comment: "Field in the view for adding or editing a coupon.")
        static let couponExpiryDatePlaceholder = NSLocalizedString(
            "None",
            comment: "Coupon expiry date placeholder in the view for adding or editing a coupon")
        static let includeFreeShipping = NSLocalizedString(
            "Include Free Shipping?",
            comment: "Toggle field in the view for adding or editing a coupon.")
        static let headerApplyCouponTo = NSLocalizedString(
            "Apply this coupon to",
            comment: "Header of the section for applying a coupon to specific products or categories in the view for adding or editing a coupon.")
        static let editProductsButton = NSLocalizedString(
            "Edit Products",
            comment: "Button for specify the products where a coupon can be applied in the view for adding or editing a coupon.")
        static let editProductCategoriesButton = NSLocalizedString(
            "Edit Product Categories",
            comment: "Button for specify the product categories where a coupon can be applied in the view for adding or editing a coupon.")
        static let headerUsageDetails = NSLocalizedString(
            "Usage Details",
            comment: "Header of the section usage details in the view for adding or editing a coupon.")
        static let usageRestrictions = NSLocalizedString(
            "Usage Restrictions",
            comment: "Field in the view for adding or editing a coupon.")
        static let saveButton = NSLocalizedString("Save", comment: "Action for saving a Coupon remotely")
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
