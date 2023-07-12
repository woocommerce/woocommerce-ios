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

    init(siteID: Int64,
         addImage: @escaping (MediaPickingSource) async -> MediaPickerImage?,
         stores: StoresManager = ServiceLocator.stores,
         completion: @escaping (AddProductFromImageData) -> Void) {
        self.completion = completion
        self._viewModel = .init(wrappedValue: AddProductFromImageViewModel(siteID: siteID, stores: stores, onAddImage: addImage))
    }

    var body: some View {
        Form {
            // Image header view.
            Section {
                HStack {
                    Spacer()
                    AddProductFromImageFormImageView(viewModel: viewModel)
                    Spacer()
                }
            }

            // Name & description fields.
            Section {
                // TODO: 10180 - use `TextEditor` with a placeholder overlay
                TextField(Localization.nameFieldPlaceholder, text: $viewModel.name)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                TextField(Localization.descriptionFieldPlaceholder, text: $viewModel.description)
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Scanned text list.
            Section {
                VStack(alignment: .leading) {
                    // Button to regenerate product details based on the selected scanned texts.
                    Button(Localization.regenerateButtonTitle) {
                        viewModel.generateProductDetails()
                    }
                    .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isGeneratingDetails))

                    // Info text about selecting/editing the scanned text list.
                    Text(Localization.scannedTextListInfo)
                        .captionStyle()
                }
                List(viewModel.scannedTexts) { scannedText in
                    AddProductFromImageScannedTextView(viewModel: scannedText)
                }
            }
            .renderedIf(viewModel.scannedTexts.isNotEmpty)
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
        static let regenerateButtonTitle = NSLocalizedString(
            "Regenerate",
            comment: "Regenerate button on the add product from image form to regenerate product details."
        )
        static let scannedTextListInfo = NSLocalizedString(
            "Tweak your text: Unselect scans you don't need or tap to edit",
            comment: "Info text about the scanned text list on the add product from image form."
        )
    }
}

struct AddProductFromImageView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductFromImageView(siteID: 134, addImage: { _ in nil }, completion: { _ in })
    }
}
