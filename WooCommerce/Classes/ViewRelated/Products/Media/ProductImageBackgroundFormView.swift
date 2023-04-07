import SwiftUI

/// Hosting controller for `ProductImageBackgroundFormView`.
///
final class ProductImageBackgroundFormHostingController: UIHostingController<ProductImageBackgroundFormView> {
    init(viewModel: ProductImageBackgroundFormViewModel, imageAdded: @escaping (UIImage) -> Void) {
        super.init(rootView: ProductImageBackgroundFormView(viewModel: viewModel,
                                                            imageAdded: imageAdded))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ProductImageBackgroundFormView: View {
    @ObservedObject private var viewModel: ProductImageBackgroundFormViewModel
    private let imageAdded: (UIImage) -> Void

    init(viewModel: ProductImageBackgroundFormViewModel, imageAdded: @escaping (UIImage) -> Void) {
        self.viewModel = viewModel
        self.imageAdded = imageAdded
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Background description")
                    .subheadlineStyle()
                TextEditor(text: $viewModel.prompt)
                    .bodyStyle()
                    .foregroundColor(.secondary)
                    .frame(minHeight: Layout.minimuEditorSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                    )

                HStack {
                    Button(viewModel.generatedImage == nil ? "Generate": "Regenerate") {
                        Task { @MainActor in
                            await viewModel.replaceBackground()
                        }
                    }
                    .disabled(viewModel.prompt.isEmpty)
                    .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isGenerationInProgress))

                    if let generatedImage = viewModel.generatedImage {
                        Button("Use for product") {
                            imageAdded(generatedImage)
                        }
                    }
                }


                if let generatedImage = viewModel.generatedImage {
                    Image(uiImage: generatedImage)
                        .resizable()
                        .scaledToFit()
                }
            }.padding()
        }
    }
}

// MARK: Constants
private extension ProductImageBackgroundFormView {
    enum Layout {
        static let minimuEditorSize: CGFloat = 60
        static let cornerRadius: CGFloat = 8
    }
}

#if DEBUG

import Photos

struct ProductImageBackgroundFormView_Previews: PreviewProvider {
    static var previews: some View {
        ProductImageBackgroundFormView(viewModel: .init(prompt: "",
                                                        productImage: .init(imageID: 1, dateCreated: .init(), dateModified: nil, src: "", name: nil, alt: nil),
                                                        productUIImageLoader: DefaultProductUIImageLoader(productImageActionHandler: .init(siteID: 0, productID: .product(id: 0), imageStatuses: []),
                                                                                                          phAssetImageLoaderProvider: { PHImageManager.default() })),
                                       imageAdded: { _ in })
    }
}

#endif
