import Alamofire
import Combine
import Foundation
import Networking
import Yosemite

final class ProductImageBackgroundFormViewModel: ObservableObject {
    @Published var prompt: String
    @Published var originalImage: UIImage?
    @Published var generatedImage: UIImage?
    @Published var isGenerationInProgress: Bool = false

    private let productImage: ProductImage
    private let productUIImageLoader: ProductUIImageLoader

    private var subscriptions: Set<AnyCancellable> = []

    init(prompt: String, productImage: ProductImage, productUIImageLoader: ProductUIImageLoader) {
        self.prompt = prompt
        self.productImage = productImage
        self.productUIImageLoader = productUIImageLoader
    }

    @MainActor
    func replaceBackground() async {
        isGenerationInProgress = true
        defer {
            isGenerationInProgress = false
        }
        do {
            let generatedImageURL = try await replaceBackground(image: productImage, options: .init(backgroundDescription: prompt, scale: 0.7))
            // TODO-JC: remove imageID hack to download UIImage properly
            let generatedProductImage = productImage.copy(imageID: Int64(UUID().hashValue), src: generatedImageURL)
            self.generatedImage = await requestUIImage(for: generatedProductImage)
        } catch {
            print(error)
        }
    }
}

private extension ProductImageBackgroundFormViewModel {
    func requestUIImage(for image: ProductImage) async -> UIImage {
        await withCheckedContinuation { continuation in
            productUIImageLoader.requestImage(productImage: image) { image in
                continuation.resume(returning: image)
            }?.store(in: &subscriptions)
        }
    }

    func replaceBackground(image: ProductImage, options: SceneOptions) async throws -> String {
        let remote = MediaRemote(network: AlamofireNetwork(credentials: nil))
        return try await remote.replaceBackground(image: image, options: options)
    }
}
