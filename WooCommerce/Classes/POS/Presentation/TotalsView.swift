import SwiftUI

struct TotalsView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                VStack {
                    cardReaderView
                        .font(.title)
                        .padding()
                    // Temporarily removed because the CardReaderView is doing this job right now.
    //                paymentsView
    //                    .padding()
                    VStack(alignment: .leading, spacing: 32) {
                        Spacer()
                        HStack {
                            VStack(spacing: 10) {
                                priceFieldView(title: "Subtotal", formattedPrice: viewModel.formattedCartTotalPrice, shimmeringActive: false)
                                Divider()
                                    .overlay(Color.posTotalsSeparator)
                                priceFieldView(title: "Taxes", formattedPrice: viewModel.formattedOrderTotalTaxPrice, shimmeringActive: viewModel.isSyncingOrder)
                                Divider()
                                    .overlay(Color.posTotalsSeparator)
                                totalPriceView(formattedPrice: viewModel.formattedOrderTotalPrice)
                            }
                            .padding()
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.posTotalsSeparator, lineWidth: 1)
                        )
                        if viewModel.showRecalculateButton {
                            Button("Calculate amounts") {
                                viewModel.calculateAmountsTapped()
                            }
                        }
                    }
                    .padding(50)
                }
                .background(
                    LinearGradient(gradient: Gradient(stops: [
                        Gradient.Stop(color: Color.clear, location: 0.0),
                        Gradient.Stop(color: Color.posTotalsGradientPurple, location: 1.0)
                    ]),
                                   startPoint: .top,
                                   endPoint: .bottom)
                )
                paymentsActionButtons
                    .padding()
            }
            Spacer()
        }
        .onDisappear {
            viewModel.onTotalsViewDisappearance()
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
        switch viewModel.paymentState {
        case .acceptingCard:
            tapInsertCardView
        case .processingCard:
            tapInsertCardView
        case .cardPaymentSuccessful:
            paymentSuccessfulView
        }
    }

    @ViewBuilder
    private var paymentsView: some View {
        VStack {
            paymentsTextView
                .font(.title)
        }
    }

    private var newTransactionButton: some View {
        Button("New transaction") {
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
        if viewModel.paymentState == .cardPaymentSuccessful {
            newTransactionButton
        }
        else {
            EmptyView()
        }
    }

    @ViewBuilder private var cardReaderView: some View {
        switch viewModel.cardReaderConnectionViewModel.connectionStatus {
        case .connected:
            if let inlinePaymentMessage = viewModel.cardPresentPaymentInlineMessage {
                PointOfSaleCardPresentPaymentInLineMessage(messageType: inlinePaymentMessage)
            } else {
                Text("Reader connected")
                Button(action: viewModel.cardPaymentTapped) {
                    Text("Collect Payment")
                }
            }
        case .disconnected:
            Text("Reader disconnected")
            Button(action: viewModel.cardPaymentTapped) {
                Text("Collect Payment")
            }
        }
    }

    @ViewBuilder func priceFieldView(title: String, formattedPrice: String?, shimmeringActive: Bool) -> some View {
        HStack(alignment: .center, spacing: .zero) {
            Text(title)
                .font(Font.system(size: 20))
            Spacer()
            Text(formattedPrice ?? "-----")
                .font(Font.system(size: 20))
                .redacted(reason: formattedPrice == nil ? [.placeholder] : [])
                .shimmering(active: shimmeringActive)
        }
        .foregroundColor(Color.primaryText)
    }

    @ViewBuilder func totalPriceView(formattedPrice: String?) -> some View {
        HStack(alignment: .center, spacing: .zero) {
            Text("Total")
                .font(Font.system(size: 21))
                .fontWeight(.semibold)
            Spacer()
            Text(formattedPrice ?? "-----")
                .font(Font.system(size: 40))
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
                                cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                orderService: POSOrderPreviewService()))
}
#endif
