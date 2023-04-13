import Alamofire
import Combine
import Foundation
import Networking
import Yosemite

final class ProductImageBackgroundFormViewModel: ObservableObject {
    // Scene options.
    @Published var prompt: String
    @Published var scale: Double = 0.8
    @Published var prepositionIndex: Int = 0
    let prepositionOptions: [SceneOptions.ScenePreposition] = [.in, .on, .among]
    @Published var resolutionIndex: Int = 0
    let resolutionOptions: [SceneOptions.Resolution] = [.default, .high]
    @Published var timeOfDay: SceneOptions.TimeOfDay?
    let timeOfDayOptions: [SceneOptions.TimeOfDay?] = [nil] + SceneOptions.TimeOfDay.allCases
    @Published var perspective: SceneOptions.Perspective?
    let perspectiveOptions: [SceneOptions.Perspective?] = [nil] + SceneOptions.Perspective.allCases
    @Published var filters: SceneOptions.Filters?
    let filtersOptions: [SceneOptions.Filters?] = [nil] + SceneOptions.Filters.allCases
    @Published var placement: SceneOptions.Placement?
    let placementOptions: [SceneOptions.Placement?] = [nil] + SceneOptions.Placement.allCases
    @Published var vibe: SceneOptions.Vibe?
    let vibeOptions: [SceneOptions.Vibe?] = [nil] + SceneOptions.Vibe.allCases

    var modifiers: [String] {
        [timeOfDay?.rawValue, perspective?.rawValue, filters?.rawValue, placement?.rawValue, vibe?.rawValue]
        .compactMap { $0 }
    }

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
            let generatedImageURL = try await replaceBackground(image: productImage,
                                                                options: .init(backgroundDescription: prompt,
                                                                               scale: scale,
                                                                               preposition: prepositionOptions[prepositionIndex],
                                                                               resolution: resolutionOptions[resolutionIndex],
                                                                               timeOfDay: timeOfDay))
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
