import SwiftUI

struct CardPresentPaymentsModalView: View {
    let viewModel: WrappedCardPresentPaymentsModalViewModel

    var body: some View {
        VStack {
            Text(viewModel.topTitle)
                .font(.headline)
                .padding(.top)
                .foregroundColor(.primary)

            if let topSubtitle = viewModel.topSubtitle {
                Text(topSubtitle)
                    .font(.subheadline)
                    .padding(.top, 2)
                    .foregroundColor(.secondary)
            }

            Image(uiImage: viewModel.image)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(.top, 10)

            if let bottomTitle = viewModel.bottomTitle {
                Text(bottomTitle)
                    .font(.headline)
                    .padding(.top, 10)
                    .foregroundColor(.primary)
            }

            if let bottomSubtitle = viewModel.bottomSubtitle {
                Text(bottomSubtitle)
                    .font(.subheadline)
                    .padding(.top, 2)
                    .padding(.bottom)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    let viewModel = WrappedCardPresentPaymentsModalViewModel(from: CardPresentModalProcessing(
        name: "Tom Jones",
        amount: "$42.00",
        transactionType: .collectPayment))
    return CardPresentPaymentsModalView(viewModel: viewModel)
}
