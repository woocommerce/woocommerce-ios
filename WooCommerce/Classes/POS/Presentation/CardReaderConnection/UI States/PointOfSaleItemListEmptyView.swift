import SwiftUI

struct PointOfSaleItemListEmptyView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Products")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .font(.system(size: 40, weight: .bold, design: .default))
                .foregroundColor(Color.posPrimaryTexti3)
            Spacer()
            Image(uiImage: .searchImage)
            Text(Constants.emptyProductsTitle)
                .foregroundStyle(Color.posPrimaryTexti3)
                .font(.posTitle)
                .bold()
            Text(Constants.emptyProductsSubtitle)
                .foregroundStyle(Color.posPrimaryTexti3)
                .font(.posBody)
                .padding([.leading, .trailing])
            Text(Constants.emptyProductsHint)
                .foregroundStyle(Color.posPrimaryTexti3)
                .font(.posBody)
                .padding([.leading, .trailing])
            Spacer()
        }
    }
}

private extension PointOfSaleItemListEmptyView {
    enum Constants {
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
