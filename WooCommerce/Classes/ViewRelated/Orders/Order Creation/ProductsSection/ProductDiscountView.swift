import SwiftUI
import Yosemite

struct ProductDiscountView: View {
    private let imageURL: URL?
    private let name: String
    private let stockLabel: String
    private let productRowViewModel: ProductRowViewModel

    private let minusSign: String = NumberFormatter().minusSign

    @Environment(\.presentationMode) var presentation

    @ObservedObject private var discountViewModel: FeeOrDiscountLineDetailsViewModel

    init(imageURL: URL?,
         name: String,
         stockLabel: String,
         productRowViewModel: ProductRowViewModel,
         discountViewModel: FeeOrDiscountLineDetailsViewModel) {
        self.imageURL = imageURL
        self.name = name
        self.stockLabel = stockLabel
        self.productRowViewModel = productRowViewModel
        self.discountViewModel = discountViewModel
    }

    var body: some View {
        NavigationView {
            ScrollView {
                HStack(alignment: .center, spacing: Layout.spacing) {
                    ProductImageThumbnail(productImageURL: imageURL,
                                          productImageSize: Layout.productImageSize,
                                          scale: 1,
                                          productImageCornerRadius: Layout.frameCornerRadius,
                                          foregroundColor: Color(UIColor.listSmallIcon))
                    VStack(alignment: .leading) {
                        Text(name)
                        CollapsibleProductCardPriceSummary(viewModel: productRowViewModel)
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
                    DiscountLineDetailsView(viewModel: discountViewModel)
                    HStack {
                        Image(systemName: "arrow.turn.down.right")
                            .foregroundColor(.secondary)
                        Text(Localization.discountLabel)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let discountAmount = discountViewModel.finalAmountString {
                            Text(minusSign + discountAmount)
                                .foregroundColor(Color(uiColor: .withColorStudio(.green, shade: .shade50)))
                        }
                    }
                    .padding()
                    .renderedIf(discountViewModel.hasInputAmount)
                    HStack {
                        Text(Localization.priceAfterDiscountLabel)
                        Spacer()
                        if let price = productRowViewModel.price {
                            Text(discountViewModel.calculatePriceAfterDiscount(price))
                        }
                    }
                    .padding()
                    Divider()
                    Button(Localization.removeDiscountButton) {
                        discountViewModel.removeValue()
                        presentation.wrappedValue.dismiss()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color(.error))
                    .buttonStyle(RoundedBorderedStyle(borderColor: .red))
                    .renderedIf(discountViewModel.hasInputAmount)
                }
            }
            .navigationTitle(Text(productRowViewModel.hasDiscount ? Localization.editDiscountLabel : Localization.addDiscountLabel))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton) {
                        presentation.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(Localization.addButton) {
                        discountViewModel.saveData()
                        presentation.wrappedValue.dismiss()
                    }
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
            comment: "Text for the add button in the discounts details screen")
        static let cancelButton = NSLocalizedString(
            "Cancel",
            comment: "Text for the cancel button in the discounts details screen")
        static let removeDiscountButton = NSLocalizedString(
            "Remove Discount",
            comment: "Text for button to remove a discount in the discounts details screen")
        static let priceAfterDiscountLabel = NSLocalizedString(
            "Price after discount",
            comment: "The label that points to the updated price of a product after a discount has been applied")
        static let addDiscountLabel = NSLocalizedString(
            "Add Discount",
            comment: "Text for the button to add a discount to a product in the order screen")
        static let editDiscountLabel = NSLocalizedString(
            "Edit Discount",
            comment: "Text for the button to edit an existing discount to a product in the order screen")
        static let discountLabel = NSLocalizedString(
                    "Discount",
                    comment: "Text in the product row card when a discount has been added to a product")
    }
}
