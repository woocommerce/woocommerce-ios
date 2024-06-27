import SwiftUI
import class WooFoundation.CurrencyFormatter
import Yosemite

final class TotalsViewModel: ObservableObject {
    // TODO: consider removing this and use `CardPresentPaymentEvent` instead
    enum PaymentState {
        case idle
        case acceptingCard
        case preparingReader
        case processingPayment
        case cardPaymentSuccessful

        init?(from cardPaymentEvent: CardPresentPaymentEvent) {
            switch cardPaymentEvent {
            case .idle:
                self = .idle
            case .show(.validatingOrder):
                self = .preparingReader
            case .show(.tapSwipeOrInsertCard):
                self = .acceptingCard
            case .show(.processing):
                self = .processingPayment
            case .show(.paymentSuccess):
                self = .cardPaymentSuccessful
            default:
                return nil
            }
        }
    }

    @Published private(set) var paymentState: PaymentState = .acceptingCard

    @Published private(set) var isSyncingOrder: Bool = false

    // Total amounts
    @Published private(set) var formattedCartTotalPrice: String?

    @Published var showsCardReaderSheet: Bool = false
    @Published private(set) var cardPresentPaymentEvent: CardPresentPaymentEvent = .idle
    @Published private(set) var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?

    // MARK: States for each transaction that should be cleared before starting the next transaction
    /// Order created the first time the checkout is shown for a given transaction.
    /// If the merchant goes back to the product selection screen and makes changes, this should be updated when they return to the checkout.
    @Published private var order: POSOrder?

    private var itemsInCart: [CartItem] = []
    private var allItems: [POSItem] = []

    @Published private(set) var connectionStatus: CardReaderConnectionStatus = .disconnected

    private let orderService: POSOrderServiceProtocol
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let currencyFormatter: CurrencyFormatter

    var areAmountsFullyCalculated: Bool {
        isSyncingOrder == false &&
        formattedOrderTotalTaxPrice != nil &&
        formattedOrderTotalPrice != nil
    }

    var formattedOrderTotalTaxPrice: String? {
        formattedPrice(order?.totalTax, currency: order?.currency)
    }

    var formattedOrderTotalPrice: String? {
        return formattedPrice(order?.total, currency: order?.currency)
    }

    var showRecalculateButton: Bool {
        return !areAmountsFullyCalculated && isSyncingOrder == false
    }

    init(orderService: POSOrderServiceProtocol,
         cardPresentPaymentService: CardPresentPaymentFacade,
         currencyFormatter: CurrencyFormatter) {
        self.orderService = orderService
        self.cardPresentPaymentService = cardPresentPaymentService
        self.currencyFormatter = currencyFormatter
        observeConnectedReaderForStatus()
        observeCardPresentPaymentEvents()
    }

    func startSyncingOrder(itemsInCart: [CartItem], allItems: [POSItem]) {
        Task { @MainActor in
            calculateCartTotal(cartItems: itemsInCart)
            await syncOrder(for: itemsInCart, allItems: allItems)
        }
    }

    func resetForNewTransaction() {
        order = nil
        itemsInCart = []
        allItems = []
        paymentState = .acceptingCard
    }

    @MainActor
    func onTotalsViewDisappearance() {
        cardPresentPaymentService.cancelPayment()
    }

    @MainActor
    private func syncOrder(for cartProducts: [CartItem], allItems: [POSItem]) async {
        guard isSyncingOrder == false else {
            return
        }
        isSyncingOrder = true
        let cart = cartProducts
            .map {
                POSCartItem(itemID: nil,
                            product: $0.item,
                            quantity: Decimal($0.quantity))
            }
        defer {
            isSyncingOrder = false
        }
        do {
            let order = try await orderService.syncOrder(cart: cart,
                                                         order: order,
                                                         allProducts: allItems)
            self.order = order
            isSyncingOrder = false
            // TODO: this is temporary solution
            await prepareConnectedReaderForPayment()
            DDLogInfo("🟢 [POS] Synced order: \(order)")
        } catch {
            DDLogError("🔴 [POS] Error syncing order: \(error)")
        }
    }

    /// Called when order syncing failed before and CTA is tapped to resync the order.
    func calculateAmountsTapped() {
        startSyncingOrder(itemsInCart: itemsInCart, allItems: allItems)
    }

    func cardPaymentTapped() {
        Task { @MainActor in
            await collectPayment()
        }
    }

    @MainActor
    private func collectPayment() async {
        guard let order else {
            return
        }
        do {
            let finalOrder = orderService.order(from: order)
            try await collectPayment(for: finalOrder)
        } catch {
            DDLogError("Error taking payment: \(error)")
        }
    }

    @MainActor
    private func collectPayment(for order: Order) async throws {
        let paymentResult = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth)
    }

    @MainActor
    private func prepareConnectedReaderForPayment() async {
        guard connectionStatus == .connected else {
            return
        }
        await collectPayment()
    }

    private func formattedPrice(_ price: String?, currency: String?) -> String? {
        guard let price, let currency else {
            return nil
        }
        guard let formattedPrice = currencyFormatter.formatAmount(price, with: currency) else {
            return nil
        }
        return formattedPrice
    }
}

