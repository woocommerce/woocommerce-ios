import Foundation
import OpenAISwift

final class ProductDescriptionGenerationViewModel: ObservableObject {
    @Published var name: String
    @Published var productDescription: String

    init(product: ProductFormDataModel) {
        self.name = product.name
        self.productDescription = product.description ?? ""
    }

    func generateDescription() async {

    }
}
