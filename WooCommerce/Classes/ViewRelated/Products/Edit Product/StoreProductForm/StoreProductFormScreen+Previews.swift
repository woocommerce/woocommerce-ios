#if DEBUG
import SwiftUI
import Yosemite

#Preview("Editable product") {
    @Previewable @State var store = StoreProductFormPreview.makeStore(isEditable: true)
    StoreProductFormScreen(store: store)
}

#Preview("Read-only product") {
    @Previewable @State var store = StoreProductFormPreview.makeStore(isEditable: false)
    StoreProductFormScreen(store: store)
        .preferredColorScheme(.dark)
}

@MainActor
enum StoreProductFormPreview {
    static func makeStore(isEditable: Bool) -> StoreProductFormRendererStore {
        let sections: [ProductFormSection] = [
            .primaryFields(rows: [
                .images(isEditable: isEditable, isStorePublic: true, allowsMultiple: true, isVariation: false),
                .name(name: "Canvas Weekender Bag", isEditable: isEditable, productStatus: .published),
                .description(description: "A durable cotton canvas bag with an adjustable shoulder strap.",
                             isEditable: isEditable,
                             isDescriptionAIEnabled: false)
            ]),
            .settings(rows: [
                .price(viewModel: .init(icon: .price,
                                        title: Localization.priceSettingsTitle,
                                        details: "$45.00",
                                        isActionable: isEditable),
                       isEditable: isEditable),
                .inventory(viewModel: .init(icon: .inventory,
                                            title: Localization.inventorySettingsTitle,
                                            details: ProductStockStatus.inStock.description,
                                            isActionable: isEditable),
                           isEditable: isEditable),
                .categories(viewModel: .init(icon: .categories,
                                             title: Localization.categoriesTitle,
                                             details: "Travel, Bags",
                                             isActionable: isEditable),
                            isEditable: isEditable),
                .reviews(viewModel: .init(icon: .reviews, title: Localization.reviewsTitle, details: nil),
                         ratingCount: 12,
                         averageRating: "4.5")
            ])
        ]
        return StoreProductFormRendererStore(sections: sections,
                                             imageStatuses: [],
                                             imageLoader: DefaultProductUIImageLoader(),
                                             onPrimaryRowSelected: { _ in },
                                             onSettingsRowSelected: { _ in },
                                             onInlineAction: { _ in })
    }

    private typealias Localization = DefaultProductFormTableViewModel.Localization
}
#endif