private extension TotalsViewModel {
    func observeConnectedReaderForStatus() {
        cardPresentPaymentService.connectedReaderPublisher
            .map { connectedReader in
                connectedReader == nil ? .disconnected: .connected
            }
            .assign(to: &$connectionStatus)
    }

    func observeCardPresentPaymentEvents() {
        cardPresentPaymentService.paymentEventPublisher.assign(to: &$cardPresentPaymentEvent)
        cardPresentPaymentService.paymentEventPublisher
            .map { event -> PointOfSaleCardPresentPaymentAlertType? in
                guard case let .show(eventDetails) = event,
                      case let .alert(alertType) = eventDetails.pointOfSalePresentationStyle else {
                    return nil
                }
                return alertType
            }
            .assign(to: &$cardPresentPaymentAlertViewModel)
        cardPresentPaymentService.paymentEventPublisher
            .map { event -> PointOfSaleCardPresentPaymentMessageType? in
                guard case let .show(eventDetails) = event,
                      case let .message(messageType) = eventDetails.pointOfSalePresentationStyle else {
                    return nil
                }
                return messageType
            }
            .assign(to: &$cardPresentPaymentInlineMessage)
        cardPresentPaymentService.paymentEventPublisher.map { event in
            switch event {
            case .idle:
                return false
            case .show(let eventDetails):
                switch eventDetails.pointOfSalePresentationStyle {
                case .alert:
                    return true
                case .message, .none:
                    return false
                }
            case .showOnboarding:
                return true
            }
        }.assign(to: &$showsCardReaderSheet)
        cardPresentPaymentService.paymentEventPublisher
            .compactMap({ PaymentState(from: $0) })
            .assign(to: &$paymentState)
    }

    func calculateCartTotal(cartItems: [CartItem]) {
        formattedCartTotalPrice = { cartItems in
            let totalValue: Decimal = cartItems.reduce(0) { partialResult, cartItem in
                let itemPrice = currencyFormatter.convertToDecimal(cartItem.item.price) ?? 0
                let quantity = cartItem.quantity
                let total = itemPrice.multiplying(by: NSDecimalNumber(value: quantity)) as Decimal
                return partialResult + total
            }
            return currencyFormatter.formatAmount(totalValue)
        }(cartItems)
    }
}

struct TotalsView: View {
    @ObservedObject private var dashboardViewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel

    init(dashboardViewModel: PointOfSaleDashboardViewModel, totalsViewModel: TotalsViewModel) {
        self.dashboardViewModel = dashboardViewModel
        self.totalsViewModel = totalsViewModel
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                VStack {
                    cardReaderView
                        .font(.title)
                        .padding()
                    Spacer()
                    VStack(alignment: .leading, spacing: 32) {
                        HStack {
                            VStack(spacing: Constants.totalsVerticalSpacing) {
                                priceFieldView(title: "Subtotal",
                                               // Relies on Cart and itemsInCart
                                               formattedPrice: totalsViewModel.formattedCartTotalPrice,
                                               shimmeringActive: false,
                                               redacted: false)
                                Divider()
                                    .overlay(Color.posTotalsSeparator)
                                priceFieldView(title: "Taxes",
                                               formattedPrice:
                                                totalsViewModel.formattedOrderTotalTaxPrice,
                                               shimmeringActive: totalsViewModel.isSyncingOrder,
                                               redacted: totalsViewModel.formattedOrderTotalTaxPrice == nil || totalsViewModel.isSyncingOrder)
                                Divider()
                                    .overlay(Color.posTotalsSeparator)
                                totalPriceView(formattedPrice: totalsViewModel.formattedOrderTotalPrice,
                                               shimmeringActive: totalsViewModel.isSyncingOrder,
                                               redacted: totalsViewModel.formattedOrderTotalPrice == nil || totalsViewModel.isSyncingOrder)
                            }
                            .padding()
                            .frame(idealWidth: Constants.pricesIdealWidth)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.defaultBorderLineCornerRadius)
                                .stroke(Color.posTotalsSeparator, lineWidth: Constants.defaultBorderLineWidth)
                        )
                        if totalsViewModel.showRecalculateButton {
                            Button("Calculate amounts") {
                                // Relies on syncing the order
                                totalsViewModel.calculateAmountsTapped()
                            }
                        }
                    }
                    .padding(Constants.totalsPadding)
                }
                .background(
                    LinearGradient(gradient: Gradient(stops: gradientStops),
                                   startPoint: .top,
                                   endPoint: .bottom)
                )
                paymentsActionButtons
                    .padding()
            }
        }
        .onDisappear {
            // Relies on CardPresentService
            totalsViewModel.onTotalsViewDisappearance()
        }
        .sheet(isPresented: $totalsViewModel.showsCardReaderSheet, content: {
            // Might be the only way unless we make the type conform to `Identifiable`
            if let alertType = totalsViewModel.cardPresentPaymentAlertViewModel {
                PointOfSaleCardPresentPaymentAlert(alertType: alertType)
            } else {
                switch totalsViewModel.cardPresentPaymentEvent {
                case .idle,
                        .show, // handled above
                        .showOnboarding:
                    Text(totalsViewModel.cardPresentPaymentEvent.temporaryEventDescription)
                }
            }
        })
    }

    private var gradientStops: [Gradient.Stop] {
        // Relies on CardPresentService
        if totalsViewModel.paymentState == .cardPaymentSuccessful {
            return [
                Gradient.Stop(color: Color.clear, location: 0.0),
                Gradient.Stop(color: Color.posTotalsGradientGreen, location: 1.0)
            ]
        }
        else {
            return [
                Gradient.Stop(color: Color.clear, location: 0.0),
                Gradient.Stop(color: Color.posTotalsGradientPurple, location: 1.0)
            ]
        }
    }

    private var paymentButtonsDisabled: Bool {
        return !totalsViewModel.areAmountsFullyCalculated
    }
}

