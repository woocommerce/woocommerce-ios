import SwiftUI

/// Represents the Payment section in an order
///
struct OrderPaymentSection: View {
    /// View model to drive the view content
    let viewModel: EditableOrderViewModel.PaymentDataViewModel

    /// Indicates if the shipping line details screen should be shown or not.
    ///
    @State private var shouldShowShippingLineDetails: Bool = false

    /// Indicates if the fee line details screen should be shown or not.
    ///
    @State private var shouldShowFeeLineDetails: Bool = false

    /// Indicates if the coupon line details screen should be shown or not.
    ///
    @State private var shouldShowAddCouponLineDetails: Bool = false

    /// Indicates if the go to coupons alert should be shown or not.
    ///
    @State private var shouldShowGoToCouponsAlert: Bool = false

    /// Keeps track of the selected coupon line details view model.
    ///
    @State private var selectedCouponLineDetailsViewModel: CouponLineDetailsViewModel? = nil

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        Divider()

        VStack(alignment: .leading, spacing: .zero) {
            HStack {
                Text(Localization.payment)
                    .accessibilityAddTraits(.isHeader)
                    .headlineStyle()

                Spacer()

                Image(uiImage: .lockImage)
                    .foregroundColor(Color(.brand))
                    .renderedIf(viewModel.showNonEditableIndicators)

                ProgressView()
                    .renderedIf(viewModel.isLoading)
            }
            .padding()

            TitleAndValueRow(title: Localization.productsTotal, value: .content(viewModel.itemsTotal), selectionStyle: .none) {}

            shippingRow
                .sheet(isPresented: $shouldShowShippingLineDetails) {
                    ShippingLineDetails(viewModel: viewModel.shippingLineViewModel)
                }
            feesRow
                .sheet(isPresented: $shouldShowFeeLineDetails) {
                    FeeOrDiscountLineDetailsView(viewModel: viewModel.feeLineViewModel)
                }

            VStack {
                ForEach(viewModel.couponLineViewModels, id: \.title) { viewModel in
                    TitleAndValueRow(title: viewModel.title, value: .content(viewModel.discount), selectionStyle: .highlight) {
                        selectedCouponLineDetailsViewModel = viewModel.detailsViewModel
                    }
                }
            }
            .sheet(item: $selectedCouponLineDetailsViewModel) { viewModel in
                CouponLineDetails(viewModel: viewModel)
            }

            addCouponRow
                .sheet(isPresented: $shouldShowAddCouponLineDetails) {
                    NavigationView {
                        CouponListView(siteID: viewModel.siteID,
                                       emptyStateActionTitle: Localization.goToCoupons,
                                       emptyStateAction: {
                                            shouldShowGoToCouponsAlert = true
                                        },
                                       onCouponSelected: { coupon in
                                            viewModel.addNewCouponLineClosure(coupon)
                                            shouldShowAddCouponLineDetails = false
                                        })
                        .navigationTitle(Localization.addCoupon)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button(Localization.cancelButton) {
                                        shouldShowAddCouponLineDetails = false
                                    }
                                }
                            }
                            .alert(isPresented: $shouldShowGoToCouponsAlert, content: {
                                Alert(title: Text(Localization.goToCoupons),
                                      message: Text(Localization.goToCouponsAlertMessage),
                                      primaryButton: .default(Text(Localization.goToCouponsAlertButtonTitle), action: {
                                    viewModel.onGoToCouponsClosure()
                                    MainTabBarController.presentCoupons()
                                }),
                                      secondaryButton: .cancel())
                            })
                    }
                }

            if viewModel.shouldShowTaxExtraInformation {
                TitleSubtitleAndValuesRow(title: Localization.taxesTotal, titleValue: viewModel.taxesTotal, subtitle: "test", subtitleValue: "10%")
            } else {
                TitleAndValueRow(title: Localization.taxesTotal, value: .content(viewModel.taxesTotal))
            }

            TitleAndValueRow(title: Localization.discountTotal, value: .content(viewModel.discountTotal))
                .renderedIf(viewModel.shouldShowDiscountTotal)

            TitleAndValueRow(title: Localization.orderTotal, value: .content(viewModel.orderTotal), bold: true, selectionStyle: .none) {}
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.listForeground(modal: true)))

        Divider()
    }

    @ViewBuilder private var shippingRow: some View {
        if viewModel.shouldShowShippingTotal {
            TitleAndValueRow(title: Localization.shippingTotal, value: .content(viewModel.shippingTotal), selectionStyle: .highlight) {
                shouldShowShippingLineDetails = true
            }
        } else {
            Button(Localization.addShipping) {
                shouldShowShippingLineDetails = true
            }
            .buttonStyle(PlusButtonStyle())
            .padding()
            .accessibilityIdentifier("add-shipping-button")
        }
    }

    @ViewBuilder private var feesRow: some View {
        if viewModel.shouldShowFees {
            TitleAndValueRow(title: Localization.feesTotal, value: .content(viewModel.feesTotal), selectionStyle: .highlight) {
                shouldShowFeeLineDetails = true
            }
        } else {
            Button(Localization.addFee) {
                shouldShowFeeLineDetails = true
            }
            .buttonStyle(PlusButtonStyle())
            .padding()
            .accessibilityIdentifier("add-fee-button")
        }
    }

    @ViewBuilder private var addCouponRow: some View {
        Button(Localization.addCoupon) {
            shouldShowAddCouponLineDetails = true
        }
        .buttonStyle(PlusButtonStyle())
        .padding()
        .accessibilityIdentifier("add-coupon-button")
        .disabled(viewModel.shouldDisableAddingCoupons)
    }
}

