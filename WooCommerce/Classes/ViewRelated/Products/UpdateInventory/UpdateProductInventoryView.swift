import SwiftUI
import Combine
import WooFoundation

struct UpdateProductInventoryView: View {
    @State private var quantity: Int = 2000
    @ObservedObject private(set) var viewModel = UpdateProductInventoryViewModel()

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    @Environment(\.presentationMode) var presentationMode

    @State private var isKeyboardVisible = false

    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 0) {
                    AsyncImage(url: URL(string: "https://picsum.photos/160")) { image in
                        image.resizable()
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.gray)
                    }
                    .frame(width: Layout.imageDimensionsSize * scale, height: Layout.imageDimensionsSize * scale)
                    .cornerRadius(Layout.imageCornerRadius)
                    .padding(.bottom, Layout.largeVerticalSpacing)
                    .renderedIf(!isKeyboardVisible)

                Text(Localization.ProductNameTitle)
                    .headlineStyle()
                    .padding(.bottom, Layout.smallVerticalSpacing)


                Text("123-SKU-456")
                    .subheadlineStyle()
                    .padding(.bottom, Layout.largeVerticalSpacing)

                Divider()

                HStack {
                    Text(Localization.ProductQuantityTitle)
                    Spacer()
                    TextField("", text: $viewModel.quantity)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                .padding([.top, .bottom], Layout.mediumVerticalSpacing)

                Divider()

                Spacer()

                Button("Quantity + 1") {

                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("")
                .padding(.bottom, Layout.mediumVerticalSpacing)

                Button(Localization.ViewProductDetailsButtonTitle) {

                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("")
                .padding(.bottom)
            }
            .padding()
            .navigationBarTitle(Localization.NavigationBarTitle, displayMode: .inline)
            .navigationBarItems(leading: Button(Localization.CancelButtonTitle) {
                presentationMode.wrappedValue.dismiss()
            })
            .onReceive(Publishers.keyboardHeight) { keyboardHeight in
                self.isKeyboardVisible = keyboardHeight > 0
            }
        }
    }
}

extension UpdateProductInventoryView {
    enum Layout {
        static let imageDimensionsSize: CGFloat = 160
        static let imageCornerRadius: CGFloat = 8
        static let largeVerticalSpacing: CGFloat = 32
        static let mediumVerticalSpacing: CGFloat = 16
        static let smallVerticalSpacing: CGFloat = 8
    }

    enum Localization {
        static let ProductNameTitle = NSLocalizedString("updateProductInventoryView.productNameTitle",
                                                        value: "Product Name",
                                                        comment: "Product name label in the update product inventory view.")
        static let ProductQuantityTitle = NSLocalizedString("updateProductInventoryView.productQuantityTitle",
                                                        value: "Product Name",
                                                        comment: "Product quantity label in the update product inventory view.")
        static let ViewProductDetailsButtonTitle = NSLocalizedString("updateProductInventoryView.viewProductDetailsButtonTitle",
                                                        value: "View Product Details",
                                                        comment: "Product detailsl button title.")
        static let NavigationBarTitle = NSLocalizedString("updateProductInventoryView.navigationBarTitle",
                                                        value: "Product",
                                                        comment: "Navigation bar title of the update product inventory view.")
        static let CancelButtonTitle = NSLocalizedString("updateProductInventoryView.cancelButtonTitle",
                                                        value: "Cancel",
                                                        comment: "Cancel button title on the update product inventory view.")
    }
}

struct UpdateProductInventoryView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateProductInventoryView()
    }
}