private extension TotalsView {
    private var newTransactionButton: some View {
        Button(action: {
            dashboardViewModel.startNewTransaction()
        }, label: {
            HStack(spacing: Constants.newTransactionButtonSpacing) {
                Spacer()
                Image(uiImage: .posNewTransactionImage)
                Text("New transaction")
                    .font(Constants.newTransactionButtonFont)
                Spacer()
            }
        })
        .padding(Constants.newTransactionButtonPadding)
        .foregroundColor(Color.primaryText)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.defaultBorderLineCornerRadius)
                .stroke(Color.primaryText, lineWidth: Constants.defaultBorderLineWidth)
        )
    }

    @ViewBuilder
    private var paymentsActionButtons: some View {
        if totalsViewModel.paymentState == .cardPaymentSuccessful {
            newTransactionButton
        }
        else {
            EmptyView()
        }
    }

    @ViewBuilder private var cardReaderView: some View {
        switch totalsViewModel.connectionStatus {
        case .connected:
            if let inlinePaymentMessage = totalsViewModel.cardPresentPaymentInlineMessage {
                PointOfSaleCardPresentPaymentInLineMessage(messageType: inlinePaymentMessage)
            } else {
                Text("Reader connected")
                Button(action: totalsViewModel.cardPaymentTapped) {
                    Text("Collect Payment")
                }
            }
        case .disconnected:
            Text("Reader disconnected")
            Button(action: totalsViewModel.cardPaymentTapped) {
                Text("Collect Payment")
            }
        }
    }

    @ViewBuilder func priceFieldView(title: String, formattedPrice: String?, shimmeringActive: Bool, redacted: Bool) -> some View {
        HStack(alignment: .top, spacing: .zero) {
            Text(title)
                .font(Constants.subtotalTitleFont)
            Spacer()
            Text(formattedPrice ?? "-----")
                .font(Constants.subtotalAmountFont)
                .redacted(reason: redacted ? [.placeholder] : [])
                .shimmering(active: shimmeringActive)
        }
        .foregroundColor(Color.primaryText)
    }

    @ViewBuilder func totalPriceView(formattedPrice: String?, shimmeringActive: Bool, redacted: Bool) -> some View {
        HStack(alignment: .top, spacing: .zero) {
            Text("Total")
                .font(Constants.totalTitleFont)
                .fontWeight(.semibold)
            Spacer()
            Text(formattedPrice ?? "-----")
                .font(Constants.totalAmountFont)
                .redacted(reason: redacted ? [.placeholder] : [])
                .shimmering(active: shimmeringActive)
        }
        .foregroundColor(Color.primaryText)
    }
}

private extension TotalsView {
    enum Constants {
        static let pricesIdealWidth: CGFloat = 380
        static let defaultBorderLineWidth: CGFloat = 1
        static let defaultBorderLineCornerRadius: CGFloat = 8

        static let totalsVerticalSpacing: CGFloat = 10
        static let totalsPadding: CGFloat = 50
        static let subtotalTitleFont: Font = Font.system(size: 20)
        static let subtotalAmountFont: Font = Font.system(size: 20)
        static let totalTitleFont: Font = Font.system(size: 21, weight: .semibold)
        static let totalAmountFont: Font = Font.system(size: 40, weight: .bold)

        static let newTransactionButtonSpacing: CGFloat = 20
        static let newTransactionButtonPadding: CGFloat = 16
        static let newTransactionButtonFont: Font = Font.system(size: 32, weight: .medium)
    }
}

fileprivate extension CardPresentPaymentEvent {
    var temporaryEventDescription: String {
        switch self {
        case .idle:
            return "Idle"
        case .show:
            return "Event"
        case .showOnboarding(let onboardingViewModel):
            return "Onboarding: \(onboardingViewModel.state.reasonForAnalytics)" // This will only show the initial onboarding state
        }
    }
}

//#if DEBUG
//#Preview {
//    TotalsView(viewModel: .init(itemProvider: POSItemProviderPreview(),
//                                cardPresentPaymentService: CardPresentPaymentPreviewService(),
//                                orderService: POSOrderPreviewService()))
//}
//#endif
