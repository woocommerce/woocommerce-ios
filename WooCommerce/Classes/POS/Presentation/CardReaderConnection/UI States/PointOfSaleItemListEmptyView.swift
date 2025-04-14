import SwiftUI

struct PointOfSaleItemListEmptyView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    private let viewModel: PointOfSaleItemListEmptyViewModel

    private let onAction: (() -> Void)?

    @State private var viewWidth: CGFloat = 0

    private var shouldShowErrorIcon: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.enableCouponsInPointOfSale)
    }

    init(viewModel: PointOfSaleItemListEmptyViewModel, onAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onAction = onAction
    }

    var body: some View {
        ScrollableVStack {
            Spacer()
            VStack(alignment: .center, spacing: POSSpacing.none) {
                if shouldShowErrorIcon {
                    POSErrorExclamationMark(size: .large)
                } else {
                    Image(decorative: PointOfSaleAssets.magnifierNotFound.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Constants.iconSize, height: Constants.iconSize)
                        .foregroundColor(.posOnSurfaceVariantHighest)
                        .renderedIf(!dynamicTypeSize.isAccessibilitySize)
                }

                Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing)

                Text(viewModel.title)
                    .accessibilityAddTraits(.isHeader)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posHeadingBold)

                Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.textSpacing)

                Text(viewModel.subtitle)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posBodyLargeRegular())
                    .padding([.leading, .trailing])

                if let hint = viewModel.hint {
                    Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.textSpacing)
                    Text(hint)
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                        .font(.posBodyLargeRegular())
                        .padding([.leading, .trailing])
                }

                Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing)

                if let onAction, let buttonTitle = viewModel.buttonTitle {
                    Button(action: {
                        onAction()
                    }, label: {
                        Text(buttonTitle)
                    })
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
                    .frame(width: viewWidth / 2)
                    .padding([.leading, .trailing])
                }
            }
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.bottom, floatingControlAreaSize.height)
        .measureWidth { width in
            viewWidth = width
        }
    }
}

private extension PointOfSaleItemListEmptyView {
    enum Constants {
        static let iconSize: CGFloat = 100
    }
}

struct PointOfSaleItemListEmptyViewModel {
    let itemType: ItemType
    let baseItem: ItemListBaseItem

    var title: String {
        switch (baseItem, itemType) {
        case (.root, .products):
            return Localization.emptyProductsTitle
        case (.root, .coupons):
            return Localization.emptyCouponsTitle
        case (.parent, .products):
            return Localization.emptyVariableParentProductTitle
        default:
            assertionFailure("No title defined for \(baseItem)")
            return Localization.emptyProductsTitle
        }
    }

    var subtitle: String {
        switch (baseItem, itemType) {
        case (.root, .products):
            return Localization.emptyProductsSubtitle
        case (.root, .coupons):
            return Localization.emptyCouponsSubtitle
        case (.parent, .products):
            return Localization.emptyVariableParentProductSubtitle
        default:
            assertionFailure("No subtitle defined for \(baseItem)")
            return Localization.emptyProductsTitle
        }
    }

    var hint: String? {
        switch (baseItem, itemType) {
        case (.root, .products):
            return Localization.emptyProductsHint
        case (.root, .coupons):
            return nil
        case (.parent, .products):
            return Localization.emptyVariableParentProductHint
        default:
            assertionFailure("No hint defined for \(baseItem)")
            return Localization.emptyProductsTitle
        }
    }

    var buttonTitle: String? {
        switch itemType {
        case .coupons:
            return Localization.emptyCouponsButtonTitle
        default:
            return nil
        }
    }

    enum Localization {
        static let emptyProductsTitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyProductsTitle.1",
            value: "No supported products found.",
            comment: "Text appearing on screen when there are no products to load."
        )
        static let emptyProductsSubtitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyProductsSubtitle.1",
            value: "POS currently only supports simple and variable products.",
            comment: "Subtitle text on screen when there are no products to load."
        )
        static let emptyProductsHint = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyProductsHint.1",
            value: "To add one, exit POS and go to Products.",
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

        static let emptyCouponsTitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyCouponsTitle",
            value: "No coupons found.",
            comment: "Text appearing on the coupon list screen when there's no coupons found."
        )
        static let emptyCouponsSubtitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyCouponsSubtitle",
            value: "Boost your business by sending customers special offers and discounts.",
            comment: "Text appearing on the coupons list screen as subtitle when there's no coupons found."
        )
        static let emptyCouponsButtonTitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.noCouponsFoundButtonTitleButtonTitle",
            value: "Create coupon",
            comment: "Text for the button appearing on the coupons list screen when there's no coupons found."
        )
    }
}
