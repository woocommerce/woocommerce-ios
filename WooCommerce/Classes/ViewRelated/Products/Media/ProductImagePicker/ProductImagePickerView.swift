import Kingfisher
import SwiftUI
import struct Yosemite.ProductImage

/// View to pick an image from an existing product.
///
struct ProductImagePickerView: View {
    typealias Completion = ((_ selectedImage: ProductImage?) -> Void)

    @ObservedObject private var viewModel: ProductImagePickerViewModel
    @State private var selectedImage: ProductImage?

    private var onSelection: (ProductImage) -> Void
    private var onDismiss: () -> Void

    init(viewModel: ProductImagePickerViewModel,
         onSelection: @escaping Completion,
         onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onSelection = onSelection
        self.onDismiss = onDismiss
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
                        onDismiss()
                    }
                }
                if let image = selectedImage {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(Localization.select) {
                            onSelection(image)
                        }
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
                    .aspectRatio(Layout.gridAspectRatio, contentMode: .fill)
                    .if(selectedImage == image, transform: { view in
                        view.border(Color.accentColor, width: Layout.gridBorderWidth)
                    })
                    .onTapGesture {
                        selectedImage = image
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
        static let emptyStateImageName = "photo.on.rectangle.angled"
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
        static let select = NSLocalizedString(
            "productImagePickerView.select",
            value: "Select",
            comment: "Button to select an item on the product image picker screen"
        )
        static let emptyStateTitle = NSLocalizedString(
            "productImagePickerView.emptyStateTitle",
            value: "No photos found",
            comment: "Title for the empty state of the product image picker screen"
        )
    }
}

#Preview {
    ProductImagePickerView(viewModel: .init(siteID: 123, productID: 2),
                           onSelection: { _ in },
                           onDismiss: {})
}
