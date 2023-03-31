import Foundation
import Yosemite

final class ProductDescriptionGenerationViewModel: ObservableObject {
    @Published var name: String
    @Published var prompt: String
    @Published var suggestedText: String?
    @Published var isGenerationInProgress: Bool = false

    var generateButtonTitle: String {
        suggestedText == nil ? "🪄 Magic write": "✨ Regenerate"
    }

    var applyButtonTitle: String {
        product.description?.isNotEmpty == true ? "Replace description": "Use for description"
    }

    private let product: ProductFormDataModel
    private let stores: StoresManager

    init(product: ProductFormDataModel,
         stores: StoresManager = ServiceLocator.stores) {
        self.name = product.name
        self.prompt = product.description ?? ""
        self.product = product
        self.stores = stores
    }

    @MainActor
    func generateDescription() async {
        isGenerationInProgress = true

        defer {
            isGenerationInProgress = false
        }

        let result = await generateProductDescription()
        switch result {
        case let .success(text):
            suggestedText = text
        case let .failure(error):
            print("Error generating product description: \(error)")
        }
    }
}

private extension ProductDescriptionGenerationViewModel {
    @MainActor
    func generateProductDescription() async -> Result<String, Error> {
        let base = """
Generate an elegant product description that is optimized for SEO with the following attributes on an e-commerce site:
Product name: \(name)
Description: \(prompt)
"""
        return await withCheckedContinuation { continuation in
            stores.dispatch(ProductAction.generateProductDescription(siteID: product.siteID, base: base) { result in
                continuation.resume(returning: result)
            })
        }
    }
}
