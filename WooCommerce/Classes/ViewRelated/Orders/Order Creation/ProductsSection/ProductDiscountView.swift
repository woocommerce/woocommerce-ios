import SwiftUI
import Yosemite

struct ProductDiscountView: View {

    @Environment(\.presentationMode) var presentation

    private let viewModel: ProductInOrderViewModel

    init(viewModel: ProductInOrderViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ScrollView {
                // TODO: Rounded border
                HStack {
                    ProductImageThumbnail(productImageURL: viewModel.productRowViewModel.imageURL,
                                          productImageSize: 56.0,
                                          scale: 1,
                                          productImageCornerRadius: 4.0,
                                          foregroundColor: Color(UIColor.listSmallIcon))
                    VStack {
                        Text(viewModel.productRowViewModel.name)
                        DiscountLineDetailsView(viewModel: viewModel.discountDetailsViewModel)
                    }
                }
            }
            .navigationTitle(Text("Add Discount"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentation.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        presentation.wrappedValue.dismiss()
                    }
                }
            }
            .wooNavigationBarStyle()
            .navigationViewStyle(.stack)
        }
    }
}

struct DiscountLineDetailsView: View {

    @ObservedObject private var viewModel: FeeOrDiscountLineDetailsViewModel

    init(viewModel: FeeOrDiscountLineDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Fixed price discount")
            HStack {
                inputFixedField
                Button("$") {}
                Button("%") {}
            }
            HStack {
                Text("-> 50% discount ")
                    .foregroundColor(.gray)
                Text("-15.00")
                    .foregroundColor(.green)
            }
            HStack {
                Text("Price after discount")
                Text("45.00")
                    .bold()
            }
            Button("Remove Discount") {}
            .errorStyle()
        }
    }

    private var inputFixedField: some View {
        AdaptiveStack(horizontalAlignment: .leading) {
            Text(String.localizedStringWithFormat("Amount (%1$@)", viewModel.currencySymbol))
                .bodyStyle()
                .fixedSize()

            HStack {
                Spacer()
                BindableTextfield(viewModel.amountPlaceholder,
                                  text: $viewModel.amount,
                                  focus: .constant(true))
                    .keyboardType(.numbersAndPunctuation)
            }
        }
        .frame(minHeight: 44)
        .padding([.leading, .trailing], 16)
    }
}

// MARK: Constants
private extension ProductDiscountView {
    enum Layout {
        static let sectionSpacing: CGFloat = 16.0
        static let noSpacing: CGFloat = 0.0
    }

    enum Localization {
        static let title = NSLocalizedString("Product", comment: "Title for the Product screen during order creation")
        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Product screen")
        static let addDiscount = NSLocalizedString("Add discount",
                                              comment: "Text for the button to add a discount to a product during order creation")
        static let couponsAndDiscountAlert = NSLocalizedString("Adding discount is currently not available. Remove coupons first.",
                                              comment: "Alert on the Product Details screen during order creation when" +
                                                               "we cannot add a discount because we have coupons")
        static let remove = NSLocalizedString("Remove Product from Order",
                                              comment: "Text for the button to remove a product from the order during order creation")
        static let discountTitle = NSLocalizedString("Discount", comment: "Title for the Discount section on the Product Details screen during order creation")
        static let editDiscount = NSLocalizedString("Edit", comment: "Text for the button to edit a discount to a product during order creation")
        static let discountAmount = NSLocalizedString("Amount", comment: "Title for the discount amount of a product during order creation")
    }
}

struct ProductInOrder_Previews: PreviewProvider {
    static var previews: some View {
        let productRowViewModel = ProductRowViewModel(productOrVariationID: 1,
                                            name: "Love Ficus",
                                            sku: "123456",
                                            price: "20",
                                            stockStatusKey: "instock",
                                            stockQuantity: 7,
                                            manageStock: true,
                                            canChangeQuantity: false,
                                            imageURL: nil)
        let viewModel = ProductInOrderViewModel(productRowViewModel: productRowViewModel,
                                                productDiscountConfiguration: nil, showCouponsAndDiscountsAlert: false,
                                                onRemoveProduct: {})
        ProductDiscountView(viewModel: viewModel)
    }
}

struct DiscountLineDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let feeOrDiscountViewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: true,
                                                                       baseAmountForPercentage: 10.0,
                                                                       initialTotal: "100.00",
                                                                       lineType: .discount,
                                                                       didSelectSave: { _ in })
        DiscountLineDetailsView(viewModel: feeOrDiscountViewModel)
    }
}
