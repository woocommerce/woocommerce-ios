import SwiftUI

struct POSListInlineErrorView: View {
    let errorState: PointOfSaleErrorState
    let buttonAction: @Sendable () async -> Void


    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var isLoading: Bool = false

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
            POSErrorXMark(size: .small)
                .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                       height: Constants.productCardSize * scale)
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
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))

            Spacer()

            button
                .buttonStyle(POSOutlinedButtonStyle(size: .normal, isLoading: isLoading))
                .fixedSize(horizontal: true, vertical: false)
                .padding(Constants.accessoryButtonPadding * (1 / scale))
        }
    }

    @ViewBuilder
    private var compactView: some View {
        HStack(spacing: POSSpacing.small) {
            POSErrorXMark(size: .small)
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: Constants.textSpacing) {
                    Text(errorState.title)
                        .lineLimit(2)
                        .foregroundStyle(Color.posOnSurface)
                        .multilineTextAlignment(.leading)
                        .font(POSFontStyle.posBodyMediumBold)
                    Text(errorState.subtitle)
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                        .font(POSFontStyle.posBodyMediumRegular())
                }
                Spacer()
                button
                    .buttonStyle(POSOutlinedButtonStyle(size: .extraSmall, isLoading: isLoading))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, POSSpacing.medium * (1 / scale))
        .padding(.vertical, POSSpacing.medium * (1 / scale))
    }

    @ViewBuilder
    private var button: some View {
        Button {
            Task { @MainActor in
                isLoading = true
                await buttonAction()
                isLoading = false
            }
        } label: {
            Text(errorState.buttonText)
                .font(Constants.itemTitleFont)
        }
    }
}

private typealias Constants = PointOfSaleItemListCardConstants

#Preview {
    POSListInlineErrorView(
        errorState: .errorOnLoadingVariationsNextPage(),
        buttonAction: {}
    )
}
