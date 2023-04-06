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
        let image = await requestOriginalImage()
        self.originalImage = image
        do {
            self.generatedImage = try await replaceBackground(image: image, prompt: prompt)
        } catch {
            print(error)
        }
    }
}

private extension ProductImageBackgroundFormViewModel {
    func requestOriginalImage() async -> UIImage {
        await withCheckedContinuation { continuation in
            productUIImageLoader.requestImage(productImage: productImage) { image in
                continuation.resume(returning: image)
            }?.store(in: &subscriptions)
        }
    }

    func replaceBackground(image: UIImage, prompt: String) async throws -> UIImage {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            fatalError()
        }
        let remote = MediaRemote(network: AlamofireNetwork(credentials: nil))
        return try await remote.replaceBackground(image: imageData, prompt: prompt)
    }
}
