import SwiftUI
import Yosemite

/// Displays a scrollable list of child items in POS.
struct ChildItemList: View {
    private let parentItem: POSItem
    private let parentProduct: POSParentProduct
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
                    Image(systemName: "chevron.backward")
                        .font(.posBodyEmphasized, maximumContentSizeCategory: .accessibilityLarge)
                        .foregroundColor(.primary)
                }
                POSHeaderTitleView(title: parentProduct.name)
                Spacer()
            }
            .padding(.horizontal, Constants.itemListPadding)
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

private extension ChildItemList {
    enum Localization {
        static let back = NSLocalizedString(
            "pos.childItemList.back",
            value: "Back",
            comment: "Back button title in the child item list screen."
        )
    }

    enum Constants {
        static let itemListPadding: CGFloat = 16
    }
}

#if DEBUG

#Preview("Variable product child items") {
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
    return ChildItemList(parentItem: parentItem, parentProduct: parentProduct)
        .environmentObject(posModel)
}

#endif
