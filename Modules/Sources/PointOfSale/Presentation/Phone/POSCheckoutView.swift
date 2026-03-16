import SwiftUI

struct POSCheckoutView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(POSPaymentModel.self) private var paymentModel
    @Binding var isPresented: Bool

    private let viewHelper = TotalsViewHelper()

    var body: some View {
        @Bindable var paymentModel = paymentModel
        NavigationStack {
            VStack(spacing: .zero) {
                cartItemsList
                checkoutFooter
            }
            .background(Color.posSurface)
            .navigationTitle(Localization.checkout)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isPresented = false
                    } label: {
                        HStack(spacing: POSSpacing.xSmall) {
                            Image(systemName: "chevron.left")
                            Text(Localization.back)
                        }
                    }
                }
            }
        }
        .posModal(item: $paymentModel.cardPresentPaymentAlertViewModel, onDismiss: {
            paymentModel.cardPresentPaymentAlertViewModel?.onDismiss?()
        }) { alertType in
            PointOfSaleCardPresentPaymentAlert(alertType: alertType)
                .posInteractiveDismissDisabled(alertType.isDismissDisabled)
        }
        .posModal(item: $paymentModel.cardPresentPaymentOnboardingViewContainer, onDismiss: {
            paymentModel.cancelCardPaymentsOnboarding()
        }) { factory in
            PointOfSaleCardPresentPaymentOnboardingView(viewModel: .init(
                onboardingViewContainer: factory,
                onDismissTap: {
                    paymentModel.cancelCardPaymentsOnboarding()
                }))
        }
        .fullScreenCover(isPresented: fullScreenPaymentBinding) {
            paymentFullScreenContent
        }
    }
}

// MARK: - Cart Items
private extension POSCheckoutView {
    var cartItemsList: some View {
        ScrollView {
            LazyVStack(spacing: POSSpacing.medium) {
                ForEach(posModel.cart.purchasableItems, id: \.id) { cartItem in
                    ItemRowView(
                        cartItem: cartItem,
                        showImage: .constant(true),
                        onItemRemoveTapped: nil,
                        onCancelLoading: {
                            posModel.cancelLoadingItem(id: cartItem.id)
                        }
                    )
                }

                if posModel.cart.coupons.isNotEmpty {
                    ForEach(posModel.cart.coupons, id: \.id) { couponItem in
                        CouponRowView(
                            couponItem: couponItem,
                            showImage: .constant(true),
                            onItemRemoveTapped: nil
                        )
                    }
                }
            }
            .padding(.horizontal, POSPadding.medium)
            .padding(.vertical, POSPadding.medium)
        }
    }
}

// MARK: - Checkout Footer
private extension POSCheckoutView {
    var checkoutFooter: some View {
        VStack(spacing: POSSpacing.medium) {
            Divider()
                .overlay(Color.posOutlineVariant)

            totalsSection
                .padding(.horizontal, POSPadding.medium)

            VStack(spacing: POSSpacing.small) {
                Button {
                    Task { @MainActor in
                        await paymentModel.startPayment()
                    }
                } label: {
                    Text(Localization.tapToPay)
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))

                Button {
                    Task { @MainActor in
                        await paymentModel.startCashPayment()
                    }
                } label: {
                    Text(Localization.cashPayment)
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            }
            .padding(.horizontal, POSPadding.medium)
            .padding(.bottom, POSPadding.medium)
        }
        .background(Color.posSurfaceBright)
    }

    @ViewBuilder
    var totalsSection: some View {
        switch posModel.orderState {
        case .loaded(let orderTotals):
            VStack(spacing: POSSpacing.small) {
                totalsRow(title: Localization.subtotal, value: orderTotals.cartTotal)

                if viewHelper.shouldShowTotalDiscountField(cart: posModel.cart, orderTotals: orderTotals) {
                    totalsRow(title: Localization.discount, value: orderTotals.discountTotal ?? "")
                }

                totalsRow(title: Localization.taxes, value: orderTotals.taxTotal)

                Divider()
                    .overlay(Color.posOutlineVariant)

                HStack {
                    Text(Localization.total)
                        .font(.posHeadingBold)
                    Spacer()
                    Text(orderTotals.orderTotal)
                        .font(.posHeadingBold)
                }
                .foregroundStyle(Color.posOnSurface)
            }
        case .syncing, .idle:
            VStack(spacing: POSSpacing.small) {
                Color.posOnSurfaceVariantLowest
                    .frame(height: 24)
                    .cornerRadius(POSCornerRadiusStyle.small.value)
                    .shimmering(active: true)
                Color.posOnSurfaceVariantLowest
                    .frame(height: 32)
                    .cornerRadius(POSCornerRadiusStyle.small.value)
                    .shimmering(active: true)
            }
        case .error:
            EmptyView()
        }
    }

    func totalsRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.posBodyLargeRegular())
            Spacer()
            Text(value)
                .font(.posBodyLargeRegular())
        }
        .foregroundStyle(Color.posOnSurface)
    }
}

// MARK: - Full Screen Payment States
private extension POSCheckoutView {
    var fullScreenPaymentBinding: Binding<Bool> {
        Binding(
            get: { paymentModel.paymentState.shownFullScreen },
            set: { _ in }
        )
    }

    @ViewBuilder
    var paymentFullScreenContent: some View {
        switch paymentModel.paymentState.activePaymentMethod {
        case .card:
            POSCardPaymentContentView(
                cardReaderConnectionStatus: paymentModel.cardReaderConnectionStatus,
                paymentState: paymentModel.paymentState,
                cardPresentPaymentInlineMessage: paymentModel.cardPresentPaymentInlineMessage,
                connectCardReaderAction: paymentModel.connectCardReader
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(POSPaymentViewHelper().paymentBackgroundColor(for: paymentModel.paymentState).ignoresSafeArea())
        case .cash:
            if case .loaded(let totals) = posModel.orderState {
                POSCashPaymentContentView(
                    cashPaymentState: paymentModel.paymentState.cash,
                    formattedOrderTotal: totals.orderTotal
                )
            }
        }
    }
}

// MARK: - Localization
private extension POSCheckoutView {
    enum Localization {
        static let checkout = NSLocalizedString(
            "pos.phone.checkout.title",
            value: "Checkout",
            comment: "Title for the checkout screen in phone POS"
        )
        static let back = NSLocalizedString(
            "pos.phone.checkout.back",
            value: "Back",
            comment: "Back button title on the phone POS checkout screen"
        )
        static let tapToPay = NSLocalizedString(
            "pos.phone.checkout.tapToPay",
            value: "Tap to Pay",
            comment: "Title for the Tap to Pay button on the phone POS checkout screen"
        )
        static let cashPayment = NSLocalizedString(
            "pos.phone.checkout.cashPayment",
            value: "Cash Payment",
            comment: "Title for the Cash Payment button on the phone POS checkout screen"
        )
        static let subtotal = NSLocalizedString(
            "pos.phone.checkout.subtotal",
            value: "Subtotal",
            comment: "Label for subtotal in phone POS checkout"
        )
        static let taxes = NSLocalizedString(
            "pos.phone.checkout.taxes",
            value: "Taxes",
            comment: "Label for taxes in phone POS checkout"
        )
        static let discount = NSLocalizedString(
            "pos.phone.checkout.discount",
            value: "Discount total",
            comment: "Label for discount total in phone POS checkout"
        )
        static let total = NSLocalizedString(
            "pos.phone.checkout.total",
            value: "Total",
            comment: "Label for the grand total in phone POS checkout"
        )
    }
}
