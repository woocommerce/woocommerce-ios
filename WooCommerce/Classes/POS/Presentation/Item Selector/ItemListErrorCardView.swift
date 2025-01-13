import SwiftUI

struct ItemListErrorCardView: View {
    let errorState: PointOfSaleErrorState
    let buttonAction: () -> Void

    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSErrorExclamationMark(size: 48)
            .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                   height: Constants.productCardSize * scale)
            .clipped()

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(errorState.title)
                    .lineLimit(2)
                    .foregroundStyle(Color.posPrimaryText)
                    .multilineTextAlignment(.leading)
                    .font(.posBodyEmphasized)

                Text(errorState.subtitle)
                    .foregroundStyle(Color.posSecondaryText)
                    .font(.posBodyRegular)
            }
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))

            Spacer()

            Button {
                buttonAction()
            } label: {
                Text(errorState.buttonText)
            }
            .buttonStyle(POSTertiaryButtonStyle())
            .frame(maxWidth: Constants.accessoryButtonMaxWidth * scale)
            .padding(Constants.accessoryButtonPadding * (1 / scale))
        }
        .frame(maxWidth: .infinity, idealHeight: Constants.productCardSize * scale)
        .background(Color.posSecondaryBackground)
        .posItemCardBorderStyles()
    }
}

private typealias Constants = PointOfSaleItemListCardConstants

#Preview {
    ItemListErrorCardView(
        errorState: .errorOnLoadingVariationsNextPage(),
        buttonAction: {}
    )
}
