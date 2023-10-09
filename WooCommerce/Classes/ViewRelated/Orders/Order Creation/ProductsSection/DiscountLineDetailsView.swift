import SwiftUI

struct DiscountLineDetailsView: View {

    @ObservedObject private var viewModel: FeeOrDiscountLineDetailsViewModel

    init(viewModel: FeeOrDiscountLineDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(Localization.fixedPriceDiscountLabel)
                .renderedIf(viewModel.feeOrDiscountType == .fixed)
                .padding()
            Text(Localization.percentagePriceDiscountLabel)
                .renderedIf(viewModel.feeOrDiscountType == .percentage)
                .padding()
            HStack {
                inputFixedField
                    .renderedIf(viewModel.feeOrDiscountType == .fixed)
                inputPercentageField
                    .renderedIf(viewModel.feeOrDiscountType == .percentage)
                HStack(spacing: 0) {
                    Button(viewModel.currencySymbol) {
                        viewModel.feeOrDiscountType = .fixed
                    }
                    .buttonStyle(isPrimary: viewModel.feeOrDiscountType == .fixed)
                    .fixedSize(horizontal: true, vertical: false)
                    Button(viewModel.percentSymbol) {
                        viewModel.feeOrDiscountType = .percentage
                    }
                    .buttonStyle(isPrimary: viewModel.feeOrDiscountType == .percentage)
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
    }

    private var inputFixedField: some View {
        AdaptiveStack(horizontalAlignment: .leading) {
            HStack {
                BindableTextfield(Localization.fixedPriceDiscountInputPlaceholder,
                                  text: $viewModel.amount,
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
                BindableTextfield(Localization.percentagePriceDiscountInputPlaceholder,
                                  text: $viewModel.percentage,
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
}

fileprivate extension View {
    func buttonStyle(isPrimary: Bool) -> some View {
        self.modifier(DiscountButtonStyleModifier(isPrimary: isPrimary))
    }
}

fileprivate struct DiscountButtonStyleModifier: ViewModifier {
    var isPrimary: Bool

    func body(content: Content) -> some View {
        Group {
            if isPrimary {
                content
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                content
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

private extension DiscountLineDetailsView {
    enum Layout {
        static let padding: CGFloat = 16
        static let rowHeight: CGFloat = 44
        static let frameCornerRadius: CGFloat = 4
        static let borderLineWidth: CGFloat = 1
    }

    enum Localization {
        static let fixedPriceDiscountLabel = NSLocalizedString(
            "Fixed price discount",
            comment: "Label that shows the type of discount selected by a merchant in the discount view")
        static let fixedPriceDiscountInputPlaceholder = NSLocalizedString(
            "Enter amount",
            comment: "Text for the input textfield placeholder when no value has been added yet")
        static let percentagePriceDiscountLabel = NSLocalizedString(
            "Percentage discount",
            comment: "Label that shows the type of discount selected by a merchant in the discount view")
        static let percentagePriceDiscountInputPlaceholder = NSLocalizedString(
            "Enter percentage",
            comment: "Text for the input textfield placeholder when no value has been added yet")
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
