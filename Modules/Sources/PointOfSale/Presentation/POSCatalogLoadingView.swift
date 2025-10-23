import SwiftUI

struct POSCatalogLoadingView: View {
    let onExit: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center) {
                Spacer()
                ProgressView()
                    .progressViewStyle(POSProgressViewStyle())
                Spacer().frame(height: POSSpacing.large * 2)
                Text(Localization.title)
                    .font(.posHeadingBold)
                Spacer()
                VStack(spacing: POSSpacing.medium) {
                    Button {
                        onExit()
                    } label: {
                        Text(Localization.exitButtonTitle)
                            .font(.posBodySmallBold(underline: true))
                            .foregroundStyle(Color.posOnSurface)
                    }

                    Text(Localization.exitButtonDescription)
                        .font(.posCaptionRegular)
                        .foregroundStyle(Color.posOnSurfaceVariantLowest)
                }
                .padding(.bottom, POSPadding.large)
            }
            .multilineTextAlignment(.center)
            Spacer()

        }
        .background(Color.posSurface)
    }
}

#Preview {
    POSCatalogLoadingView {}
}


private extension POSCatalogLoadingView {
    struct Localization {
        static let title = NSLocalizedString(
            "pointOfSale.catalogLoadingView.title",
            value: "Syncing catalog",
            comment: "A title of a full screen view that is displayed while the POS catalog is being synced.")

        static let exitButtonTitle = NSLocalizedString(
            "pointOfSale.catalogLoadingView.exitButton.title",
            value: "Exit POS",
            comment: "A button that exits POS.")

        static let exitButtonDescription = NSLocalizedString(
            "pointOfSale.catalogLoadingView.exitButton.description",
            value: "Syncing will continue in the background.",
            comment: "A description within a full screen loading view for POS catalog.")
    }
}
