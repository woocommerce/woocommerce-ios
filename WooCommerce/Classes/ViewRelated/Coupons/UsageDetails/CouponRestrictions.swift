import SwiftUI

struct CouponRestrictions: View {

    @State private var showingAllowedEmails: Bool = false
    @State private var showingExcludeProducts: Bool = false
    @State private var showingExcludeCategories: Bool = false
    @ObservedObject private var viewModel: CouponRestrictionsViewModel

    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    private let categorySelectorConfig = ProductCategorySelector.Configuration.excludedCategories
    private let categoryListConfig = ProductCategoryListViewController.Configuration(searchEnabled: true, selectAllEnabled: true)

    init(viewModel: CouponRestrictionsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        TitleAndTextFieldRow(title: String.localizedStringWithFormat(Localization.minimumSpend, viewModel.currencySymbol),
                                             placeholder: Localization.none,
                                             text: $viewModel.minimumSpend,
                                             keyboardType: .decimalPad)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)
                        TitleAndTextFieldRow(title: String.localizedStringWithFormat(Localization.maximumSpend, viewModel.currencySymbol),
                                             placeholder: Localization.none,
                                             text: $viewModel.maximumSpend,
                                             keyboardType: .decimalPad)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)
                        TitleAndTextFieldRow(title: Localization.usageLimitPerCoupon,
                                             placeholder: Localization.unlimited,
                                             text: $viewModel.usageLimitPerCoupon,
                                             keyboardType: .asciiCapableNumberPad)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)
                        TitleAndTextFieldRow(title: Localization.usageLimitPerUser,
                                             placeholder: Localization.unlimited,
                                             text: $viewModel.usageLimitPerUser,
                                             keyboardType: .asciiCapableNumberPad)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)
                    }
                    .background(Color(.listForeground))

                    VStack(alignment: .leading, spacing: 0) {
                        TitleAndTextFieldRow(title: Localization.limitUsageToXItems,
                                             placeholder: Localization.allQualifyingInCart,
                                             text: $viewModel.limitUsageToXItems,
                                             keyboardType: .asciiCapableNumberPad)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)
                        TitleAndValueRow(title: Localization.allowedEmails,
                                         value: viewModel.allowedEmails.isNotEmpty ?
                                            .content(viewModel.allowedEmails) :
                                                .content(Localization.noRestrictions),
                                         selectionStyle: .disclosure) {
                            showingAllowedEmails = true
                        }
                                         .padding(.horizontal, insets: geometry.safeAreaInsets)

                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)
                    }

                    VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                        TitleAndToggleRow(title: Localization.individualUseOnly,
                                          isOn: $viewModel.individualUseOnly)
                            .padding(.horizontal, Constants.margin)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)

                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)

                        Text(Localization.individualUseDescription)
                            .footnoteStyle()
                            .padding(.horizontal, Constants.margin)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)

                        TitleAndToggleRow(title: Localization.excludeSaleItems,
                                          isOn: $viewModel.excludeSaleItems)
                            .padding(.horizontal, Constants.margin)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)

                        Divider()
                            .padding(.leading, Constants.margin)
                            .padding(.leading, insets: geometry.safeAreaInsets)

                        Text(Localization.excludeSaleItemsDescription)
                            .footnoteStyle()
                            .padding(.horizontal, Constants.margin)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                    }
                    .padding(.vertical, Constants.margin)
                }

                VStack(alignment: .leading, spacing: Constants.margin) {
                    Text(Localization.exclusions.uppercased())
                        .footnoteStyle()
                    Button(action: {
                        showingExcludeProducts = true
                    }) {
                        HStack {
                            Image(uiImage: UIImage.plusImage)
                                .resizable()
                                .frame(width: Constants.plusIconSize * scale, height: Constants.plusIconSize * scale)
                            Text(Localization.excludeProducts)
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle(labelFont: .body))

                    Button(action: {
                        showingExcludeCategories = true
                    }) {
                        HStack {
                            Image(uiImage: UIImage.plusImage)
                                .resizable()
                                .frame(width: Constants.plusIconSize * scale, height: Constants.plusIconSize * scale)
                            Text(Localization.excludeProductCategories)
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle(labelFont: .body))
                }
                .padding(.vertical, Constants.sectionSpacing)
                .padding(.horizontal, Constants.margin)
                .padding(.horizontal, insets: geometry.safeAreaInsets)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.listForeground))
            .ignoresSafeArea(.container, edges: [.horizontal])
            .sheet(isPresented: $showingExcludeProducts) {
                ProductSelector(configuration: ProductSelector.Configuration.excludedProductsForCoupons,
                                isPresented: $showingExcludeProducts,
                                viewModel: viewModel.productSelectorViewModel)
                    .onDisappear {
                        viewModel.productSelectorViewModel.clearSearchAndFilters()
                    }
            }
            .sheet(isPresented: $showingExcludeCategories) {
                ProductCategorySelector(isPresented: $showingExcludeCategories,
                                        viewConfig: categorySelectorConfig,
                                        categoryListConfig: categoryListConfig,
                                        viewModel: viewModel.categorySelectorViewModel)
            }
            LazyNavigationLink(destination: CouponAllowedEmails(emailFormats: $viewModel.allowedEmails), isActive: $showingAllowedEmails) {
                EmptyView()
            }
        }
        .navigationTitle(Localization.usageRestriction)
    }
}

