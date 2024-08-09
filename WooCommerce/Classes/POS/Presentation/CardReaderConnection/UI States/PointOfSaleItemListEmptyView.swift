import SwiftUI

struct PointOfSaleItemListEmptyView: View {
    var body: some View {
        VStack(alignment: .center, spacing: Constants.headerSpacing) {
            Text(Localization.productTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Constants.headerPadding)
                .font(Constants.titleFont)
                .foregroundColor(Color.posPrimaryTexti3)
            Spacer()
            Image(uiImage: .searchImage)
            Text(Localization.emptyProductsTitle)
                .foregroundStyle(Color.posPrimaryTexti3)
                .font(.posTitle)
                .bold()
            Text(Localization.emptyProductsSubtitle)
                .foregroundStyle(Color.posPrimaryTexti3)
                .font(.posBody)
                .padding([.leading, .trailing])
            Text(Localization.emptyProductsHint)
                .foregroundStyle(Color.posPrimaryTexti3)
                .font(.posBody)
                .padding([.leading, .trailing])
            Spacer()
        }
    }
}

private extension PointOfSaleItemListEmptyView {
    enum Constants {
        static let headerPadding: CGFloat = 8
        static let headerSpacing: CGFloat = 16
        static let titleFont: Font = .system(size: 40, weight: .bold, design: .default)
    }
    enum Localization {
        static let productTitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.productTitle",
            value: "Products",
            comment: "Title for the Point of Sale screen"
        )
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
