import SwiftUI
import Combine
import WooFoundation

struct UpdateProductInventoryView: View {
    @ObservedObject private(set) var viewModel: UpdateProductInventoryViewModel

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    @Environment(\.presentationMode) var presentationMode

    @State private var isKeyboardVisible = false
    @State private var updateInventoryButtonTitle: String = Localization.IncreaseStockOnceButtonTitle

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .center, spacing: 0) {
                        AsyncImage(url: viewModel.imageURL) { image in
                            image.resizable()
                        } placeholder: {
                            Rectangle()
                                .foregroundColor(.gray)
                        }
                        .frame(width: Layout.imageDimensionsSize * scale, height: Layout.imageDimensionsSize * scale)
                        .cornerRadius(Layout.imageCornerRadius)
                        .padding(.bottom, Layout.largeSpacing)
                        .padding(.top, Layout.mediumSpacing)
                        .renderedIf(!isKeyboardVisible)

                        Group {
                            Text(viewModel.name)
                                .headlineStyle()
                                .renderedIf(!viewModel.showLoadingName)

                            ProgressView()
                                .renderedIf(viewModel.showLoadingName)
                        }
                        .padding(.bottom, Layout.smallSpacing)

                        Text(viewModel.sku)
                            .subheadlineStyle()
                            .padding(.bottom, Layout.largeSpacing)

                        Divider()
                            .padding(.trailing, -Layout.mediumSpacing)

                        HStack {
                            Text(Localization.ProductQuantityTitle)
                            Spacer()
                            TextField("", text: $viewModel.quantity, onEditingChanged: { _ in
                                updateInventoryButtonTitle = Localization.UpdateQuantityButtonTitle
                            })
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        }
                        .padding([.top, .bottom], Layout.mediumSpacing)

                        Divider()
                            .padding(.trailing, -Layout.mediumSpacing)

                        Spacer()

                        Button(updateInventoryButtonTitle) {}
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.bottom, Layout.mediumSpacing)

                        Button(Localization.ViewProductDetailsButtonTitle) {

                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.bottom)
                    }
                    .frame(minHeight: geometry.size.height)
                    .padding()
                    .navigationBarTitle(Localization.NavigationBarTitle, displayMode: .inline)
                    .navigationBarItems(leading: Button(Localization.CancelButtonTitle) {
                        presentationMode.wrappedValue.dismiss()
                    })
                    .onReceive(Publishers.keyboardHeight) { keyboardHeight in
                        isKeyboardVisible = keyboardHeight > 0
                    }
                    .frame(width: geometry.size.width)
                }
            }
        }
    }
}

extension UpdateProductInventoryView {
    enum Layout {
        static let imageDimensionsSize: CGFloat = 160
        static let imageCornerRadius: CGFloat = 8
        static let largeSpacing: CGFloat = 32
        static let mediumSpacing: CGFloat = 16
        static let smallSpacing: CGFloat = 8
    }

    enum Localization {
        static let ProductNameTitle = NSLocalizedString("updateProductInventoryView.productNameTitle",
                                                        value: "Product Name",
                                                        comment: "Product name label in the update product inventory view.")
        static let ProductQuantityTitle = NSLocalizedString("updateProductInventoryView.productQuantityTitle",
                                                            value: "Quantity",
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
        static let IncreaseStockOnceButtonTitle = NSLocalizedString("updateProductInventoryView.quantityButton.increaseStockOnceButtonTitle",
                                                                    value: "Quantity + 1",
                                                                    comment: "Stock quantity button when a tap increases the stock once.")
        static let UpdateQuantityButtonTitle = NSLocalizedString("updateProductInventoryView.quantityButton.updateQuantityButtonTitle",
                                                                 value: "Update quantity",
                                                                 comment: "Stock quantity button when the user adds a custom quantity.")
    }
}
