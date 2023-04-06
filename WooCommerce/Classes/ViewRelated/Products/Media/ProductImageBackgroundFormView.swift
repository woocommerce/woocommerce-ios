import SwiftUI

/// Hosting controller for `ProductImageBackgroundFormView`.
///
final class ProductImageBackgroundFormHostingController: UIHostingController<ProductImageBackgroundFormView> {
    init(viewModel: ProductImageBackgroundFormViewModel) {
        super.init(rootView: ProductImageBackgroundFormView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

struct ProductImageBackgroundFormView: View {
    @ObservedObject private var viewModel: ProductImageBackgroundFormViewModel

    init(viewModel: ProductImageBackgroundFormViewModel) {
        self.viewModel = viewModel
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

                Button(viewModel.generatedImage == nil ? "Generate": "Regenerate") {
                    Task { @MainActor in
                        await viewModel.replaceBackground()
                    }
                }
                .disabled(viewModel.prompt.isEmpty)
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isGenerationInProgress))


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
                                                                                                          phAssetImageLoaderProvider: { PHImageManager.default() })))
    }
}

#endif
