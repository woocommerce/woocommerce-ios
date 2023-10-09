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
                        CollapsibleProductCardPriceSummary(viewModel: productRowViewModel)
                    }
                }
                .padding()
                .overlay {
                    RoundedRectangle(cornerRadius: 4.0)
                        .inset(by: 0.25)
                        .stroke(Color(uiColor: .separator), lineWidth: 1.0)
                }
                .cornerRadius(4.0)
                .padding()
                VStack(alignment: .leading) {
                    DiscountLineDetailsView(viewModel: discountViewModel)
                    HStack {
                        Spacer()
                        Text("-" + (discountViewModel.finalAmountString ?? "0.00"))
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .renderedIf(discountViewModel.finalAmountString != nil)
                    HStack {
                        Text("Price after discount")
                        Spacer()
                        Text(discountViewModel.calculatePriceAfterDiscount(productRowViewModel.price ?? ""))
                    }
                    .padding()
                    Divider()
                    Button("Remove Discount") {
                        discountViewModel.removeValue()
                        presentation.wrappedValue.dismiss()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color(.error))
                    .buttonStyle(RoundedBorderedStyle(borderColor: .red))
                    .renderedIf(discountViewModel.amount != "" || discountViewModel.percentage != "")
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

struct DiscountLineDetailsView: View {

    @ObservedObject private var viewModel: FeeOrDiscountLineDetailsViewModel

    init(viewModel: FeeOrDiscountLineDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text("Fixed price discount")
                .renderedIf(viewModel.feeOrDiscountType == .fixed)
                .padding()
            Text("Percentage discount")
                .renderedIf(viewModel.feeOrDiscountType == .percentage)
                .padding()
            HStack {
                inputFixedField
                    .renderedIf(viewModel.feeOrDiscountType == .fixed)
                inputPercentageField
                    .renderedIf(viewModel.feeOrDiscountType == .percentage)
                Section {
                    if viewModel.isPercentageOptionAvailable {
                        // TODO: Decouple fees from discounts
                        Picker("", selection: $viewModel.feeOrDiscountType) {
                            Text(viewModel.currencySymbol)
                                .tag(FeeOrDiscountLineDetailsViewModel.FeeOrDiscountType.fixed)
                                .pickerStyle(SegmentedPickerStyle())
                            Text(viewModel.percentSymbol)
                                .tag(FeeOrDiscountLineDetailsViewModel.FeeOrDiscountType.percentage)
                                .pickerStyle(SegmentedPickerStyle())
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }
        }
    }

    private var inputFixedField: some View {
        AdaptiveStack(horizontalAlignment: .leading) {
            HStack {
                BindableTextfield(viewModel.amountPlaceholder == "0" ? "\(viewModel.currencySymbol) Enter amount" : viewModel.amountPlaceholder,
                                  text: $viewModel.amount, // TODO: viewModel.currencySymbol + amount
                                  focus: .constant(true))
                    .keyboardType(.numbersAndPunctuation)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding([.leading, .trailing], 16)
        .overlay {
            RoundedRectangle(cornerRadius: 4.0)
                .inset(by: 0.25)
                .stroke(Color(uiColor: .wooCommercePurple(.shade50)), lineWidth: 1.0)
        }
        .cornerRadius(4.0)
        .padding()
    }

    private var inputPercentageField: some View {
        AdaptiveStack(horizontalAlignment: .leading) {
            HStack {
                BindableTextfield(viewModel.amountPlaceholder == "0" ? "Enter percentage \(viewModel.currencySymbol)" : viewModel.amountPlaceholder,
                                  text: $viewModel.percentage,
                                  focus: .constant(true))
                    .keyboardType(.numbersAndPunctuation)
            }
        }
        .frame(minHeight: 44)
        .padding([.leading, .trailing], 16)
        .overlay {
            RoundedRectangle(cornerRadius: 4.0)
                .inset(by: 0.25)
                .stroke(Color(uiColor: .wooCommercePurple(.shade50)), lineWidth: 1.0)
        }
        .cornerRadius(4.0)
        .padding()
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
