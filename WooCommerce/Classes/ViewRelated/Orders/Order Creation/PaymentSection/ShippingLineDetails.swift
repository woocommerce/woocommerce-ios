import SwiftUI
import struct Yosemite.ShippingLine

/// View to add/edit a single shipping line in an order, with the option to remove it.
///
struct ShippingLineDetails: View {

    /// View model to drive the view content
    ///
    let viewModel: NewOrderViewModel.PaymentDataViewModel

    /// Closure to be invoked when the status is updated.
    ///
    var didSelectSave: ((ShippingLine?) -> Void)

    let currencyFormatter: CurrencyFormatter

    @State private var amount: String

    @State private var methodTitle: String

    @Environment(\.presentationMode) private var presentation

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    init(viewModel: NewOrderViewModel.PaymentDataViewModel,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         didSelectSave: @escaping ((ShippingLine?) -> Void)) {
        self.viewModel = viewModel
        self.currencyFormatter = currencyFormatter
        self.didSelectSave = didSelectSave
        self.isExistingShippingLine = viewModel.shouldShowShippingTotal

        _amount = State(initialValue: viewModel.shippingTotal)
        _methodTitle = State(initialValue: viewModel.shippingMethodTitle)
    }

    private var isExistingShippingLine: Bool

    private var finalMethodTitle: String {
        methodTitle.isNotEmpty ? methodTitle : Localization.namePlaceholder
    }

    private var isDoneEnabled: Bool {
        guard let amountDecimal = currencyFormatter.convertToDecimal(from: amount) else {
            return false
        }

        return amountDecimal != 0 &&
        (amountDecimal != currencyFormatter.convertToDecimal(from: viewModel.shippingTotal) || finalMethodTitle != viewModel.shippingMethodTitle)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: .zero) {
                    Section {
                        Group {
                            TitleAndTextFieldRow(title: Localization.amountField,
                                                 placeholder: "",
                                                 text: $amount,
                                                 symbol: nil,
                                                 keyboardType: .decimalPad)
                            Divider()
                                .padding(.leading, Layout.dividerPadding)
                            TitleAndTextFieldRow(title: Localization.nameField,
                                                 placeholder: Localization.namePlaceholder,
                                                 text: $methodTitle,
                                                 symbol: nil,
                                                 keyboardType: .default)
                        }
                        .padding(.horizontal, insets: safeAreaInsets)
                        .addingTopAndBottomDividers()
                    }
                    .background(Color(.listForeground))

                    Spacer(minLength: Layout.sectionSpacing)

                    if isExistingShippingLine {
                        Section {
                            Button(Localization.remove) {
                                didSelectSave(nil)
                                presentation.wrappedValue.dismiss()
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(Color(.error))
                            .padding(.horizontal, insets: safeAreaInsets)
                            .addingTopAndBottomDividers()
                        }
                        .background(Color(.listForeground))
                    }
                }
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            .navigationTitle(Localization.shipping)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.close) {
                        presentation.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(Localization.done) {
                        saveData()
                        presentation.wrappedValue.dismiss()
                    }
                    .disabled(!isDoneEnabled)
                }
            }
        }
        .wooNavigationBarStyle()
    }

    private func saveData() {
        let shippingLine = ShippingLine(shippingID: 0,
                                        methodTitle: finalMethodTitle,
                                        methodID: "other",
                                        total: amount,
                                        totalTax: "",
                                        taxes: [])
        didSelectSave(shippingLine)
    }
}

// MARK: Constants
private extension ShippingLineDetails {
    enum Layout {
        static let sectionSpacing: CGFloat = 16.0
        static let dividerPadding: CGFloat = 16.0
    }

    enum Localization {
        static let addShipping = NSLocalizedString("Add Shipping", comment: "Title for the Shipping Line screen during order creation")
        static let shipping = NSLocalizedString("Shipping", comment: "Title for the Shipping Line Details screen during order creation")

        static let amountField = NSLocalizedString("Amount", comment: "Title for the amount field on the Shipping Line Details screen during order creation")
        static let nameField = NSLocalizedString("Name", comment: "Title for the name field on the Shipping Line Details screen during order creation")
        static let namePlaceholder = NSLocalizedString("Shipping",
                                                       comment: "Placeholder for the name field on the Shipping Line Details screen during order creation")

        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Shipping Line Details screen")
        static let done = NSLocalizedString("Done", comment: "Text for the done button in the Shipping Line Details screen")
        static let remove = NSLocalizedString("Remove Shipping from Order",
                                              comment: "Text for the button to remove a shipping line from the order during order creation")
    }
}

struct ShippingLineDetails_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NewOrderViewModel.PaymentDataViewModel(itemsTotal: "5",
                                                               shouldShowShippingTotal: true,
                                                               shippingTotal: "10",
                                                               shippingMethodTitle: "Shipping",
                                                               orderTotal: "15")
        ShippingLineDetails(viewModel: viewModel) { _ in }
    }
}
