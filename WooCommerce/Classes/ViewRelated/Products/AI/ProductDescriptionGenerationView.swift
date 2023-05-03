import SwiftUI

/// Output data from the AI-generated product description flow.
struct ProductDescriptionGenerationOutput: Equatable {
    /// The user can enter or update the product name when polishing the AI-generated product generation.
    let name: String

    /// AI-generated product description.
    let description: String
}

/// Hosting controller for `ProductDescriptionGenerationView`.
///
final class ProductDescriptionGenerationHostingController: UIHostingController<ProductDescriptionGenerationView> {
    init(viewModel: ProductDescriptionGenerationViewModel) {
        super.init(rootView: ProductDescriptionGenerationView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Allows the user to generate a product description using Jetpack AI given the product name and features.
struct ProductDescriptionGenerationView: View {
    @ObservedObject private var viewModel: ProductDescriptionGenerationViewModel
    @State private var copyTextNotice: Notice?

    init(viewModel: ProductDescriptionGenerationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
                VStack(alignment: .leading, spacing: Layout.titleAndProductNameSpacing) {
                    Text(Localization.title)
                        .headlineStyle()

                    if #available(iOS 16.0, *) {
                        TextField(Localization.productNamePlaceholder, text: $viewModel.name, axis: .vertical)
                            .subheadlineStyle()
                    } else {
                        TextField(Localization.productNamePlaceholder, text: $viewModel.name)
                            .subheadlineStyle()
                    }
                }

                // Since there is no placeholder support in `TextEditor`, a workaround is to
                // use a ZStack with an optional `Text` on top that passes through the gestures.
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.features)
                        .bodyStyle()
                        .foregroundColor(.secondary)
                        .background(.clear)
                        .padding(insets: Layout.productFeaturesInsets)
                        .frame(minHeight: Layout.minimuEditorSize, maxHeight: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                        )

                    if viewModel.features.isEmpty {
                        Text(Localization.productDescriptionPlaceholder)
                            .foregroundColor(Color(.placeholderText))
                            .bodyStyle()
                            .padding(insets: Layout.productFeaturesPlaceholderInsets)
                            // Allows gestures to pass through to the `TextEditor`.
                            .allowsHitTesting(false)
                    }
                }

                if let suggestedText = viewModel.suggestedText {
                    Text(suggestedText)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .padding(Layout.suggestedTextInsets)
                        .background(
                            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                                .foregroundColor(.init(uiColor: .secondarySystemBackground))
                        )
                }

                HStack(alignment: .center, spacing: Layout.defaultSpacing) {
                    if let suggestedText = viewModel.suggestedText {
                        // CTA to copy the generated text.
                        Button {
                            UIPasteboard.general.string = suggestedText
                            copyTextNotice = .init(title: Localization.textCopiedNotice)
                            ServiceLocator.analytics.track(event: .ProductFormAI.productDescriptionAICopyButtonTapped())
                        } label: {
                            Label(Localization.copyGeneratedText, systemImage: "doc.on.doc")
                        }.buttonStyle(PlainButtonStyle())

                        Spacer()

                        // CTA to start or stop text generation based on the current state.
                        Button {
                            viewModel.toggleDescriptionGeneration()
                        } label: {
                            Image(systemName: viewModel.isGenerationInProgress ? "pause.circle": "arrow.counterclockwise")
                        }.buttonStyle(PlainButtonStyle())

                        // CTA to apply the generated text.
                        Button(Localization.insertGeneratedText) {
                            viewModel.applyToProduct()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .fixedSize(horizontal: true, vertical: false)
                    } else {
                        // CTA to generate text for the first pass.
                        Button(Localization.generateText) {
                            viewModel.generateDescription()
                        }
                        .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isGenerationInProgress))
                        .disabled(viewModel.isGenerationEnabled == false)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .errorStyle()
                }
            }.padding(insets: Layout.insets)
        }
        .notice($copyTextNotice, autoDismiss: true)
    }
}

// MARK: Constants
private extension ProductDescriptionGenerationView {
    enum Layout {
        static let insets: EdgeInsets = .init(top: 24, leading: 16, bottom: 16, trailing: 16)
        static let defaultSpacing: CGFloat = 16
        static let titleAndProductNameSpacing: CGFloat = 2
        static let minimuNameEditorSize: CGFloat = 30
        static let minimuEditorSize: CGFloat = 76
        static let cornerRadius: CGFloat = 8
        static let productFeaturesInsets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let productFeaturesPlaceholderInsets: EdgeInsets = .init(top: 18, leading: 16, bottom: 18, trailing: 16)
        static let suggestedTextInsets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    }
}

private extension ProductDescriptionGenerationView {
    enum Localization {
        static let title = NSLocalizedString(
            "Write product description",
            comment: "Title in the product description AI generator view."
        )
        static let productNamePlaceholder = NSLocalizedString(
            "Enter product name",
            comment: "Product name placeholder in the product description AI generator view."
        )
        static let productDescriptionPlaceholder = NSLocalizedString(
            "Describe your product features",
            comment: "Product features placeholder in the product description AI generator view."
        )
        static let copyGeneratedText = NSLocalizedString(
            "Copy",
            comment: "Button title to copy generated text in the product description AI generator view."
        )
        static let textCopiedNotice = NSLocalizedString(
            "Copied!",
            comment: "Text in the notice after copying the generated text in the product description AI generator view."
        )
        static let insertGeneratedText = NSLocalizedString("Apply",
                                                           comment: "Button title to insert AI-generated product description.")
        static let generateText = NSLocalizedString("Generate",
                                                    comment: "Button title to generate product description with Jetpack AI.")
    }
}

#if DEBUG

import Yosemite

final class ProductDescriptionGenerationPreviewStores: DefaultStoresManager {
    private let result: Result<String, Error>

    init(result: Result<String, Error>) {
        self.result = result
        super.init(sessionManager: ServiceLocator.stores.sessionManager)
    }

    override func dispatch(_ action: Action) {
        if let action = action as? ProductAction {
            if case let .generateProductDescription(_, _, _, _, completion) = action {
                completion(result)
            }
        }
    }
}

struct ProductDescriptionGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        ProductDescriptionGenerationView(viewModel:
                .init(siteID: 0,
                      name: "Potted cactus",
                      description: "low-maintenance, decorative plant that improves indoor air quality and provides health benefits",
                      stores: ProductDescriptionGenerationPreviewStores(result:
                            .success("These unique plants thrive in harsh environments and require very little care.")),
                      onApply: { _ in }))
        .previewDisplayName("Pre-filled name and features with success")

        ProductDescriptionGenerationView(viewModel:
                .init(siteID: 0,
                      name: "",
                      description: "",
                      stores: ProductDescriptionGenerationPreviewStores(result:
                            .failure(ProductDownloadFileError.emptyFileName)),
                      onApply: { _ in }))
        .previewDisplayName("Empty name and features with failure")
    }
}

#endif
