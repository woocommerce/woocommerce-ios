import SwiftUI

import Combine

final class TotalsViewModel: ObservableObject {
    enum CashPaymentState {
        case idle
        case inProgress
        case confirmed
    }

    @Published private(set) var paymentState: PointOfSaleDashboardViewModel.PaymentState = .acceptingCard

    @Published private var cashPaymentState: CashPaymentState = .idle

    private let cardPresentPaymentEvent: AnyPublisher<CardPresentPaymentEvent, Never>

    // TODO: update init to only take in the event publisher
    init(viewModel: PointOfSaleDashboardViewModel) {
        self.cardPresentPaymentEvent = viewModel.$cardPresentPaymentEvent.eraseToAnyPublisher()
        observeForPaymentState()
    }

    func takeCashPayment() {
        cashPaymentState = .inProgress
    }

    // TODO: update to async to update order status remotely
    func confirmCashPayment() {
        cashPaymentState = .confirmed
    }

    func cancelCashPayment() {
        cashPaymentState = .idle
    }

    private func observeForPaymentState() {
        Publishers.CombineLatest($cashPaymentState, cardPresentPaymentEvent)
            .compactMap { cashPaymentState, cardPresentPaymentEvent in
                if case .showPaymentSuccess = cardPresentPaymentEvent {
                    return .cardPaymentSuccessful
                }

                if cashPaymentState == .confirmed {
                    return .cashPaymentSuccessful
                }

                // TODO: update to acceptingCard when reader is ready for payment
                if case .readyForPayment = cardPresentPaymentEvent {
                    return .acceptingCard
                }

                if case let .showReaderMessage(message) = cardPresentPaymentEvent {
                    return .processingCard(readerMessage: message)
                }

                if cashPaymentState == .inProgress {
                    return .acceptingCash
                }

                return nil
            }
            .assign(to: &$paymentState)
    }
}

struct TotalsView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
        self.totalsViewModel = .init(viewModel: viewModel)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 32) {
                    HStack(spacing: 40) {
                        priceFieldView(title: "Subtotal", formattedPrice: viewModel.formattedCartTotalPrice ?? "-")
                        priceFieldView(title: "Taxes", formattedPrice: viewModel.formattedOrderTotalTaxPrice ?? "-")
                    }
                    totalPriceView(formattedPrice: viewModel.formattedOrderTotalPrice ?? "-")
                }
                .padding()
                Spacer()
                cardReaderView
                    .padding()
                paymentsView
                    .padding()
                Spacer()
                paymentsActionButtons
                    .padding()
            }
            Spacer()
        }
        .sheet(isPresented: $viewModel.showsCreatingOrderSheet) {
            ProgressView {
                Text("Creating $15 test order")
            }
        }
    }
}

private extension TotalsView {
    @ViewBuilder func tapInsertCardView(readerMessage: String?) -> some View {
        VStack {
            // TODO: update image based on M1 design
            Image(uiImage: .cardPresentImage)
            if let readerMessage {
                Text(readerMessage)
                    .font(.footnote)
            }
        }
    }

    private var takeCashView: some View {
        Text("Take cash payment")
    }

    private var paymentSuccessfulView: some View {
        Text("Payment successful")
    }

    @ViewBuilder
    private var paymentsTextView: some View {
        switch totalsViewModel.paymentState {
        case .acceptingCard:
            tapInsertCardView(readerMessage: nil)
        case let .processingCard(readerMessage):
            tapInsertCardView(readerMessage: readerMessage)
        case .cardPaymentSuccessful:
            paymentSuccessfulView
        case .acceptingCash:
            takeCashView
        case .cashPaymentSuccessful:
            paymentSuccessfulView
        }
    }

    @ViewBuilder
    private var paymentsIconView: some View {
        switch totalsViewModel.paymentState {
        case .acceptingCard:
            EmptyView()
        case .processingCard:
            EmptyView()
        case .cardPaymentSuccessful:
            EmptyView()
        case .acceptingCash:
            EmptyView()
        case .cashPaymentSuccessful:
            EmptyView()
        }
    }

    @ViewBuilder
    private var paymentsView: some View {
        VStack {
            paymentsTextView
                .font(.title)
            paymentsIconView
        }
    }

    private var cashPaymentButton: some View {
        Button("Cash payment") {
            totalsViewModel.takeCashPayment()
        }
        .padding(30)
        .font(.title)
        .foregroundColor(Color.primaryText)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primaryText, lineWidth: 2)
        )
    }

    private var confirmCashPaymentButton: some View {
        Button("Confirm") {
            totalsViewModel.confirmCashPayment()
        }
        .padding(30)
        .font(.title)
        .foregroundColor(Color.primaryText)
        .background(Color.secondaryBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primaryText, lineWidth: 2)
        )
    }

    private var cancelCashPaymentButton: some View {
        Button("Cancel") {
            totalsViewModel.cancelCashPayment()
        }
        .padding(30)
        .font(.title)
        .foregroundColor(Color.primaryText)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primaryText, lineWidth: 2)
        )
    }

    private var provideReceiptButton: some View {
        Button("Provide receipt") {}
        .padding(30)
        .font(.title)
        .foregroundColor(Color.primaryText)
        .background(Color.secondaryBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primaryText, lineWidth: 2)
        )
    }

    private var newTransactionButton: some View {
        Button("New transaction") {
            // TODO: reset POS/payment state
        }
        .padding(30)
        .font(.title)
        .foregroundColor(Color.primaryText)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primaryText, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var paymentsActionButtons: some View {
        VStack {
            switch totalsViewModel.paymentState {
            case .acceptingCard:
                HStack {
                    cashPaymentButton
                }
            case .processingCard:
                EmptyView()
            case .cardPaymentSuccessful, .cashPaymentSuccessful:
                HStack {
                    provideReceiptButton
                    Spacer()
                    newTransactionButton
                }
            case .acceptingCash:
                HStack {
                    confirmCashPaymentButton
                    cancelCashPaymentButton
                }
            }
        }
    }

    @ViewBuilder private var cardReaderView: some View {
        switch viewModel.cardReaderConnectionViewModel.connectionStatus {
        case .connected:
            Text("Tap, swipe, or insert card to pay")
        case .disconnected:
            Button(action: viewModel.cardPaymentTapped) {
                Text("Collect Payment")
            }
        }
    }

    @ViewBuilder func priceFieldView(title: String, formattedPrice: String) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(title)
            Text(formattedPrice)
                .font(.title2)
                .fontWeight(.medium)
        }
        .foregroundColor(Color.primaryText)
    }

    @ViewBuilder func totalPriceView(formattedPrice: String) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text("Total")
                .font(.title2)
                .fontWeight(.medium)
            Text(formattedPrice)
                .font(.largeTitle)
                .bold()
        }
        .foregroundColor(Color.primaryText)
    }
}

#if DEBUG
#Preview {
    TotalsView(viewModel: .init(items: [],
                                cardPresentPaymentService: CardPresentPaymentPreviewService()))
}
#endif
