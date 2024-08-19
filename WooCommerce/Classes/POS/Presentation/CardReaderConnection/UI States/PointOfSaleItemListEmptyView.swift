import SwiftUI

struct PointOfSaleItemListEmptyView: View {
    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleItemListErrorLayout.headerSpacing) {
            POSHeaderTitleView(foregroundColor: .posIconGrayi3)
            Spacer()
            Image(systemName: Constants.iconSystemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundColor(.posIconGrayi3)
                .scaleEffect(x: -1, y: 1)
                .accessibilityHidden(true)
            Text(Localization.emptyProductsTitle)
                .foregroundStyle(Color.posIconGrayi3)
                .font(.posTitleEmphasized)
            Text(Localization.emptyProductsSubtitle)
                .foregroundStyle(Color.posIconGrayi3)
                .font(.posBodyRegular)
                .padding([.leading, .trailing])
            Text(Localization.emptyProductsHint)
                .foregroundStyle(Color.posIconGrayi3)
                .font(.posBodyRegular)
                .padding([.leading, .trailing])
            Spacer()
        }
    }
}

private extension PointOfSaleItemListEmptyView {
    enum Constants {
        static let iconSystemName: String = "plus.magnifyingglass"
        static let iconSize: CGFloat = 100
    }
    enum Localization {
        static let emptyProductsTitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyProductsTitle",
            value: "No supported products found",
            comment: "Text appearing on screen when there are no products to load."
        )
        static let emptyProductsSubtitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyProductsSubtitle",
            value: "POS currently only supports simple products.",
            comment: "Subtitle text on screen when there are no products to load."
        )
        static let emptyProductsHint = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyProductsHint",
            value: "To add one, exit POS and go to Products",
            comment: "Text hinting the merchant to create a product."
        )
    }
}
