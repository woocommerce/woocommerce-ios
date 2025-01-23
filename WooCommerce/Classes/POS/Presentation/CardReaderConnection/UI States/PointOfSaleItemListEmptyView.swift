import SwiftUI

struct PointOfSaleItemListEmptyView: View {
    private let baseItem: ItemListBaseItem

    init(base: ItemListBaseItem) {
        self.baseItem = base
    }

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleItemListErrorLayout.headerSpacing) {
            Spacer()
            Image(decorative: PointOfSaleAssets.magnifierNotFound.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundColor(.posSecondaryText)
            Text(title)
                .foregroundStyle(Color.posSecondaryText)
                .font(.posTitleEmphasized)
            Text(subtitle)
                .foregroundStyle(Color.posSecondaryText)
                .font(.posBodyRegular)
                .padding([.leading, .trailing])
            Text(hint)
                .foregroundStyle(Color.posSecondaryText)
                .font(.posBodyRegular)
                .padding([.leading, .trailing])
            Spacer()
        }
    }
}

private extension PointOfSaleItemListEmptyView {
    var title: String {
        switch baseItem {
        case .root:
            return Localization.emptyProductsTitle
        case .parent(.variableParentProduct):
            return Localization.emptyVariableParentProductTitle
        default:
            assertionFailure("No title defined for \(baseItem)")
            return Localization.emptyProductsTitle
        }
    }

    var subtitle: String {
        switch baseItem {
        case .root:
            return Localization.emptyProductsSubtitle
        case .parent(.variableParentProduct):
            return Localization.emptyVariableParentProductSubtitle
        default:
            assertionFailure("No subtitle defined for \(baseItem)")
            return Localization.emptyProductsTitle
        }
    }

    var hint: String {
        switch baseItem {
        case .root:
            return Localization.emptyProductsHint
        case .parent(.variableParentProduct):
            return Localization.emptyVariableParentProductHint
        default:
            assertionFailure("No hint defined for \(baseItem)")
            return Localization.emptyProductsTitle
        }
    }

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

        static let emptyVariableParentProductTitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyVariableParentProductTitle",
            value: "No supported variations found.",
            comment: "Text appearing on screen when there are no variations to load."
        )
        static let emptyVariableParentProductSubtitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyVariableParentProductSubtitle",
            value: "POS only supports enabled, non-downloadable variations.",
            comment: "Subtitle text on screen when there are no products to load."
        )
        static let emptyVariableParentProductHint = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyVariableParentProductHint",
            value: "To add one, exit POS and edit this product in the Products tab.",
            comment: "Text hinting the merchant to create a product."
        )
    }
}
