import Kingfisher
import Alamofire
import SwiftUI
import struct Yosemite.ProductImage

final class ProductImagePickerViewController: UIHostingController<ProductImagePickerView> {
    private var onSelection: ProductImagePickerView.Completion

    init(viewModel: ProductImagePickerViewModel,
         onSelection: @escaping ProductImagePickerView.Completion) {
        self.onSelection = onSelection
        super.init(rootView: ProductImagePickerView(viewModel: viewModel))
        rootView.onSelection = { [weak self] image in
            guard let self else { return }
            onSelection(image)
            self.dismiss(animated: true)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set presentation delegate to track the user dismiss flow event
        if let navigationController = navigationController {
            navigationController.presentationController?.delegate = self
        } else {
            presentationController?.delegate = self
        }
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Intercepts to the dismiss drag gesture.
///
extension ProductImagePickerViewController: UIAdaptivePresentationControllerDelegate {

    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        onSelection(nil)
    }
}

/// View to pick an image from an existing product.
///
struct ProductImagePickerView: View {
    typealias Completion = ((_ selectedImage: ProductImage?) -> Void)

    @ObservedObject private var viewModel: ProductImagePickerViewModel
    @State private var selectedImage: ProductImage?

    // To be set in the hosting controller
    var onSelection: ((ProductImage?) -> Void)?

    init(viewModel: ProductImagePickerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.productImages.isNotEmpty {
                    ScrollView {
                        imageGridView
                    }
                } else if viewModel.loadingData {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else {
                    EmptyState(title: Localization.emptyStateTitle)
                        .frame(maxHeight: .infinity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        onSelection?(nil)
                    }
                }
            }
        }
        .task {
            await viewModel.retrieveProductImages()
        }
    }
}

private extension ProductImagePickerView {
    var imageGridView: some View {
        LazyVGrid(columns: [.init(.adaptive(minimum: Layout.gridColumnMinimumSize,
                                            maximum: .infinity),
                                  spacing: Layout.gridSpacing)],
                  spacing: Layout.gridSpacing) {
            ForEach(viewModel.productImages, id: \.imageID) { image in
                KFImage(URL(string: image.src)!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                    .aspectRatio(Layout.gridAspectRatio, contentMode: .fit)
                    .if(selectedImage == image, transform: { view in
                        view.border(Color.accentColor, width: Layout.gridBorderWidth)
                    })
                    .onTapGesture {
                        selectedImage = image
                        onSelection?(image)
                    }
            }
        }
    }
}

extension ProductImagePickerView {
    enum Layout {
        static let gridSpacing: CGFloat = 2
        static let gridColumnMinimumSize: CGFloat = 100
        static let gridAspectRatio: CGFloat = 1
        static let gridBorderWidth: CGFloat = 4
    }

    enum Localization {
        static let title = NSLocalizedString(
            "productImagePickerView.title",
            value: "Photos",
            comment: "Title of the product image picker screen"
        )
        static let cancel = NSLocalizedString(
            "productImagePickerView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the product image picker screen"
        )
        static let emptyStateTitle = NSLocalizedString(
            "productImagePickerView.emptyStateTitle",
            value: "No photos found",
            comment: "Title for the empty state of the product image picker screen"
        )
    }
}

#Preview {
    ProductImagePickerView(viewModel: .init(siteID: 123, productID: 2))
}
