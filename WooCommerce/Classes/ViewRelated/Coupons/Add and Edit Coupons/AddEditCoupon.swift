import SwiftUI
import Yosemite

/// A view for Adding or Editing a Coupon.
///
struct AddEditCoupon: View {

    @ObservedObject private var viewModel: AddEditCouponViewModel
    @State private var showingEditDescription: Bool = false
    @State private var showingCouponExpiryActionSheet: Bool = false
    @State private var showingCouponExpiryDate: Bool = false
    @State private var showingCouponRestrictions: Bool = false
    @State private var showingSelectProducts: Bool = false
    @State private var showingSelectCategories: Bool = false
    @State private var showingDiscountTypeSheet: Bool = false
    @Environment(\.presentationMode) var presentation

    private var expiryDateActionSheetButtons: [Alert.Button] {
        var buttons: [Alert.Button] = []

        if viewModel.expiryDateField != nil {
            buttons = [
                .default(Text(Localization.actionSheetEditExpirationDate), action: {
                    showingCouponExpiryDate = true
                }),
                .destructive(Text(Localization.actionSheetDeleteExpirationDate), action: {
                    viewModel.expiryDateField = nil
                })
            ]
        }
        else {
            buttons = [
                .default(Text(Localization.actionSheetAddExpirationDate), action: {
                    showingCouponExpiryDate = true
                })
            ]
        }

        buttons.append(.cancel())

        return buttons
    }

    private let categorySelectorConfig = ProductCategorySelector.Configuration.categoriesForCoupons
    private let categoryListConfig = ProductCategoryListViewController.Configuration(searchEnabled: true, clearSelectionEnabled: true)

