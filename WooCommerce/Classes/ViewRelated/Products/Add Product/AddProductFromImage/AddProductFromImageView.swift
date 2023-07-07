import SwiftUI
import Yosemite

/// Product data from the "add product from image" form.
struct AddProductFromImageData {
    let name: String
    let description: String
    // TODO: 10180 - image from media picker
}

/// Hosting controller for `AddProductFromImageView`.
final class AddProductFromImageHostingController: UIHostingController<AddProductFromImageView> {
    init(siteID: Int64,
         completion: @escaping (AddProductFromImageData) -> Void) {
        super.init(rootView: AddProductFromImageView(siteID: siteID, completion: completion))
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
         stores: StoresManager = ServiceLocator.stores,
         completion: @escaping (AddProductFromImageData) -> Void) {
        self.completion = completion
        self._viewModel = .init(wrappedValue: AddProductFromImageViewModel())
    }

    var body: some View {
        Form {
            Section {
                // TODO: 10180 - use `TextEditor` with a placeholder overlay
                TextField(Localization.nameFieldPlaceholder, text: $viewModel.name)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                TextField(Localization.descriptionFieldPlaceholder, text: $viewModel.description)
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .navigationTitle(Localization.title)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Localization.continueButtonTitle) {
                    // TODO: 10180 - pass the image from media picker
                    completion(.init(name: viewModel.name, description: viewModel.description))
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
    }
}

struct AddProductFromImageView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductFromImageView(siteID: 134, completion: { _ in })
    }
}
