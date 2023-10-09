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
                HStack(alignment: .center, spacing: Layout.spacing) {
                    ProductImageThumbnail(productImageURL: imageURL,
                                          productImageSize: Layout.productImageSize,
                                          scale: 1,
                                          productImageCornerRadius: Layout.frameCornerRadius,
                                          foregroundColor: Color(UIColor.listSmallIcon))
                    VStack {
                        Text(name)
                        CollapsibleProductCardPriceSummary(viewModel: productRowViewModel)
                    }
                }
                .padding()
                .overlay {
                    RoundedRectangle(cornerRadius: Layout.frameCornerRadius)
                        .inset(by: 0.25)
                        .stroke(Color(uiColor: .separator), lineWidth: Layout.borderLineWidth)
                }
                .cornerRadius(Layout.frameCornerRadius)
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

private extension ProductDiscountView {
    enum Layout {
        static let frameCornerRadius: CGFloat = 4
        static let borderLineWidth: CGFloat = 1
        static let productImageSize: CGFloat = 56
        static let spacing: CGFloat = 8
    }
}
