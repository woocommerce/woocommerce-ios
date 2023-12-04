import SwiftUI
import Combine
import WooFoundation

struct UpdateProductInventoryView: View {
    @ObservedObject private(set) var viewModel: UpdateProductInventoryViewModel

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    @Environment(\.dismiss) private var dismiss

    @State private var isKeyboardVisible = false

    init(inventoryItem: InventoryItem, siteID: Int64) {
        viewModel = UpdateProductInventoryViewModel(inventoryItem: inventoryItem, siteID: siteID)
    }

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
                            Text(Localization.productQuantityTitle)
                            Spacer()
                            TextField("", text: $viewModel.quantity)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 200, alignment: .trailing)
                                .fixedSize()
                        }
                        .padding([.top, .bottom], Layout.mediumSpacing)

                        Divider()
                            .padding(.trailing, -Layout.mediumSpacing)

                        Spacer()

                        Group {
                            Button(Localization.updateQuantityButtonTitle) {
                                Task { @MainActor in
                                    await viewModel.onTapUpdateStockQuantity()
                                    dismiss()
                                }
                            }
                            .renderedIf(viewModel.updateQuantityButtonMode == .customQuantity)

                            Button(Localization.increaseStockOnceButtonTitle) {
                                Task { @MainActor in
                                    await viewModel.onTapIncreaseStockQuantityOnce()
                                    dismiss()
                                }
                            }
                            .renderedIf(viewModel.updateQuantityButtonMode == .increaseOnce)

                            ProgressView()
                                .renderedIf(viewModel.updateQuantityButtonMode == .loading)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!viewModel.enableQuantityButton)
                        .padding(.bottom, Layout.mediumSpacing)

                        Button(Localization.viewProductDetailsButtonTitle) {}
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.bottom)
                    }
                    .padding()
                    .frame(minHeight: geometry.size.height)
                    .frame(width: geometry.size.width)
                    .navigationBarTitle(Localization.navigationBarTitle, displayMode: .inline)
                    .navigationBarItems(leading: Button(Localization.cancelButtonTitle) {
                        dismiss()
                    })
                    .onReceive(Publishers.keyboardHeight) { keyboardHeight in
                        isKeyboardVisible = keyboardHeight > 0
                    }
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
        static let productNameTitle = NSLocalizedString("updateProductInventoryView.productNameTitle",
                                                        value: "Product Name",
                                                        comment: "Product name label in the update product inventory view.")
        static let productQuantityTitle = NSLocalizedString("updateProductInventoryView.productQuantityTitle",
                                                            value: "Quantity",
                                                            comment: "Product quantity label in the update product inventory view.")
        static let viewProductDetailsButtonTitle = NSLocalizedString("updateProductInventoryView.viewProductDetailsButtonTitle",
                                                                     value: "View Product Details",
                                                                     comment: "Product detailsl button title.")
        static let navigationBarTitle = NSLocalizedString("updateProductInventoryView.navigationBarTitle",
                                                          value: "Product",
                                                          comment: "Navigation bar title of the update product inventory view.")
        static let cancelButtonTitle = NSLocalizedString("updateProductInventoryView.cancelButtonTitle",
                                                         value: "Cancel",
                                                         comment: "Cancel button title on the update product inventory view.")
        static let increaseStockOnceButtonTitle = NSLocalizedString("updateProductInventoryView.quantityButton.increaseStockOnceButtonTitle",
                                                                    value: "Quantity + 1",
                                                                    comment: "Stock quantity button when a tap increases the stock once.")
        static let updateQuantityButtonTitle = NSLocalizedString("updateProductInventoryView.quantityButton.updateQuantityButtonTitle",
                                                                 value: "Update quantity",
                                                                 comment: "Stock quantity button when the user adds a custom quantity.")
    }
}
