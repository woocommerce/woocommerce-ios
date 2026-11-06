import SwiftUI

struct POSListInlineErrorView: View {
    let errorState: PointOfSaleErrorState
    let buttonAction: @Sendable () async -> Void


    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.posMetrics) private var metrics
    @State private var isLoading: Bool = false

    var body: some View {
        ViewThatFits {
            largerView
            compactView
        }
        .frame(maxWidth: .infinity, idealHeight: metrics.productCardSize * scale)
        .background(Constants.backgroundColor)
        .posItemCardBorderStyles()
    }

    @ViewBuilder
    private var largerView: some View {
        HStack(spacing: metrics.spacing.none) {
            POSErrorXMark(size: .small)
                .frame(width: min(metrics.productCardSize * scale, metrics.productCardSize * Constants.maximumCardSizeMultiplier),
                       height: metrics.productCardSize * scale)
            VStack(alignment: .leading, spacing: metrics.spacing.xSmall) {
                Text(errorState.title)
                    .lineLimit(2)
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)

                Text(errorState.subtitle)
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .font(Constants.itemDetailFont)
            }
            .padding(.horizontal, metrics.padding.medium * (1 / scale))
            .padding(.vertical, metrics.padding.small * (1 / scale))

            Spacer()

            button
                .buttonStyle(POSOutlinedButtonStyle(size: .normal, isLoading: isLoading))
                .fixedSize(horizontal: true, vertical: false)
                .padding(metrics.padding.medium * (1 / scale))
        }
    }

    @ViewBuilder
    private var compactView: some View {
        HStack(spacing: metrics.spacing.small) {
            POSErrorXMark(size: .small)
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: metrics.spacing.xSmall) {
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
        .padding(.horizontal, metrics.padding.medium * (1 / scale))
        .padding(.vertical, metrics.padding.medium * (1 / scale))
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
