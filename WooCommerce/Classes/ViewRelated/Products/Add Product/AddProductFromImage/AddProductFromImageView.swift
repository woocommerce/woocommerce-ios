import SwiftUI
import Yosemite

/// Product data from the "add product from image" form.
struct AddProductFromImageData {
    let name: String
    let description: String
    let image: MediaPickerImage?
}

/// Hosting controller for `AddProductFromImageView`.
final class AddProductFromImageHostingController: UIHostingController<AddProductFromImageView> {
    init(siteID: Int64,
         addImage: @escaping (MediaPickingSource) async -> MediaPickerImage?,
         completion: @escaping (AddProductFromImageData) -> Void) {
        super.init(rootView: AddProductFromImageView(siteID: siteID, addImage: addImage, completion: completion))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A form to create a product from an image, where any texts in the image can be scanned to generate product details with Jetpack AI.
struct AddProductFromImageView: View {
    private let completion: (AddProductFromImageData) -> Void
    @StateObject private var viewModel: AddProductFromImageViewModel
    @FocusState private var isNameFieldInFocus: Bool
    @FocusState private var isDescriptionFieldInFocus: Bool

    init(siteID: Int64,
         addImage: @escaping (MediaPickingSource) async -> MediaPickerImage?,
         stores: StoresManager = ServiceLocator.stores,
         completion: @escaping (AddProductFromImageData) -> Void) {
        self.completion = completion
        self._viewModel = .init(wrappedValue: AddProductFromImageViewModel(siteID: siteID,
                                                                           onAddImage: addImage))
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    AddProductFromImageFormImageView(viewModel: viewModel)
                    Spacer()
                }
            }

            Section(header: Text(Localization.nameFieldPlaceholder)) {
                TextEditor(text: $viewModel.name)
                    .bodyStyle()
                    .foregroundColor(.secondary)

                if let suggestedName = viewModel.suggestedName, suggestedName.isNotEmpty {
                    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
                        Text("Suggestion from photo")
                            .captionStyle()
                        Text(suggestedName)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)

                        HStack {
                            Spacer()
                            // CTA to copy the generated text.
                            Button {
                                UIPasteboard.general.string = suggestedName
    //                                copyTextNotice = .init(title: Localization.textCopiedNotice)
    //                                ServiceLocator.analytics.track(event: .ProductFormAI.productDescriptionAICopyButtonTapped())
                            } label: {
                                Label(Localization.copyGeneratedText, systemImage: "doc.on.doc")
                                    .secondaryBodyStyle()
                            }
                            .buttonStyle(.plain)
                            .fixedSize(horizontal: true, vertical: false)

                            // CTA to replace with the generated text.
                            Button {
                                viewModel.applySuggestedName()
                            } label: {
                                Image(systemName: "checkmark")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .fixedSize(horizontal: true, vertical: false)

                            // CTA to copy the generated text.
                            Button {
//                                UIPasteboard.general.string = suggestedName
    //                                copyTextNotice = .init(title: Localization.textCopiedNotice)
    //                                ServiceLocator.analytics.track(event: .ProductFormAI.productDescriptionAICopyButtonTapped())
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(Layout.suggestedTextInsets)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.cornerRadius)
                            .foregroundColor(.init(uiColor: .tertiarySystemBackground))
                    )
                }
            }

            Section(header: Text(Localization.descriptionFieldPlaceholder)) {
                TextEditor(text: $viewModel.description)
                    .bodyStyle()
                    .foregroundColor(.secondary)
            }
            .redacted(reason: viewModel.isGeneratingDetails ? .placeholder : [])
            // TODO-JC: placeholder UI when loading image
            .shimmering(active: viewModel.isGeneratingDetails)
        }
        .navigationTitle(Localization.title)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Localization.continueButtonTitle) {
                    completion(.init(name: viewModel.name, description: viewModel.description, image: viewModel.image))
                }
                .buttonStyle(LinkButtonStyle())
            }
        }
    }
}

private extension AddProductFromImageView {
    enum Localization {
        static let title = NSLocalizedString(
            "Add product",
            comment: "Navigation bar title of the add product from image form."
        )
        static let nameFieldPlaceholder = NSLocalizedString(
            "Name",
            comment: "Product name placeholder on the add product from image form."
        )
        static let descriptionFieldPlaceholder = NSLocalizedString(
            "Description",
            comment: "Product description placeholder on the add product from image form."
        )
        static let continueButtonTitle = NSLocalizedString(
            "Continue",
            comment: "Continue button on the add product from image form."
        )
        static let copyGeneratedText = NSLocalizedString(
            "Copy",
            comment: "Button title to copy generated text in the product description AI generator view."
        )
    }

    enum Layout {
        static let insets: EdgeInsets = .init(top: 24, leading: 16, bottom: 16, trailing: 16)
        static let defaultSpacing: CGFloat = 16
        static let titleAndProductNameSpacing: CGFloat = 2
        static let minimuNameEditorSize: CGFloat = 30
        static let minimuEditorSize: CGFloat = 76
        static let cornerRadius: CGFloat = 8
        static let productFeaturesInsets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let productFeaturesPlaceholderInsets: EdgeInsets = .init(top: 18, leading: 16, bottom: 18, trailing: 16)
        static let suggestedTextInsets: EdgeInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
    }
}

struct AddProductFromImageView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductFromImageView(siteID: 134, addImage: { _ in nil }, completion: { _ in })
    }
}
