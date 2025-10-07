import SwiftUI

struct PointOfSaleUnsupportedWidthView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .center, spacing: PointOfSaleItemListErrorLayout.headerSpacing) {
                Image(systemName: "ipad.landscape.badge.exclamationmark")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.posAlert, Color.posOnSurface)
                    .font(.system(size: Constants.iconSize))
                    .accessibilityHidden(true)
                    .renderedIf(!dynamicTypeSize.isAccessibilitySize)

                Group {
                    Text(Localization.title)
                        .font(.posBodyLargeBold)
                        .accessibilityAddTraits(.isHeader)
                    Text(Localization.detail)
                        .font(.posBodyLargeRegular())
                }
                .foregroundStyle(Color.posOnSurface)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, POSPadding.medium)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private extension PointOfSaleUnsupportedWidthView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.unsupportedWidth.title",
            value: "Point of Sale is not supported in this screen width.",
            comment: "An error shown when the Point of Sale is used in iOS split view, but with not enough " +
            "horizontal space.")

        static let detail = NSLocalizedString(
            "pos.unsupportedWidth.detail",
            value: "Please adjust your screen split to give Point of Sale more space.",
            comment: "Detail for an error shown when the Point of Sale is used in iOS split view, but with not " +
            "enough horizontal space.")
    }

    enum Constants {
        static let iconSize: CGFloat = 64
    }
}

#Preview {
    PointOfSaleUnsupportedWidthView()
}
