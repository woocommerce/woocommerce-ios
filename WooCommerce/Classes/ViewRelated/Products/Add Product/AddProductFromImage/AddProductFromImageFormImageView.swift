import SwiftUI

/// Image header view in the add product from image form.
struct AddProductFromImageFormImageView: View {
    @ObservedObject private var viewModel: AddProductFromImageViewModel
    @State private var isShowingActionSheet: Bool = false

    init(viewModel: AddProductFromImageViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            EditableImageView(imageState: viewModel.imageState,
                              emptyContent: {
                VStack(spacing: Layout.verticalSpacing) {
                    Image(uiImage: .addImage)

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

            if let message = viewModel.textDetectionErrorMessage {
                Text(message)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
    }
}

private extension AddProductFromImageFormImageView {
    enum Layout {
        static let editImageSize: CGFloat = 30
        static let verticalSpacing: CGFloat = 16
        static let padding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    }

    enum Localization {
        static let packagingImageTip = NSLocalizedString(
            "Take a packaging photo to create product details with AI",
            comment: "Tip in the add product from image form to add a packaging image for AI-generated product details."
        )
    }
}

struct AddProductFromImageFormImageView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductFromImageFormImageView(viewModel: .init(siteID: 0,
                                                          source: .productsTab,
                                                          productName: nil,
                                                          onAddImage: { _ in nil }))
    }
}
