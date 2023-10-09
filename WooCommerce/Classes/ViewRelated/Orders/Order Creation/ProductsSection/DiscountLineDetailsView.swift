import SwiftUI

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
                        .frame(minWidth: Layout.rowHeight, minHeight: Layout.rowHeight)
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
        .frame(maxWidth: .infinity, minHeight: Layout.rowHeight)
        .padding([.leading, .trailing], Layout.padding)
        .overlay {
            RoundedRectangle(cornerRadius: Layout.frameCornerRadius)
                .inset(by: 0.25)
                .stroke(Color(uiColor: .wooCommercePurple(.shade50)), lineWidth: Layout.borderLineWidth)
        }
        .cornerRadius(Layout.frameCornerRadius)
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
        .frame(minHeight: Layout.rowHeight)
        .padding([.leading, .trailing], Layout.padding)
        .overlay {
            RoundedRectangle(cornerRadius: Layout.frameCornerRadius)
                .inset(by: 0.25)
                .stroke(Color(uiColor: .wooCommercePurple(.shade50)), lineWidth: Layout.borderLineWidth)
        }
        .cornerRadius(Layout.frameCornerRadius)
        .padding()
    }
}

private extension DiscountLineDetailsView {
    enum Layout {
        static let padding: CGFloat = 16
        static let rowHeight: CGFloat = 44
        static let frameCornerRadius: CGFloat = 4
        static let borderLineWidth: CGFloat = 1
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
