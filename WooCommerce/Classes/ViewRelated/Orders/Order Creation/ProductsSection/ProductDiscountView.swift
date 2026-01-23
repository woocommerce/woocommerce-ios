import SwiftUI
import Yosemite
import struct WooFoundation.ProductImageThumbnail

struct ProductDiscountView: View {
    private let viewModel: ProductDiscountViewModel
    @ObservedObject private var discountDetailsViewModel: FeeOrDiscountLineDetailsViewModel

    private let minusSign: String = NumberFormatter().minusSign

    @Environment(\.presentationMode) var presentation

    init(viewModel: ProductDiscountViewModel) {
        self.viewModel = viewModel
        self.discountDetailsViewModel = viewModel.discountDetailsViewModel
    }

    var body: some View {
        NavigationView {
            ScrollView {
                HStack(alignment: .center, spacing: Layout.spacing) {
                    ProductImageThumbnail(productImageURL: viewModel.imageURL,
                                          productImageSize: Layout.productImageSize,
                                          scale: 1,
                                          productImageCornerRadius: Layout.frameCornerRadius,
                                          foregroundColor: Color(UIColor.listSmallIcon))
                    VStack(alignment: .leading) {
                        Text(viewModel.name)
                        CollapsibleProductCardPriceSummary(viewModel: viewModel.priceSummary)
                    }
                }
                .padding()
                .overlay {
                    RoundedRectangle(cornerRadius: Layout.frameCornerRadius)
                        .inset(by: Layout.inputFieldOverlayInset)
                        .stroke(Color(uiColor: .separator), lineWidth: Layout.borderLineWidth)
                }
                .cornerRadius(Layout.frameCornerRadius)
                .padding()
                VStack(alignment: .leading) {
                    DiscountLineDetailsView(viewModel: discountDetailsViewModel)
                    Text(Localization.discountDisallowedLabel)
                        .padding(.horizontal)
                        .foregroundColor(.red)
                        .renderedIf(viewModel.discountDetailsViewModel.discountExceedsProductPrice)
                    HStack {
                        Image(systemName: "arrow.turn.down.right")
                            .flipsForRightToLeftLayoutDirection(true)
                            .foregroundColor(.secondary)
                        Text(Localization.discountLabel)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let discountAmount = discountDetailsViewModel.finalAmountString {
                            Text(minusSign + discountAmount)
                                .foregroundColor(Color(uiColor: .withColorStudio(.green, shade: .shade50)))
                        }
                    }
                    .padding()
                    .renderedIf(discountDetailsViewModel.hasInputAmount)
                    HStack {
                        Text(Localization.priceAfterDiscountLabel)
                        Spacer()
                        if let price = viewModel.totalPricePreDiscount {
                            Text(discountDetailsViewModel.formattedPriceAfterDiscount)
                        }
                    }
                    .padding()
                    Divider()
                    Button(Localization.removeDiscountButton) {
                        discountDetailsViewModel.removeValue()
                        presentation.wrappedValue.dismiss()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color(.error))
                    .buttonStyle(RoundedBorderedStyle(borderColor: .red))
                    .renderedIf(discountDetailsViewModel.hasInputAmount)
                }
            }
            .navigationTitle(Text(viewModel.hasDiscount ? Localization.editDiscountLabel : Localization.addDiscountLabel))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton) {
                        presentation.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(Localization.addButton) {
                        discountDetailsViewModel.saveData()
                        presentation.wrappedValue.dismiss()
                    }
                    .disabled(viewModel.discountDetailsViewModel.discountExceedsProductPrice)
                }
            }
            .wooNavigationBarStyle()
            .navigationViewStyle(.stack)
        }
    }
}

private extension ProductDiscountView {
    enum Layout {
        static let frameCornerRadius: CGFloat = 4
        static let borderLineWidth: CGFloat = 1
        static let productImageSize: CGFloat = 56
        static let spacing: CGFloat = 8
        static let inputFieldOverlayInset: CGFloat = 0.25
    }

    enum Localization {
        static let addButton = NSLocalizedString(
            "Add",
            comment: "Button label that appears in shipment tracking screens and order note screens. When tapped, it adds a new tracking entry or saves a new order note respectively.")
        static let cancelButton = NSLocalizedString(
            "Cancel",
            comment: "Button text used to dismiss action sheets, web views, and modal screens in authentication flows, including the store picker screen, Jetpack setup, and site credential login screens.")
        static let removeDiscountButton = NSLocalizedString(
            "Remove Discount",
            comment: "Text for button to remove a discount in the discounts details screen")
        static let priceAfterDiscountLabel = NSLocalizedString(
            "Price after discount",
            comment: "The label that points to the updated price of a product after a discount has been applied")
        static let addDiscountLabel = NSLocalizedString(
            "Add Discount",
            comment: "This text appears as a navigation title on the discount configuration screen during order creation, displayed at the top of the view when users are adding a new discount to an order.")
        static let editDiscountLabel = NSLocalizedString(
            "Edit Discount",
            comment: "Text for the button to edit an existing discount to a product in the order screen")
        static let discountLabel = NSLocalizedString(
                    "Discount",
                    comment: "Text in the product row card when a discount has been added to a product")
        static let discountDisallowedLabel = NSLocalizedString(
            "productDiscountView.text.discountDisallowedLabel",
            value: "Discount cannot be greater than the price",
            comment: "Text describing the value that has been entered in the discount textfield is not allowed")
    }
}
