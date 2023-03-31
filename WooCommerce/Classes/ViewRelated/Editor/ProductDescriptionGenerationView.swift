import SwiftUI

/// Hosting controller for `ProductDescriptionGenerationView`.
///
final class ProductDescriptionGenerationHostingController: UIHostingController<ProductDescriptionGenerationView> {
    init(viewModel: ProductDescriptionGenerationViewModel,
         onDescriptionUpdate: @escaping (_ updatedDescription: String) -> Void) {
        super.init(rootView: ProductDescriptionGenerationView(viewModel: viewModel,
                                                             onDescriptionUpdate: onDescriptionUpdate))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

struct ProductDescriptionGenerationView: View {
    @ObservedObject private var viewModel: ProductDescriptionGenerationViewModel

    private let onDescriptionUpdate: (_ updatedDescription: String) -> Void

    init(viewModel: ProductDescriptionGenerationViewModel,
         onDescriptionUpdate: @escaping (_ updatedDescription: String) -> Void) {
        self.viewModel = viewModel
        self.onDescriptionUpdate = onDescriptionUpdate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Title", text: $viewModel.name)
                    .headlineStyle()
                Text("Describe your product")
                    .subheadlineStyle()
                TextEditor(text: $viewModel.prompt)
                    .bodyStyle()
                    .foregroundColor(.secondary)
                    .frame(minHeight: Layout.minimuEditorSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                    )

                HStack {
                    Button(viewModel.generateButtonTitle) {
                        Task { @MainActor in
                            await viewModel.generateDescription()
                        }
                    }.buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isGenerationInProgress))

                    if let suggestedText = viewModel.suggestedText {
                        Button(viewModel.applyButtonTitle) {
                            onDescriptionUpdate(suggestedText)
                        }.buttonStyle(SecondaryButtonStyle())
                    }
                }

                if let suggestedText = viewModel.suggestedText {
                    Text(suggestedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }.padding()
        }
    }
}

// MARK: Constants
private extension ProductDescriptionGenerationView {
    enum Layout {
        static let minimuEditorSize: CGFloat = 100
        static let cornerRadius: CGFloat = 8
    }
}

#if DEBUG

struct ProductDescriptionGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        ProductDescriptionGenerationView(viewModel: .init(product:
                                                            EditableProductModel(product:
                                                                    .init(siteID: 0,
                                                                          productID: 0,
                                                                          name: "Name",
                                                                          slug: "",
                                                                          permalink: "",
                                                                          date: .init(),
                                                                          dateCreated: .init(),
                                                                          dateModified: .init(),
                                                                          dateOnSaleStart: nil,
                                                                          dateOnSaleEnd: nil,
                                                                          productTypeKey: "",
                                                                          statusKey: "",
                                                                          featured: false,
                                                                          catalogVisibilityKey: "",
                                                                          fullDescription: "Green case",
                                                                          shortDescription: "",
                                                                          sku: "",
                                                                          price: "",
                                                                          regularPrice: "",
                                                                          salePrice: "",
                                                                          onSale: false,
                                                                          purchasable: false,
                                                                          totalSales: 0,
                                                                          virtual: false,
                                                                          downloadable: false,
                                                                          downloads: [],
                                                                          downloadLimit: 0,
                                                                          downloadExpiry: 0,
                                                                          buttonText: "",
                                                                          externalURL: "",
                                                                          taxStatusKey: "",
                                                                          taxClass: "",
                                                                          manageStock: false,
                                                                          stockQuantity: 0,
                                                                          stockStatusKey: "",
                                                                          backordersKey: "",
                                                                          backordersAllowed: false,
                                                                          backordered: false,
                                                                          soldIndividually: false,
                                                                          weight: "",
                                                                          dimensions: .init(length: "", width: "", height: ""),
                                                                          shippingRequired: false,
                                                                          shippingTaxable: false,
                                                                          shippingClass: "",
                                                                          shippingClassID: 0,
                                                                          productShippingClass: nil,
                                                                          reviewsAllowed: false,
                                                                          averageRating: "",
                                                                          ratingCount: 0,
                                                                          relatedIDs: [],
                                                                          upsellIDs: [],
                                                                          crossSellIDs: [],
                                                                          parentID: 0,
                                                                          purchaseNote: "",
                                                                          categories: [],
                                                                          tags: [],
                                                                          images: [],
                                                                          attributes: [],
                                                                          defaultAttributes: [],
                                                                          variations: [],
                                                                          groupedProducts: [],
                                                                          menuOrder: 0,
                                                                          addOns: [],
                                                                          bundleStockStatus: .inStock,
                                                                          bundleStockQuantity: 0,
                                                                          bundledItems: [],
                                                                          compositeComponents: []))), onDescriptionUpdate: { _ in })
    }
}

#endif
