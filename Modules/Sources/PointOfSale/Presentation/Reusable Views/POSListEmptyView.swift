import SwiftUI
import WooFoundation

protocol POSListEmptyViewModelProtocol {
    var title: String { get }
    var subtitle: String { get }
    var hint: String? { get }
    var buttonTitle: String? { get }
    var icon: Image { get }
}

extension POSListEmptyViewModelProtocol {
    var hint: String? { nil }
}

struct POSListEmptyView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    private let viewModel: any POSListEmptyViewModelProtocol

    private let onAction: (() -> Void)?

    @State private var viewWidth: CGFloat = 0

    @Environment(\.keyboardObserver) private var keyboard

    init(viewModel: any POSListEmptyViewModelProtocol, onAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onAction = onAction
    }

    var body: some View {
        ScrollableVStack {
            Spacer()
            VStack(alignment: .center, spacing: POSSpacing.none) {
                let shouldShowIcon: Bool = !dynamicTypeSize.isAccessibilitySize && !keyboard.isFullSizeKeyboardVisible

                if shouldShowIcon {
                    icon

                    Spacer().frame(height: PointOfSaleEmptyErrorStateViewLayout.imageAndTextSpacing)
                }

                Text(viewModel.title)
                    .accessibilityAddTraits(.isHeader)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posHeadingBold)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: PointOfSaleEmptyErrorStateViewLayout.textSpacing)

                Text(viewModel.subtitle)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posBodyLargeRegular())
                    .padding([.leading, .trailing])
                    .multilineTextAlignment(.center)

                if let hint = viewModel.hint {
                    Spacer().frame(height: POSSpacing.small)
                    Text(hint)
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                        .font(.posBodyLargeRegular())
                        .padding([.leading, .trailing])
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(height: PointOfSaleEmptyErrorStateViewLayout.textAndButtonSpacing)

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
        .padding(.bottom, !keyboard.isFullSizeKeyboardVisible ? floatingControlAreaSize.height : 0)
        .animation(.default, value: keyboard.keyboardHeight)
        .measureWidth { width in
            viewWidth = width
        }
    }

    @ViewBuilder
    private var icon: some View {
        viewModel.icon
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Constants.iconSize, height: Constants.iconSize)
            .foregroundColor(.posOnSurfaceVariantHighest)
    }
}

private extension POSListEmptyView {
    enum Constants {
        static let iconSize: CGFloat = 88
    }
}

struct POSListEmptyViewModel: POSListEmptyViewModelProtocol {
    let itemListType: ItemListType
    let baseItem: ItemListBaseItem

    var title: String {
        switch (baseItem, itemListType) {
        case (.root, .products(search: true)):
            return Localization.emptyProductsSearchTitle
        case (.root, .products(search: false)):
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
        switch (baseItem, itemListType) {
        case (.root, .products(search: true)):
            return Localization.emptyProductsSearchSubtitle
        case (.root, .products(search: false)):
            return Localization.emptyProductsSubtitle
        case (.root, .coupons(search: false)):
            return Localization.emptyCouponsSubtitle
        case (.root, .coupons(search: true)):
            return Localization.emptyCouponSearchSubtitle
        case (.parent, .products):
            return Localization.emptyVariableParentProductSubtitle
        default:
            assertionFailure("No subtitle defined for \(baseItem)")
            return Localization.emptyProductsTitle
        }
    }

    var hint: String? {
        switch (baseItem, itemListType) {
        case (.root, .products(search: true)):
            return Localization.emptyProductsSearchHint
        case (.root, .products(search: false)):
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
        switch (baseItem, itemListType) {
        case (.root, .coupons(search: false)):
            return Localization.emptyCouponsButtonTitle
        case (.root, .products(search: false)):
            return Localization.emptyProductsButtonTitle
        case (.parent, .products):
            return Localization.emptyProductsButtonTitle
        default:
            return nil
        }
    }

    var icon: Image {
        switch itemListType {
        case .coupons(search: false):
            SharedImageAsset.coupons.decorativeImage
        default:
            PointOfSaleAssets.magnifierNotFound.decorativeImage
        }
    }

    enum Localization {
        static let emptyProductsTitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyProductsTitle.2",
            value: "No supported products found",
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
        static let emptyProductsSearchTitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyProductsSearchTitle.2",
            value: "No products found",
            comment: "Text appearing on screen when a POS product search returns no results."
        )
        static let emptyProductsSearchSubtitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyProductsSearchSubtitle.3",
            value: "We couldn't find any matching products. Try adjusting your search term.",
            comment: "Subtitle text suggesting to modify search terms when no products are found in the POS product search."
        )
        static let emptyProductsSearchHint = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyProductsSearchHint",
            value: "Variation names can't be searched, so use the parent product name.",
            comment: "Text providing additional search tips when no products are found in the POS product search."
        )
        static let emptyVariableParentProductTitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyVariableParentProductTitle.2",
            value: "No supported variations found",
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
            "pos.pointOfSaleItemListEmptyView.emptyCouponsTitle2",
            value: "No coupons found",
            comment: "Text appearing on the coupon list screen when there's no coupons found."
        )
        static let emptyCouponsSubtitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyCouponsSubtitle.2",
            value: "Coupons can be an effective way to drive business. Would you like to create one?",
            comment: "Text appearing on the coupons list screen as subtitle when there's no coupons found."
        )
        static let emptyCouponsButtonTitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.noCouponsFoundButtonTitleButtonTitle",
            value: "Create coupon",
            comment: "Text for the button appearing on the coupons list screen when there's no coupons found."
        )
        static let emptyCouponSearchSubtitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyCouponSearchSubtitle.3",
            value: "We couldn’t find any coupons with that name. Try adjusting your search term.",
            comment: "Text appearing on the coupons list screen as subtitle when there's no coupons found."
        )
        static let emptyProductsButtonTitle = NSLocalizedString(
            "pos.pointOfSaleItemListEmptyView.emptyProductsButtonTitle",
            value: "Refresh",
            comment: "Text for the button appearing on the products list screen when there are no products found."
        )
    }
}

// MARK: - Preview

#Preview {
    POSListEmptyView(
        viewModel: POSListEmptyViewModel(
            itemListType: .coupons(search: false),
            baseItem: .root
        )
    ) {}
}

#Preview {
    POSListEmptyView(
        viewModel: POSListEmptyViewModel(
            itemListType: .products(search: true),
            baseItem: .root
        )
    ) {}
}
