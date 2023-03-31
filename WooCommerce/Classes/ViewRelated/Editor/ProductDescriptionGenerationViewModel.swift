import Foundation
import OpenAISwift

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

    init(product: ProductFormDataModel) {
        self.name = product.name
        self.prompt = product.description ?? ""
        self.product = product
    }

    @MainActor
    func generateDescription() async {
        let content = """
Generate an elegant product description that is optimized for SEO with the following attributes on an e-commerce site:
Product name: \(name)
Description: \(prompt)
"""
        isGenerationInProgress = true

        defer {
            isGenerationInProgress = false
        }

        let openAI = OpenAISwift(authToken: Constants.authToken)
        do {
            let chat: [ChatMessage] = [
                ChatMessage(role: .user, content: content)
            ]

            let result = try await openAI.sendChat(with: chat)
            guard let text = result.choices.first?.message.content else {
                return
            }
            suggestedText = text
        } catch {
            print("Error generating product description: \(error)")
        }
    }
}

private extension ProductDescriptionGenerationViewModel {
    enum Constants {
        static let authToken = ""
    }
}