private extension CouponRestrictions {
    enum Constants {
        static let margin: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
        static let sectionSpacing: CGFloat = 30
        static let plusIconSize: CGFloat = 16
    }

    enum Localization {
        static let usageRestriction = NSLocalizedString(
            "Usage Restrictions",
            comment: "Title for the usage restrictions section on coupon usage details screen"
        )
        static let minimumSpend = NSLocalizedString(
            "Min. Spend (%1$@)",
            comment: "Title for the minimum spend row on coupon usage details screen with currency symbol within the brackets. " +
            "Reads like: Min. Spend ($)"
        )
        static let maximumSpend = NSLocalizedString(
            "Max. Spend (%1$@)",
            comment: "Title for the maximum spend row on coupon usage details screen with currency symbol within the brackets. " +
            "Reads like: Max. Spend ($)"
        )
        static let usageLimitPerCoupon = NSLocalizedString(
            "Usage Limit Per Coupon",
            comment: "Title for the usage limit per coupon row in coupon usage details screen."
        )
        static let usageLimitPerUser = NSLocalizedString(
            "Usage Limit Per User",
            comment: "Title for the usage limit per user row in coupon usage details screen."
        )
        static let limitUsageToXItems = NSLocalizedString(
            "Limit Usage to X Items",
            comment: "Title for the limit usage to X items row in coupon usage details screen."
        )
        static let allowedEmails = NSLocalizedString(
            "Allowed Emails",
            comment: "Title for the allowed email row in coupon usage details screen."
        )
        static let individualUseOnly = NSLocalizedString(
            "Individual Use Only",
            comment: "Title for the individual use only row in coupon usage details screen."
        )
        static let individualUseDescription = NSLocalizedString(
            "Turn this on if the coupon cannot be used in conjunction with other coupons.",
            comment: "Description for the individual use only row in coupon usage details screen."
        )
        static let excludeSaleItems = NSLocalizedString(
            "Exclude Sale Items",
            comment: "Title for the exclude sale items row in coupon usage details screen."
        )
        static let excludeSaleItemsDescription = NSLocalizedString(
            "Turn this on if the coupon should not apply to items on sale. " +
            "Per-item coupons will only work if the item is not on sale. " +
            "Per-cart coupons will only work if there are items in the cart that are not on sale.",
            comment: "Description for the exclude sale items row in coupon usage details screen."
        )
        static let none = NSLocalizedString("None", comment: "Value for fields in Coupon Usage Details screen when no value is set")
        static let unlimited = NSLocalizedString("Unlimited", comment: "Value for fields in Coupon Usage Details screen when no limit is set")
        static let allQualifyingInCart = NSLocalizedString(
            "All Qualifying",
            comment: "Value for the limit usage to X items row in Coupon Usage Details screen when no limit is set"
        )
        static let noRestrictions = NSLocalizedString(
            "No Restrictions",
            comment: "Value for the allowed emails row in Coupon Usage Details screen when no restriction is set"
        )
        static let exclusions = NSLocalizedString("Exclusions", comment: "Title of the exclusions section in Coupon Usage Details screen")
        static let excludeProducts = NSLocalizedString(
            "Exclude Products",
            comment: "Title of the action button to add products to the exclusion list in Coupon Usage Details screen"
        )
        static let excludeProductCategories = NSLocalizedString(
            "Exclude Product Categories",
            comment: "Title of the action button to add product categories to the exclusion list in Coupon Usage Details screen"
        )
    }
}