// MARK: Constants
private extension OrderPaymentSection {
    enum Localization {
        static let payment = NSLocalizedString("Payment", comment: "Title text of the section that shows Payment details when creating a new order")
        static let productsTotal = NSLocalizedString("Products Total", comment: "Label for the row showing the total cost of products in the order")
        static let orderTotal = NSLocalizedString("Order Total", comment: "Label for the the row showing the total cost of the order")
        static let discountTotal = NSLocalizedString("Discount Total", comment: "Label for the the row showing the total discount of the order")
        static let addShipping = NSLocalizedString("Add Shipping", comment: "Title text of the button that adds shipping line when creating a new order")
        static let shippingTotal = NSLocalizedString("Shipping", comment: "Label for the row showing the cost of shipping in the order")
        static let addFee = NSLocalizedString("Add Fee", comment: "Title text of the button that adds a fee when creating a new order")
        static let feesTotal = NSLocalizedString("Fees", comment: "Label for the row showing the cost of fees in the order")
        static let taxesTotal = NSLocalizedString("Taxes", comment: "Label for the row showing the taxes in the order")
        static let addCoupon = NSLocalizedString("Add coupon", comment: "Title for the Coupon screen during order creation")
        static let coupon = NSLocalizedString("Coupon", comment: "Label for the row showing the cost of coupon in the order")
        static let goToCoupons = NSLocalizedString("Go to Coupons", comment: "Button title on the Coupon screen empty state" +
                                                   "when creating a new order that navigates to the Coupons Section")
        static let goToCouponsAlertMessage = NSLocalizedString("Do you want to navigate to the Coupons Menu? These changes will be discarded.",
                                                               comment: "Confirm message for navigating to coupons when creating a new order")
        static let goToCouponsAlertButtonTitle = NSLocalizedString("Go", comment: "Confirm button title for navigating to coupons when creating a new order")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title when showing the coupon list selector")
    }
}

struct OrderPaymentSection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EditableOrderViewModel.PaymentDataViewModel(itemsTotal: "20.00", orderTotal: "20.00")

        OrderPaymentSection(viewModel: viewModel)
            .previewLayout(.sizeThatFits)
    }
}
