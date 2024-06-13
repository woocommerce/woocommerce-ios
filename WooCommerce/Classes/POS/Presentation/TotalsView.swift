import SwiftUI

struct TotalsView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    @State var paymentState: PointOfSaleDashboardViewModel.PaymentState = .acceptingCard

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 32) {
                    HStack(spacing: 40) {
                        Spacer()
                        priceFieldView(title: "Subtotal", formattedPrice: viewModel.formattedCartTotalPrice, shimmeringActive: false)
                        Text("+")
                        priceFieldView(title: "Taxes", formattedPrice: viewModel.formattedOrderTotalTaxPrice, shimmeringActive: viewModel.isSyncingOrder)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        totalPriceView(formattedPrice: viewModel.formattedOrderTotalPrice)
                        Spacer()
                    }
                    if viewModel.showRecalculateButton {
                        Button("Calculate amounts") {
                            viewModel.recalculateAmounts()
                        }
                    }
                    Divider()
                }
                .padding()
                Spacer()
                cardReaderView
                    .disabled(!viewModel.areAmountsFullyCalculated)
                    .padding()
                paymentsView
                    .padding()
                Spacer()
                paymentsActionButtons
                    .disabled(paymentButtonsDisabled)
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

    private var paymentButtonsDisabled: Bool {
        return !viewModel.areAmountsFullyCalculated
    }
}

private extension TotalsView {
    private var tapInsertCardView: some View {
        Text("Tap or insert card to pay")
    }

    private var paymentSuccessfulView: some View {
        Text("Payment successful")
    }

    @ViewBuilder
    private var paymentsTextView: some View {
        switch paymentState {
        case .acceptingCard:
            tapInsertCardView
        case .processingCard:
            tapInsertCardView
        case .cardPaymentSuccessful:
            paymentSuccessfulView
        }
    }

    @ViewBuilder
    private var paymentsIconView: some View {
        switch paymentState {
        case .acceptingCard:
            EmptyView()
        case .processingCard:
            EmptyView()
        case .cardPaymentSuccessful:
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
            paymentState = .acceptingCard
            viewModel.startNewTransaction()
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
            switch paymentState {
            case .acceptingCard:
                EmptyView()
            case .processingCard:
                EmptyView()
            case .cardPaymentSuccessful:
                HStack {
                    provideReceiptButton
                    Spacer()
                    newTransactionButton
                }
            }
        }
    }

    @ViewBuilder private var cardReaderView: some View {
        switch viewModel.cardReaderConnectionViewModel.connectionStatus {
        case .connected:
            Text("Card reader connected placeholder view")
        case .disconnected:
            Button(action: viewModel.cardPaymentTapped) {
                Text("Collect Payment")
            }
        }
    }

    @ViewBuilder func priceFieldView(title: String, formattedPrice: String?, shimmeringActive: Bool) -> some View {
        VStack(alignment: .center, spacing: .zero) {
            Text(title)
            Text(formattedPrice ?? "-----")
                .font(.title2)
                .fontWeight(.medium)
                .redacted(reason: formattedPrice == nil ? [.placeholder] : [])
                                .shimmering(active: shimmeringActive)
        }
        .foregroundColor(Color.primaryText)
    }

    @ViewBuilder func totalPriceView(formattedPrice: String?) -> some View {
        VStack(alignment: .center, spacing: .zero) {
            Text("Total")
                .font(.title2)
                .fontWeight(.medium)
            Text(formattedPrice ?? "-----")
                .font(.largeTitle)
                .bold()
                .redacted(reason: formattedPrice == nil ? [.placeholder] : [])
                .shimmering(active: viewModel.isSyncingOrder)
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
