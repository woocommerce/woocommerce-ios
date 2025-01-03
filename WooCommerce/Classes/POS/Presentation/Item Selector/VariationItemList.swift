import SwiftUI
import Yosemite

/// Displays a scrollable list of variation items in POS.
struct VariationItemList: View {
    let parentItem: POSItem
    let parentProduct: POSParentProduct
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize

    private var state: ItemListState {
        posModel.itemsViewState.itemsStack
            .itemStates[parentItem] ??
            .loading([])
    }

    init(parentItem: POSItem, parentProduct: POSParentProduct) {
        self.parentItem = parentItem
        self.parentProduct = parentProduct
    }

    var body: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Label(Localization.back, systemImage: "chevron.backward")
                        .font(.posTitleRegular)
                }
                Spacer()
                POSHeaderTitleView(title: parentProduct.name)
                Spacer()
            }
            ScrollView {
                VStack {
                    ItemList(state: state)
                        .background(Color.posPrimaryBackground)
                        .toolbar(.hidden, for: .navigationBar)
                        .transition(.opacity)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, floatingControlAreaSize.height)
                .padding(.horizontal, Constants.itemListPadding)
            }
        }
        .task {
            guard state.items.isEmpty else {
                return
            }
            await posModel.loadInitialChildItems(for: parentItem)
        }
    }
}

private extension VariationItemList {
    enum Localization {
        static let back = NSLocalizedString(
            "pos.variationItemList.back",
            value: "Back",
            comment: "Back button title in the variation item list screen."
        )
    }

    enum Constants {
        static let itemListPadding: CGFloat = 16
    }
}

#if DEBUG

#Preview("Loaded with all product types") {
    let parentProduct = POSParentProduct(
        id: .init(),
        name: "Variable latte",
        productImageSource: nil,
        productID: 1,
        type: .variable
    )
    let parentItem = POSItem.parentProduct(parentProduct)
    let itemsController = PointOfSalePreviewItemsController()
    itemsController.itemsViewState = .init(containerState: .content,
                                           itemsStack: ItemsStackState(
                                            root: .loading([]),
                                            itemStates: [
                                                parentItem: .loaded(
                                                    [
                                                        .variation(
                                                            POSVariation(
                                                                id: .init(),
                                                                name: "Cinamon chestnut latte",
                                                                formattedPrice: "$5.75"
                                                            )
                                                        ),
                                                        .variation(
                                                            POSVariation(
                                                                id: .init(),
                                                                name: "Choco latte",
                                                                formattedPrice: "$6.5"
                                                            )
                                                        )
                                                    ])]))
    let posModel = PointOfSaleAggregateModel(
        itemsController: itemsController,
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController())
    return VariationItemList(parentItem: parentItem, parentProduct: parentProduct)
        .environmentObject(posModel)
}

#endif
