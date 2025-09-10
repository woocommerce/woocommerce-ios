import SwiftUI

struct ItemListErrorCardView: View {
    let errorState: PointOfSaleErrorState
    let buttonAction: () -> Void

    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        ViewThatFits {
            largerView
            compactView
        }
        .frame(maxWidth: .infinity, idealHeight: Constants.productCardSize * scale)
        .background(Constants.backgroundColor)
        .posItemCardBorderStyles()
    }

    @ViewBuilder
    private var largerView: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSErrorExclamationMark(size: .small)
                .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                       height: Constants.productCardSize * scale)
            errorLabels
                .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
                .padding(.vertical, Constants.verticalTextPadding * (1 / scale))
            Spacer()
            button
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                .fixedSize(horizontal: true, vertical: false)
                .padding(Constants.accessoryButtonPadding * (1 / scale))
        }
    }

    @ViewBuilder
    private var compactView: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            POSErrorExclamationMark(size: .small)
            errorLabels
            button
                .buttonStyle(POSOutlinedButtonStyle(size: .extraSmall))
        }
        .padding(.horizontal, POSSpacing.medium * (1 / scale))
        .padding(.vertical, POSSpacing.medium * (1 / scale))
    }

    @ViewBuilder
    private var errorImage: some View {
        POSErrorExclamationMark(size: .small)
            .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                   height: Constants.productCardSize * scale)
    }

    @ViewBuilder
    private var errorLabels: some View {
        VStack(alignment: .leading, spacing: Constants.textSpacing) {
            Text(errorState.title)
                .lineLimit(2)
                .foregroundStyle(Color.posOnSurface)
                .multilineTextAlignment(.leading)
                .font(Constants.itemTitleFont)

            Text(errorState.subtitle)
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .font(Constants.itemDetailFont)
        }
    }

    @ViewBuilder
    private var button: some View {
        Button {
            buttonAction()
        } label: {
            Text(errorState.buttonText)
                .font(Constants.itemTitleFont)
        }
    }
}

private typealias Constants = PointOfSaleItemListCardConstants

#Preview {
    ItemListErrorCardView(
        errorState: .errorOnLoadingVariationsNextPage(),
        buttonAction: {}
    )
}