    init(_ viewModel: AddEditCouponViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack (alignment: .leading, spacing: 0) {
                        Group {
                            ListHeaderView(text: Localization.headerCouponDetails.uppercased(), alignment: .left)

                            Group {
                                TitleAndValueRow(title: Localization.discountType,
                                                 value: viewModel.discountTypeValue,
                                                 selectionStyle: .disclosure, action: {
                                    showingDiscountTypeSheet = true
                                })
                                Divider()
                                    .padding(.leading, Constants.margin)

                                TitleAndTextFieldRow(title: viewModel.amountLabel,
                                                     placeholder: "0",
                                                     text: $viewModel.amountField,
                                                     editable: true,
                                                     fieldAlignment: .leading,
                                                     keyboardType: .decimalPad,
                                                     inputFormatter: CouponAmountInputFormatter())
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
                                                     keyboardType: .default,
                                                     inputFormatter: CouponCodeInputFormatter())
                                Divider()
                                    .padding(.leading, Constants.margin)
                                    .padding(.bottom, Constants.verticalSpacing)
                                Text(Localization.footerCouponCode)
                                    .subheadlineStyle()
                                    .padding(.horizontal, Constants.margin)
                            }
                            .padding(.bottom, Constants.verticalSpacing)

                            Button {
                                viewModel.generateRandomCouponCode()
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
                                        .resizable()
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
                                                 value: viewModel.expiryDateValue,
                                                 selectionStyle: .disclosure, action: {
                                    showingCouponExpiryActionSheet = true
                                })
                                    .actionSheet(isPresented: $showingCouponExpiryActionSheet) {
                                        ActionSheet(
                                            title: Text(Localization.expiryDateActionSheetTitle),
                                            buttons: expiryDateActionSheetButtons
                                        )
                                    }
                                Divider()
                                    .padding(.leading, Constants.margin)
                            }
                            .padding(.bottom, Constants.verticalSpacing)

                            Group {
                                TitleAndToggleRow(title: Localization.includeFreeShipping, isOn: $viewModel.freeShipping)
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
                                showingSelectProducts = true
                            } label: {
                                HStack {
                                    if viewModel.hasSelectedProducts {
                                        Image(uiImage: .pencilImage)
                                            .resizable()
                                            .colorMultiply(Color(.text))
                                            .frame(width: Constants.iconSize, height: Constants.iconSize)
                                        Text(viewModel.editProductsButtonTitle)
                                            .bodyStyle()
                                    } else {
                                        Text(Localization.allProductsButton)
                                            .bodyStyle()
                                    }
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.horizontal, Constants.margin)
                            .padding(.bottom, Constants.verticalSpacing)

                            Button {
                                showingSelectCategories = true
                            } label: {
                                HStack {
                                    if viewModel.hasSelectedCategories {
                                        Image(uiImage: .pencilImage)
                                            .resizable()
                                            .colorMultiply(Color(.text))
                                            .frame(width: Constants.iconSize, height: Constants.iconSize)
                                        Text(viewModel.editCategoriesButtonTitle)
                                            .bodyStyle()
                                    } else {
                                        Image(uiImage: .plusImage)
                                            .resizable()
                                            .frame(width: Constants.iconSize, height: Constants.iconSize)
                                        Text(Localization.selectCategoriesButton)
                                            .bodyStyle()
                                    }
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
                            viewModel.updateCoupon(coupon: viewModel.populatedCoupon)
                        } label: {
                            Text(Localization.saveButton)
                        }
                        .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isLoading))
                        .padding(.horizontal, Constants.margin)
                        .padding([.top, .bottom], Constants.verticalSpacing)
                        .disabled(!viewModel.hasChangesMade)

                        LazyNavigationLink(destination: FullScreenTextView(title: Localization.titleEditDescriptionView,
                                                                           text: $viewModel.descriptionField,
                                                                           placeholder: Localization.addDescriptionPlaceholder),
                                           isActive: $showingEditDescription) {
                            EmptyView()
                        }

                        LazyNavigationLink(destination: CouponExpiryDateView(date: viewModel.expiryDateField ?? Date(),
                                                                             timezone: viewModel.timezone,
                                                                             completion: { updatedExpiryDate in
                            viewModel.expiryDateField = updatedExpiryDate
                        }),
                                           isActive: $showingCouponExpiryDate) {
                            EmptyView()
                        }

                        LazyNavigationLink(destination: CouponRestrictions(viewModel: viewModel.couponRestrictionsViewModel),
                                           isActive: $showingCouponRestrictions) {
                            EmptyView()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSelectProducts) {
                ProductSelector(configuration: ProductSelector.Configuration.productsForCoupons,
                                isPresented: $showingSelectProducts,
                                viewModel: viewModel.productSelectorViewModel)
                    .onDisappear {
                        viewModel.productSelectorViewModel.clearSearchAndFilters()
                    }
            }
            .sheet(isPresented: $showingSelectCategories) {
                ProductCategorySelector(isPresented: $showingSelectCategories,
                                        viewConfig: categorySelectorConfig,
                                        categoryListConfig: categoryListConfig,
                                        viewModel: viewModel.categorySelectorViewModel)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton, action: {
                        presentation.wrappedValue.dismiss()
                    })
                }
            }
            .notice($viewModel.notice)
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
            comment: "Text field coupon code in the view for adding or editing a coupon code.")
        static let couponCodePlaceholder = NSLocalizedString(
            "Enter a coupon",
            comment: "Text field coupon code placeholder in the view for adding or editing a coupon.")
        static let footerCouponCode = NSLocalizedString(
            "Customers need to enter this code to use the coupon.",
            comment: "The footer of the text field coupon code in the view for adding or editing a coupon.")
        static let regenerateCouponCodeButton = NSLocalizedString(
            "Regenerate Coupon Code",
            comment: "Button in the view for adding or editing a coupon code.")
        static let couponExpiryDate = NSLocalizedString(
            "Coupon Expiry Date",
            comment: "Field in the view for adding or editing a coupon's expiry date.")
        static let discountType = NSLocalizedString(
            "Discount Type",
            comment: "Field in the view for adding or editing a coupon's discount type.")
        static let includeFreeShipping = NSLocalizedString(
            "Include Free Shipping?",
            comment: "Toggle field in the view for adding or editing a coupon's free shipping support.")
        static let headerApplyCouponTo = NSLocalizedString(
            "Apply this coupon to",
            comment: "Header of the section for applying a coupon to specific products or categories in the view " +
            "for adding or editing a coupon's product and category restrictions.")
        static let allProductsButton = NSLocalizedString(
            "All Products",
            comment: "Button indicating that coupon can be applied to all products in the view for adding or editing a coupon.")
        static let selectCategoriesButton = NSLocalizedString(
            "Select Product Categories",
            comment: "Button to select specific categories applicable for a coupon in the view for adding or editing a coupon.")
        static let headerUsageDetails = NSLocalizedString(
            "Usage Details",
            comment: "Header of the section usage details in the view for adding or editing a coupon.")
        static let usageRestrictions = NSLocalizedString(
            "Usage Restrictions",
            comment: "Field in the view for adding or editing a coupon.")
        static let saveButton = NSLocalizedString("Save", comment: "Action for saving a Coupon remotely")
        static let addDescriptionPlaceholder = NSLocalizedString("Add the description of the coupon.",
                                                                 comment: "Placeholder text that will be shown in the view" +
                                                                 " for adding the description of a coupon.")
        static let expiryDateActionSheetTitle = NSLocalizedString("Set an expiry date for this coupon",
                                                                  comment: "Title of the action sheet for setting an expiry date for a coupon.")
        static let actionSheetEditExpirationDate = NSLocalizedString("Edit expiration date",
                                                                     comment: "Button in the action sheet for editing the expiration date of a coupon.")
        static let actionSheetDeleteExpirationDate = NSLocalizedString("Delete expiration date",
                                                                     comment: "Button in the action sheet for deleting the expiration date of a coupon.")
        static let actionSheetAddExpirationDate = NSLocalizedString("Add expiration date",
                                                                     comment: "Button in the action sheet for adding the expiration date for a coupon.")
        static let titleEditDescriptionView = NSLocalizedString("Coupon Description",
                                                                comment: "Title of the view for editing the coupon description.")
    }
}

