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

            Text(Localization.noTextDetected)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .renderedIf(viewModel.shouldShowNoTextDetectedMessage)
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
        static let noTextDetected = NSLocalizedString(
            "No text detected. Please select another packaging photo or enter product details manually.",
            comment: "No text detected message on the add product from image form."
        )
    }
}

struct AddProductFromImageFormImageView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductFromImageFormImageView(viewModel: .init(siteID: 0,
                                                          source: .productsTab, onAddImage: { _ in nil }))
    }
}
