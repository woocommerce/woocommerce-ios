import SwiftUI
import Yosemite

/// A view for Adding or Editing a Coupon.
///
struct AddEditCoupon: View {

    @ObservedObject private var viewModel: AddEditCouponViewModel
    @State private var showingCouponRestrictions: Bool = false
    @State private var showingEditDescription: Bool = false
    @Environment(\.presentationMode) var presentation

    init(_ viewModel: AddEditCouponViewModel) {
        self.viewModel = viewModel
        //TODO: add analytics
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack (alignment: .leading, spacing: 0) {
                        Group {
                            ListHeaderView(text: Localization.headerCouponDetails.uppercased(), alignment: .left)

                            Group {
                                TitleAndTextFieldRow(title: viewModel.amountLabel,
                                                     placeholder: "0",
                                                     text: $viewModel.amountField,
                                                     editable: true,
                                                     fieldAlignment: .leading,
                                                     keyboardType: .decimalPad)
                                Divider()
                                    .padding(.leading, Constants.margin)

                                Text(viewModel.amountSubtitleLabel)
                                    .subheadlineStyle()
                                    .padding(.horizontal, Constants.margin)
                            }
                            .padding(.bottom, Constants.verticalSpacing)

                            Group {
                                TitleAndTextFieldRow(title: Localization.couponCode,
                                                     placeholder: Localization.couponCodePlaceholder,
                                                     text: $viewModel.codeField,
                                                     editable: true,
                                                     fieldAlignment: .leading,
                                                     keyboardType: .default)
                                Divider()
                                    .padding(.leading, Constants.margin)
                                    .padding(.bottom, Constants.verticalSpacing)
                                Text(Localization.footerCouponCode)
                                    .subheadlineStyle()
                                    .padding(.horizontal, Constants.margin)
                            }
                            .padding(.bottom, Constants.verticalSpacing)

                            Button {
                                //TODO: handle action
                            } label: {
                                Text(Localization.regenerateCouponCodeButton)
                            }
                            .buttonStyle(LinkButtonStyle())
                            .fixedSize()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, Constants.verticalSpacing)

                            Button {
                                showingEditDescription = true
                            } label: {
                                HStack {
                                    Image(uiImage: viewModel.editDescriptionIcon)
                                        .colorMultiply(Color(.text))
                                        .frame(width: Constants.iconSize, height: Constants.iconSize)
                                    Text(viewModel.editDescriptionLabel)
                                        .bodyStyle()
                                }
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
                            .padding(.bottom, Constants.verticalSpacing)

                            Group {
                                TitleAndToggleRow(title: Localization.includeFreeShipping, isOn: .constant(false))
                                    .padding(.horizontal, Constants.margin)
                                Divider()
                                    .padding(.leading, Constants.margin)
                            }
                            .padding(.bottom, Constants.verticalSpacing)
                        }

                        Group {
                            ListHeaderView(text: Localization.headerApplyCouponTo.uppercased(), alignment: .left)
                                .padding(.bottom, Constants.verticalSpacing)

                            Button {
                                //TODO: handle action
                            } label: {
                                HStack {
                                    Image(uiImage: .pencilImage).colorMultiply(Color(.text))
                                        .frame(width: Constants.iconSize, height: Constants.iconSize)
                                    Text(Localization.editProductsButton)
                                        .bodyStyle()
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.horizontal, Constants.margin)
                            .padding(.bottom, Constants.verticalSpacing)

                            Button {
                                //TODO: handle action
                            } label: {
                                HStack {
                                    Image(uiImage: .pencilImage)
                                        .colorMultiply(Color(.text))
                                        .frame(width: Constants.iconSize, height: Constants.iconSize)
                                    Text(Localization.editProductCategoriesButton)
                                        .bodyStyle()
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.horizontal, Constants.margin)
                        }
                        .padding(.bottom, Constants.verticalSpacing)

                        Group {
                            ListHeaderView(text: Localization.headerUsageDetails.uppercased(), alignment: .left)

                            TitleAndValueRow(title: Localization.usageRestrictions,
                                             value: .placeholder(""),
                                             selectionStyle: .disclosure, action: {
                                showingCouponRestrictions = true
                            })
                            Divider()
                                .padding(.leading, Constants.margin)
                        }
                        .padding(.bottom, Constants.verticalSpacing)

                        Button {
                            //TODO: handle action
                        } label: {
                            Text(Localization.saveButton)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, Constants.margin)
                        .padding([.top, .bottom], Constants.verticalSpacing)

                        if let coupon = viewModel.coupon {
                            LazyNavigationLink(destination: CouponRestrictions(viewModel: CouponRestrictionsViewModel(coupon: coupon)),
                                               isActive: $showingCouponRestrictions) {
                                EmptyView()
                            }
                        }
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
        .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
    }
}

// MARK: - Constants
//
private extension AddEditCoupon {

    enum Constants {
        static let margin: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
        static let iconSize: CGFloat = 16
    }

    enum Localization {
        static let cancelButton = NSLocalizedString(
            "Cancel",
            comment: "Cancel button in the navigation bar of the view for adding or editing a coupon.")
        static let headerCouponDetails = NSLocalizedString(
            "Coupon details",
            comment: "Header of the coupon details in the view for adding or editing a coupon.")
        static let couponCode = NSLocalizedString(
            "Coupon Code",
            comment: "Text field coupon code in the view for adding or editing a coupon.")
        static let couponCodePlaceholder = NSLocalizedString(
            "Enter a coupon",
            comment: "Text field coupon code placeholder in the view for adding or editing a coupon.")
        static let footerCouponCode = NSLocalizedString(
            "Customers need to enter this code to use the coupon.",
            comment: "The footer of the text field coupon code in the view for adding or editing a coupon.")
        static let regenerateCouponCodeButton = NSLocalizedString(
            "Regenerate Coupon Code",
            comment: "Button in the view for adding or editing a coupon.")
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
