import SwiftUI
import WooFoundation

struct AddCustomAmountView: View {
    @Binding var isPresented: Bool
    let onSubmit: (POSCustomAmountInput) -> Void

    @State private var viewModel: AddCustomAmountFormViewModel
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isNameFocused: Bool

    private var amountBinding: Binding<String> {
        Binding(
            get: { viewModel.amount },
            set: { viewModel.setAmount($0) }
        )
    }

    init(isPresented: Binding<Bool>,
         currencySettings: CurrencySettings,
         onSubmit: @escaping (POSCustomAmountInput) -> Void) {
        self._isPresented = isPresented
        self.onSubmit = onSubmit
        self._viewModel = State(wrappedValue: AddCustomAmountFormViewModel(currencySettings: currencySettings))
    }

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: Localization.title,
                backButtonConfiguration: .init(
                    state: .enabled,
                    action: { isPresented = false },
                    buttonIcon: "xmark"
                )
            )

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.xLarge) {
                    amountSection
                        .padding(.top, POSSpacing.xLarge)

                    Divider()

                    taxesRow

                    Divider()

                    nameSection

                    Spacer(minLength: POSSpacing.xxLarge)
                }
                .padding(.horizontal, POSHeaderLayoutConstants.sectionHorizontalPadding)
            }
            .scrollDismissesKeyboard(.interactively)

            addButton
                .padding(.horizontal, POSHeaderLayoutConstants.sectionHorizontalPadding)
                .padding(.vertical, POSPadding.medium)
        }
        .background(Color.posSurfaceBright.ignoresSafeArea())
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            Text(Localization.amountLabel)
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantLowest)

            ZStack {
                TextField("", text: amountBinding)
                    .keyboardType(.decimalPad)
                    .focused($isAmountFocused)
                    .opacity(0)
                    .accessibilityHidden(true)

                HStack(spacing: POSSpacing.xSmall) {
                    Text(viewModel.currencySymbol)
                        .font(.posHeadingBold)
                        .foregroundColor(.posOnSurface)

                    Text(viewModel.amount.isEmpty ? "0" : viewModel.amount)
                        .font(.posHeadingBold)
                        .foregroundColor(viewModel.amount.isEmpty ? .posOnSurfaceVariantLowest : .posOnSurface)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(POSPadding.large)
            .background(Color.posSurfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.large.value))
            .contentShape(Rectangle())
            .onTapGesture { focusAmountField() }
        }
    }

    private func focusAmountField() {
        isNameFocused = false
        isAmountFocused = false
        DispatchQueue.main.async {
            isAmountFocused = true
        }
    }

    private var taxesRow: some View {
        Toggle(isOn: $viewModel.isTaxable) {
            Text(Localization.chargeTaxes)
                .font(.posBodyLargeRegular())
                .foregroundColor(.posOnSurface)
        }
        .tint(.posPrimary)
        .padding(.vertical, POSPadding.small)
        .onChange(of: viewModel.isTaxable) { _, _ in
            isAmountFocused = false
            isNameFocused = false
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            Text(Localization.nameLabel)
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantLowest)

            TextField(Localization.namePlaceholder, text: $viewModel.name)
                .font(.posBodyLargeRegular())
                .foregroundColor(.posOnSurface)
                .focused($isNameFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .onSubmit(submit)
                .padding(.vertical, POSPadding.small)
        }
    }

    private var addButton: some View {
        Button(action: submit) {
            Text(Localization.addButton)
        }
        .buttonStyle(POSFilledButtonStyle(size: .normal))
        .frame(maxWidth: .infinity)
        .disabled(!viewModel.isAddEnabled)
        .accessibilityIdentifier("pos-add-custom-amount-submit-button")
    }

    private func submit() {
        guard let input = viewModel.resolvedInput() else { return }
        onSubmit(input)
        isPresented = false
    }
}

private extension AddCustomAmountView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.addCustomAmount.title",
            value: "Custom amount",
            comment: "Title of the full-screen Point of Sale form for adding a custom amount to the order.")
        static let amountLabel = NSLocalizedString(
            "pos.addCustomAmount.amountLabel",
            value: "Amount",
            comment: "Label above the amount field in the Point of Sale add custom amount form.")
        static let chargeTaxes = NSLocalizedString(
            "pos.addCustomAmount.chargeTaxes",
            value: "Charge taxes",
            comment: "Title of the taxable toggle in the Point of Sale add custom amount form.")
        static let nameLabel = NSLocalizedString(
            "pos.addCustomAmount.nameLabel",
            value: "Name",
            comment: "Label above the name field in the Point of Sale add custom amount form.")
        static let namePlaceholder = NSLocalizedString(
            "pos.addCustomAmount.namePlaceholder",
            value: "Custom amount",
            comment: "Placeholder for the name field in the Point of Sale add custom amount form.")
        static let addButton = NSLocalizedString(
            "pos.addCustomAmount.addButton",
            value: "Add custom amount",
            comment: "Primary button in the Point of Sale add custom amount form that adds the amount to the order.")
    }
}

#if DEBUG
#Preview {
    AddCustomAmountView(
        isPresented: .constant(true),
        currencySettings: CurrencySettings(),
        onSubmit: { _ in }
    )
}
#endif
