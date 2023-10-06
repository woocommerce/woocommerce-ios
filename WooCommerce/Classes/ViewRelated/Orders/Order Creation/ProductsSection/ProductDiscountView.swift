import SwiftUI
import Yosemite

struct ProductDiscountView: View {
    private let imageURL: URL?
    private let name: String
    private let stockLabel: String
    private let productRowViewModel: ProductRowViewModel

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
                HStack(alignment: .center, spacing: 8.0) {
                    ProductImageThumbnail(productImageURL: imageURL,
                                          productImageSize: 56.0,
                                          scale: 1,
                                          productImageCornerRadius: 4.0,
                                          foregroundColor: Color(UIColor.listSmallIcon))
                    VStack {
                        Text(name)
                        Text(stockLabel)
                            .foregroundColor(.gray)
                        CollapsibleProductCardPriceSummary(viewModel: productRowViewModel)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 4.0)
                        .inset(by: 0.25)
                        .stroke(Color(uiColor: .separator), lineWidth: 1.0)
                }
                .cornerRadius(4.0)
                .padding()
                VStack {
                    DiscountLineDetailsView(viewModel: discountViewModel)
                    Text("Debug: \(discountViewModel.amount)")
                    Button("Remove Discount") {
                        // TODO
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color(.error))
                    .buttonStyle(RoundedBorderedStyle(borderColor: .red))
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
        VStack(spacing: .zero) {
            Text("Fixed price discount")
                .renderedIf(viewModel.feeOrDiscountType == .fixed)
            Text("Percentage discount")
                .renderedIf(viewModel.feeOrDiscountType == .percentage)
            HStack {
                inputFixedField
                    .renderedIf(viewModel.feeOrDiscountType == .fixed)
                inputPercentageField
                    .renderedIf(viewModel.feeOrDiscountType == .percentage)
                Section {
                    if viewModel.isPercentageOptionAvailable {
                        // TODO: Decouple fees from discounts
                        Picker("", selection: $viewModel.feeOrDiscountType) {
                            Text(viewModel.percentSymbol).tag(FeeOrDiscountLineDetailsViewModel.FeeOrDiscountType.percentage)
                            Text(viewModel.currencySymbol).tag(FeeOrDiscountLineDetailsViewModel.FeeOrDiscountType.fixed)
                        }
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }
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

    private var inputPercentageField: some View {
        AdaptiveStack(horizontalAlignment: .leading) {
            Text(String.localizedStringWithFormat("Percentage (%1$@)", viewModel.percentSymbol))
                .bodyStyle()
                .fixedSize()

            HStack {
                Spacer()
                BindableTextfield("0",
                                  text: $viewModel.percentage,
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