#if DEBUG
struct CouponRestrictions_Previews: PreviewProvider {
    static var previews: some View {
        CouponRestrictions(viewModel: .init(coupon: .sampleCoupon))

        CouponRestrictions(viewModel: .init(coupon: .sampleCoupon))
            .previewLayout(.fixed(width: 715, height: 320))
    }
}
#endif

private extension ProductSelector.Configuration {
    static let excludedProductsForCoupons: Self =
        .init(showsFilters: true,
              multipleSelectionsEnabled: true,
              doneButtonTitleSingularFormat: Localization.doneButtonSingular,
              doneButtonTitlePluralFormat: Localization.doneButtonPlural,
              title: Localization.title,
              cancelButtonTitle: Localization.cancel,
              productRowAccessibilityHint: Localization.productRowAccessibilityHint,
              variableProductRowAccessibilityHint: Localization.variableProductRowAccessibilityHint)

    enum Localization {
        static let title = NSLocalizedString("Exclude Products", comment: "Title for the screen to exclude products for a coupon")
        static let cancel = NSLocalizedString("Cancel", comment: "Text for the cancel button in the Exclude Products screen")
        static let productRowAccessibilityHint = NSLocalizedString("Toggles selection to exclude this product in a coupon.",
                                                                   comment: "Accessibility hint for excluding a product in the Exclude Products screen")
        static let variableProductRowAccessibilityHint = NSLocalizedString(
            "Opens list of product variations.",
            comment: "Accessibility hint for excluding a variable product in the Exclude Products screen"
        )
        static let doneButtonSingular = NSLocalizedString(
            "Exclude 1 Product",
            comment: "Title of the action button at the bottom of the Exclude Products screen when one product is selected"
        )
        static let doneButtonPlural = NSLocalizedString(
            "Exclude %1$d Products",
            comment: "Title of the action button at the bottom of the Exclude Products screen " +
            "when more than 1 item is selected, reads like: Exclude 5 Products"
        )
    }
}

private extension ProductCategorySelector.Configuration {
    static let excludedCategories: Self = .init(
        title: Localization.title,
        doneButtonSingularFormat: Localization.doneSingularFormat,
        doneButtonPluralFormat: Localization.donePluralFormat
    )

    enum Localization {
        static let title = NSLocalizedString("Exclude categories", comment: "Title for the Exclude Categories screen")
        static let doneSingularFormat = NSLocalizedString(
            "Exclude %1$d Category",
            comment: "Button to submit selection on the Exclude Categories screen when 1 item is selected")
        static let donePluralFormat = NSLocalizedString(
            "Exclude %1$d Categories",
            comment: "Button to submit selection on the Exclude Categories screen " +
            "when more than 1 item is selected. " +
            "Reads like: Exclude 10 Categories")
    }
}
