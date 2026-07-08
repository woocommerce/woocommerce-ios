import Foundation

/// Cart-specific view helper methods used only by TotalsView.
struct TotalsViewHelper {
    private let paymentViewHelper = POSPaymentViewHelper()

    enum BottomControlState: Equatable {
        case hidden
        case checkoutMethods([POSCheckoutPaymentMethod])
        case cashAndOtherMethods
        case readerAndOtherMethods
    }

    func shouldShowReconnectingMessage(readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
                                       paymentState: PointOfSalePaymentState) -> Bool {
        guard case .reconnecting = readerConnectionStatus else {
            return false
        }

        switch paymentState.activePaymentMethod {
        case .cash, .scanToPay, .markAsPaid:
            return false
        case .card:
            switch paymentState.card {
            case .idle,
                    .acceptingCard,
                    .preparingReader:
                return true
            case .validatingOrder,
                    .validatingOrderError,
                    .paymentIntentCreationError,
                    .processingPayment,
                    .cardInserted,
                    .paymentError,
                    .cardPaymentSuccessful:
                return false
            }
        }
    }

    /// Cash payment button visibility for the cart flow (adds order state guards on top of the base check).
    func shouldShowCollectCashPaymentButton(orderState: PointOfSaleOrderState,
                                            paymentState: PointOfSalePaymentState,
                                            cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus) -> Bool {
        guard orderState != .syncing else {
            return false
        }

        if case .reconnecting = cardReaderConnectionStatus {
            return false
        }

        let isZeroTotal: Bool = if case let .loaded(totals) = orderState {
            totals.orderTotalDecimal.isZero
        } else {
            false
        }

        return paymentViewHelper.shouldShowCashPaymentButton(paymentState: paymentState,
                                                             cardReaderConnectionStatus: cardReaderConnectionStatus,
                                                             isZeroTotal: isZeroTotal)
    }

    func bottomControlState(orderState: PointOfSaleOrderState,
                            paymentState: PointOfSalePaymentState,
                            cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus,
                            tapToPayAvailabilityState: POSTapToPayAvailabilityState?,
                            hasOtherPaymentMethodsAvailable: Bool,
                            isTapToPayHeroVisible: Bool,
                            isBluetoothReaderSelected: Bool) -> BottomControlState {
        if isTapToPayHeroVisible {
            return .cashAndOtherMethods
        }

        guard shouldShowCollectCashPaymentButton(orderState: orderState,
                                                 paymentState: paymentState,
                                                 cardReaderConnectionStatus: cardReaderConnectionStatus) else {
            return .hidden
        }

        let isReaderDisconnected = paymentViewHelper.shouldShowDisconnectedMessage(
            readerConnectionStatus: cardReaderConnectionStatus,
            paymentState: paymentState
        )

        switch tapToPayAvailabilityState {
        case .available:
            if isBluetoothReaderSelected || !isReaderDisconnected {
                return .cashAndOtherMethods
            }
        case .unavailable, nil:
            if hasOtherPaymentMethodsAvailable {
                return isReaderDisconnected ? .readerAndOtherMethods : .cashAndOtherMethods
            }
        case .unknown:
            break
        }

        return .checkoutMethods(checkoutPaymentMethods(tapToPayAvailabilityState: tapToPayAvailabilityState,
                                                       isReaderDisconnected: isReaderDisconnected))
    }

    private func checkoutPaymentMethods(tapToPayAvailabilityState: POSTapToPayAvailabilityState?,
                                        isReaderDisconnected: Bool) -> [POSCheckoutPaymentMethod] {
        var methods: [POSCheckoutPaymentMethod] = []
        if tapToPayAvailabilityState == .available {
            methods.append(.tapToPay)
        }
        if isReaderDisconnected {
            methods.append(.cardReader)
        }
        methods.append(.cashPayment)
        return methods
    }

    func shouldShowCardReaderInOtherPaymentMethods(bottomControlState: BottomControlState) -> Bool {
        bottomControlState != .readerAndOtherMethods
    }

    func shouldShowTotalDiscountField(cart: Cart, orderTotals: PointOfSaleOrderTotals?) -> Bool {
        let hasCoupons = cart.coupons.isNotEmpty
        let orderIsLoading = orderTotals == nil
        let hasDiscounts = orderTotals?.discountTotal != nil

        guard hasCoupons else {
            return false
        }

        return orderIsLoading || hasDiscounts
    }

    func shouldShowCustomAmountsField(cart: Cart, orderTotals: PointOfSaleOrderTotals?) -> Bool {
        let hasCustomAmounts = cart.customAmounts.isNotEmpty
        let orderIsLoading = orderTotals == nil
        let hasCustomAmountsTotal = orderTotals?.customAmountsTotal != nil

        guard hasCustomAmounts else {
            return false
        }

        return orderIsLoading || hasCustomAmountsTotal
    }
}
