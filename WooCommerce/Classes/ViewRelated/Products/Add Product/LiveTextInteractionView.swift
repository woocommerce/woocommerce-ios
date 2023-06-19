import UIKit
import SwiftUI
import VisionKit

@available(iOS 16.0, *)
@MainActor
struct LiveTextInteractionView: UIViewRepresentable {
    private let image: UIImage
    private let imageView = LiveTextImageView()
    private let analyzer = ImageAnalyzer()
    private let interaction = ImageAnalysisInteraction()

    init(image: UIImage) {
        self.image = image
    }

    func makeUIView(context: Context) -> some UIView {
        imageView.image = image

        imageView.addInteraction(interaction)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        Task {
            let configuration = ImageAnalyzer.Configuration([.text, .machineReadableCode])
            do {
                if let image = imageView.image {
                    let analysis = try await analyzer.analyze(image, configuration: configuration)
                    interaction.analysis = analysis
                    interaction.preferredInteractionTypes = .textSelection
                }
            }
            catch {
                // Handle error…
            }
        }
    }
}

final class LiveTextImageView: UIImageView {
    // Use intrinsicContentSize to change the default image size
    // so that we can change the size in our SwiftUI View
    override var intrinsicContentSize: CGSize {
        .zero
    }
}
