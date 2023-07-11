import SwiftUI

/// Image header view in the add product from image form.
struct AddProductFromImageFormImageView: View {
    @ObservedObject private var viewModel: AddProductFromImageViewModel
    @State private var isShowingActionSheet: Bool = false

    init(viewModel: AddProductFromImageViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        EditableImageView(imageState: viewModel.imageState,
                          emptyContent: {
            VStack(spacing: Layout.verticalSpacing) {
                Image(systemName: "photo")
                    .font(.system(size: Layout.emptyStateImageSize))
                Label {
                    Text(Localization.packagingImageTip)
                } icon: {
                    Image(uiImage: .sparklesImage)
                }
                .foregroundColor(.init(uiColor: .accent))
                .fixedSize(horizontal: false, vertical: true)
            }
        })
        .padding(Layout.padding)
        .overlay(alignment: .topTrailing) {
            Button {
                isShowingActionSheet = true
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: Layout.editImageSize))
                    .foregroundColor(.init(uiColor: .accent))
                    .renderedIf(viewModel.imageState.image != nil)
            }
        }
        .mediaSourceActionSheet(showsActionSheet: $isShowingActionSheet, selectMedia: { source in
            viewModel.addImage(from: source)
        })
    }
}

private extension AddProductFromImageFormImageView {
    enum Layout {
        static let emptyStateImageSize: CGFloat = 40
        static let editImageSize: CGFloat = 30
        static let verticalSpacing: CGFloat = 16
        static let padding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    }

    enum Localization {
        static let packagingImageTip = NSLocalizedString(
            "Take a photo of the product packaging to generate details with AI",
            comment: "Tip in the add product from image form to add a packaging image for AI-generated product details."
        )
    }
}

struct AddProductFromImageFormImageView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductFromImageFormImageView(viewModel: .init(siteID: 6, onAddImage: { _ in nil }))
    }
}
