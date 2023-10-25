import SwiftUI

/// View to add/edit a single fee or discount line in an order, with the option to remove it.
///
struct FeeOrDiscountLineDetailsView: View {

    /// View model to drive the view content
    ///
    @ObservedObject private var viewModel: LegacyFeeOrDiscountLineDetailsViewModel

    /// Defines if the fixed amount input text field should be focused. Defaults to `true`
    ///
    @State private var focusFixedAmountInput: Bool = true

    /// Defines if the percentage amount input text field should be focused. Defaults to `false`
    ///
    @State private var focusPercentageAmountInput: Bool = false

    @Environment(\.presentationMode) var presentation

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    init(viewModel: LegacyFeeOrDiscountLineDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: .zero) {
                    Section {
                        if viewModel.isPercentageOptionAvailable {
                            Picker("", selection: $viewModel.discountType) {
                                Text(viewModel.percentSymbol).tag(LegacyFeeOrDiscountLineDetailsViewModel.DiscountType.percentage)
                                Text(viewModel.currencySymbol).tag(LegacyFeeOrDiscountLineDetailsViewModel.DiscountType.fixed)
                            }
                            .onChange(of: viewModel.discountType, perform: { type in
                                switch type {
                                case .fixed:
                                    focusFixedAmountInput = true
                                case .percentage:
                                    focusPercentageAmountInput = true
                                }
                            })
                            .pickerStyle(.segmented)
                            .padding()
                        }

                        Group {
                            switch viewModel.discountType {
                            case .fixed:
                                inputFixedField
                            case .percentage:
                                VStack {
                                    inputPercentageField
                                    TitleAndValueRow(title: Localization.calculatedAmount,
                                                     value: .init(placeHolder: viewModel.amountPlaceholder, content: viewModel.finalAmountString))
                                }
                            }
                        }
                        .background(Color(.listForeground(modal: false)))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, insets: safeAreaInsets)
                    }
                    .background(Color(.listForeground(modal: false)))
                    .addingTopAndBottomDividers()

                    Spacer(minLength: Layout.sectionSpacing)

                    if viewModel.isExistingLine {
                        Section {
                            Button(viewModel.lineTypeViewModel.removeButtonTitle) {
                                viewModel.removeValue()
                                presentation.wrappedValue.dismiss()
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(Color(.error))
                            .padding(.horizontal, insets: safeAreaInsets)
                            .addingTopAndBottomDividers()
                        }
                        .background(Color(.listForeground(modal: false)))
                    }
                }
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            .navigationTitle(viewModel.lineTypeViewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.close) {
                        presentation.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(Localization.done) {
                        viewModel.saveData()
                        presentation.wrappedValue.dismiss()
                    }
                    .disabled(viewModel.shouldDisableDoneButton)
                    .accessibilityIdentifier(viewModel.lineTypeViewModel.doneButtonAccessibilityIdentifier)
                }
            }
        }
        .wooNavigationBarStyle()
    }

    private var inputFixedField: some View {
        AdaptiveStack(horizontalAlignment: .leading) {
            Text(String.localizedStringWithFormat(Localization.amountField, viewModel.currencySymbol))
                .bodyStyle()
                .fixedSize()

            HStack {
                Spacer()
                BindableTextfield(viewModel.amountPlaceholder,
                                  text: $viewModel.amount,
                                  focus: $focusFixedAmountInput)
                    .keyboardType(.numbersAndPunctuation)
                    .onTapGesture {
                        focusFixedAmountInput = true
                    }
                    .accessibilityIdentifier(viewModel.lineTypeViewModel.fixedAmountFieldAccessibilityIdentifier)
            }
        }
        .frame(minHeight: Layout.rowHeight)
        .padding([.leading, .trailing], Layout.rowPadding)
    }

    private var inputPercentageField: some View {
        AdaptiveStack(horizontalAlignment: .leading) {
            Text(String.localizedStringWithFormat(Localization.percentageField, viewModel.percentSymbol))
                .bodyStyle()
                .fixedSize()

            HStack {
                Spacer()
                BindableTextfield("0",
                                  text: $viewModel.percentage,
                                  focus: $focusPercentageAmountInput)
                    .keyboardType(.numbersAndPunctuation)
                    .onTapGesture {
                        focusPercentageAmountInput = true
                    }
            }
        }
        .frame(minHeight: Layout.rowHeight)
        .padding([.leading, .trailing], Layout.rowPadding)
    }
}

// MARK: Constants
private extension FeeOrDiscountLineDetailsView {
    enum Layout {
        static let sectionSpacing: CGFloat = 16.0
        static let dividerPadding: CGFloat = 16.0
        static let rowHeight: CGFloat = 44
        static let rowPadding: CGFloat = 16
    }

    enum Localization {
        static let amountField = NSLocalizedString("Amount (%1$@)", comment: "Title for the amount field on the Fee/Discounts Details screen"
                                                   + "during order creation Parameters: %1$@ - currency symbol")

        static let percentageField = NSLocalizedString("Percentage (%1$@)",
                                                       comment: "Title for the amount field on the Fee/Discounts Details screen during order creation"
                                                       + "Parameters: %1$@ - percent sign")
        static let calculatedAmount = NSLocalizedString("Calculated amount",
                                                        comment: "Title for the helper field describing calculated amount for given percentage")

        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Fee/Discounts Details screen")
        static let done = NSLocalizedString("Done", comment: "Text for the done button in the Fee/Discounts Details screen")
    }
}

struct FeeOrDiscountLineDetails_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = LegacyFeeOrDiscountLineDetailsViewModel(isExistingLine: true,
                                                          baseAmountForPercentage: 200,
                                                          initialTotal: "10",
                                                          lineType: .fee,
                                                          didSelectSave: { _ in })
        FeeOrDiscountLineDetailsView(viewModel: viewModel)
    }
}
