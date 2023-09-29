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
         source: AddProductCoordinator.Source,
         productName: String?,
         addImage: @escaping (MediaPickingSource) async -> MediaPickerImage?,
         completion: @escaping (AddProductFromImageData?) -> Void) {
        super.init(rootView: AddProductFromImageView(siteID: siteID, source: source, productName: productName, addImage: addImage, completion: completion))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A form to create a product from an image, where any texts in the image can be scanned to generate product details with Jetpack AI.
struct AddProductFromImageView: View {
    private let completion: (AddProductFromImageData?) -> Void
    @StateObject private var viewModel: AddProductFromImageViewModel

    init(siteID: Int64,
         source: AddProductCoordinator.Source,
         productName: String?,
         addImage: @escaping (MediaPickingSource) async -> MediaPickerImage?,
         stores: StoresManager = ServiceLocator.stores,
         completion: @escaping (AddProductFromImageData?) -> Void) {
        self.completion = completion
        self._viewModel = .init(wrappedValue: AddProductFromImageViewModel(siteID: siteID,
                                                                           source: source,
                                                                           productName: productName,
                                                                           stores: stores,
                                                                           onAddImage: addImage))
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

            Section {
                // Name field.
                AddProductFromImageTextFieldView(viewModel: viewModel.nameViewModel,
                                                 customizations: .init(lineLimit: 1...2),
                                                 isGeneratingSuggestion: viewModel.isGeneratingDetails)
                // Description field.
                AddProductFromImageTextFieldView(viewModel: viewModel.descriptionViewModel,
                                                 customizations: .init(lineLimit: 2...10),
                                                 isGeneratingSuggestion: viewModel.isGeneratingDetails)
            }

            // Scanned text list.
            Section {
                VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
                    // Button to regenerate product details based on the selected scanned texts.
                    Button(Localization.regenerateButtonTitle) {
                        viewModel.generateProductDetails()
                    }
                    .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isGeneratingDetails))
                    .disabled(viewModel.regenerateButtonEnabled == false)

                    // Error message.
                    if let errorMessage = viewModel.textGenerationErrorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(uiColor: .error))
                    }

                    // Info text about selecting/editing the scanned text list.
                    Text(viewModel.scannedTextInstruction)
                        .foregroundColor(.init(uiColor: .secondaryLabel))
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
                if viewModel.isGeneratingDetails {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else {
                    Button(Localization.continueButtonTitle) {
                        viewModel.trackContinueButtonTapped()
                        completion(.init(name: viewModel.name, description: viewModel.description, image: viewModel.image))
                    }
                    .buttonStyle(LinkButtonStyle())
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.cancelButtonTitle) {
                    completion(nil)
                }
                .buttonStyle(TextButtonStyle())
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
        static let continueButtonTitle = NSLocalizedString(
            "Continue",
            comment: "Continue button on the add product from image form."
        )
        static let cancelButtonTitle = NSLocalizedString(
            "Cancel",
            comment: "Cancel button on the add product from image form."
        )
        static let regenerateButtonTitle = NSLocalizedString(
            "Regenerate",
            comment: "Regenerate button on the add product from image form to regenerate product details."
        )
    }

    enum Layout {
        static let defaultSpacing: CGFloat = 16
    }
}

struct AddProductFromImageView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductFromImageView(siteID: 134, source: .productsTab, productName: nil, addImage: { _ in nil }, completion: { _ in })
    }
}