#if DEBUG
struct AddEditCoupon_Previews: PreviewProvider {
    static var previews: some View {

        /// Edit Coupon
        ///
        let editingViewModel = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon, onCompletion: { _ in })
        AddEditCoupon(editingViewModel)
    }
}
#endif

private extension ProductSelector.Configuration {
    static let productsForCoupons: Self =
        .init(showsFilters: true,
              multipleSelectionsEnabled: true,
              doneButtonTitleSingularFormat: Localization.doneButtonSingular,
              doneButtonTitlePluralFormat: Localization.doneButtonPlural,
              title: Localization.title,
              cancelButtonTitle: Localization.cancel,
              productRowAccessibilityHint: Localization.productRowAccessibilityHint,
              variableProductRowAccessibilityHint: Localization.variableProductRowAccessibilityHint)

    enum Localization {
        static let title = NSLocalizedString("Select Products", comment: "Title for the screen to select products for a coupon")
        static let cancel = NSLocalizedString("Cancel", comment: "Text for the cancel button in the Select Products screen")
        static let productRowAccessibilityHint = NSLocalizedString("Toggles selection for this product in a coupon.",
                                                                   comment: "Accessibility hint for selecting a product in the Select Products screen")
        static let variableProductRowAccessibilityHint = NSLocalizedString(
            "Opens list of product variations.",
            comment: "Accessibility hint for selecting a variable product in the Select Products screen"
        )
        static let doneButtonSingular = NSLocalizedString(
            "Select 1 Product",
            comment: "Title of the action button at the bottom of the Select Products screen when one product is selected"
        )
        static let doneButtonPlural = NSLocalizedString(
            "Select %1$d Products",
            comment: "Title of the action button at the bottom of the Select Products screen " +
            "when more than 1 item is selected, reads like: Select 5 Products"
        )
    }
}

private extension ProductCategorySelector.Configuration {
    static let categoriesForCoupons: Self = .init(
        title: Localization.title,
        doneButtonSingularFormat: Localization.doneSingularFormat,
        doneButtonPluralFormat: Localization.donePluralFormat
    )

    enum Localization {
        static let title = NSLocalizedString("Select categories", comment: "Title for the Select Categories screen")
        static let doneSingularFormat = NSLocalizedString(
            "Select %1$d Category",
            comment: "Button to submit selection on the Select Categories screen when 1 item is selected")
        static let donePluralFormat = NSLocalizedString(
            "Select %1$d Categories",
            comment: "Button to submit selection on the Select Categories screen " +
            "when more than 1 item is selected. " +
            "Reads like: Select 10 Categories")
    }
}
