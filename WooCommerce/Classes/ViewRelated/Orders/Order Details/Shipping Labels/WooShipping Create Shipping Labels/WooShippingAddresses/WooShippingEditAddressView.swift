import SwiftUI

/// Possible statuses for a Woo Shipping address.
enum WooShippingAddressStatus {
    case verified
    case unverified
    case missingInformation
}

/// View for editing an address in the Woo Shipping label creation flow.
struct WooShippingEditAddressView: View {
    @ObservedObject var viewModel: WooShippingEditAddressViewModel

    /// Tracks the focused address field.
    @FocusState private var focusedField: WooShippingAddressFieldType?

    /// Tracks the previously focused address field.
    ///
    /// Used to validate the field when the focus changes.
    @State private var previousFocusedField: WooShippingAddressFieldType?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.sizeCategory) private var sizeCategory

    @State private var isPresentingCountrySelector: Bool = false
    @State private var isPresentingStateSelector: Bool = false
    @State private var actionType: ActionType?

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.verticalSpacing) {
                AddressTextField(field: viewModel.name,
                                 focused: $focusedField)
                if viewModel.showCompanyField {
                    AddressTextField(field: viewModel.company,
                                     focused: $focusedField)
                } else {
                    Button {
                        withAnimation {
                            viewModel.showCompanyField = true
                        }
                    } label: {
                        Text(Localization.addCompany)
                    }
                    .buttonStyle(PlusButtonStyle())
                    .font(.subheadline)
                    .bold()
                }
                AddressSelection(field: viewModel.country) {
                    isPresentingCountrySelector = true
                }
                .padding(.top, Constants.extraPadding)
                AddressTextField(field: viewModel.address,
                                 focused: $focusedField)
                AddressTextField(field: viewModel.city,
                                 focused: $focusedField)
                AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .top, spacing: Constants.innerSpacing) {
                    if viewModel.statesOfSelectedCountry.isNotEmpty {
                        AddressSelection(field: viewModel.state) {
                            isPresentingStateSelector = true
                        }
                    } else {
                        AddressTextField(field: viewModel.state,
                                         focused: $focusedField)
                    }
                    AddressTextField(field: viewModel.postalCode,
                                     focused: $focusedField)
                }
                .padding(.bottom, Constants.extraPadding)
                AddressTextField(field: viewModel.email,
                                 focused: $focusedField,
                                 keyboardType: .emailAddress)
                AddressTextField(field: viewModel.phone,
                                 focused: $focusedField,
                                 keyboardType: .phonePad)
                .padding(.bottom, Constants.extraPadding)
                if viewModel.showSaveAsDefault {
                    Toggle(Localization.defaultAddress, isOn: $viewModel.isDefaultAddress)
                        .font(.subheadline)
                        .tint(Color(.accent))
                }

                if sizeCategory.isAccessibilityCategory {
                    ctaFooter(isScrollViewEmbedded: true)
                }
            }
            .padding()
            .onChange(of: focusedField) { _, newField in
                if let previousFocusedField {
                    viewModel.validate(previousFocusedField)
                }
                previousFocusedField = newField
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: {
                        focusPreviousField()
                    }, label: {
                        Image(systemName: "chevron.backward")
                    })
                    .disabled(focusedField == WooShippingAddressFieldType.allCases.first)
                    Button(action: {
                        focusNextField()
                    }, label: {
                        Image(systemName: "chevron.forward")
                    })
                    .disabled(focusedField == WooShippingAddressFieldType.allCases.last)
                    Spacer()
                    Button {
                        dismissKeyboard()
                    } label: {
                        Text(Localization.done)
                            .bold()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.cancel) {
                    dismiss()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !sizeCategory.isAccessibilityCategory {
                ctaFooter(isScrollViewEmbedded: false)
            }
        }
        .sheet(item: $viewModel.normalizeAddressVM) { viewModel in
            NavigationStack {
                WooShippingNormalizeAddressView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $isPresentingCountrySelector) {
            NavigationStack {
                FilterListSelector(viewModel: viewModel.countrySelectorVM)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                isPresentingCountrySelector = false
                            } label: {
                                Text(Localization.done)
                                    .bold()
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $isPresentingStateSelector) {
            NavigationStack {
                FilterListSelector(viewModel: viewModel.stateSelectorVM)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                isPresentingStateSelector = false
                            } label: {
                                Text(Localization.done)
                                    .bold()
                            }
                        }
                    }
            }
        }
        .alert(
            viewModel.addressErrorState?.title ?? "",
            isPresented: $viewModel.isShowingAddressErrorAlert,
            actions: {
                Button(Localization.AlertButtons.retry) {
                    Task { @MainActor in
                        switch viewModel.addressErrorState {
                        case .validation:
                            await viewModel.remotelyValidateAddress()
                        case .updateOrigin(let address), .updateDestination(let address):
                            viewModel.updateConfirmedAddress(address)
                        case nil:
                            break
                        }
                    }
                }
                Button(
                    Localization.AlertButtons.close,
                    role: .cancel
                ) {}
            }, message: {
                Text(viewModel.addressErrorState?.message ?? "")
            }
        )
    }

    private func ctaFooter(isScrollViewEmbedded: Bool) -> some View {
        VStack(spacing: .zero) {
            Divider()
                .ignoresSafeArea(edges: [.horizontal])
                .padding(
                    /// When embedded in scroll view
                    /// we use a negative value to neglect the parent padding for the divider
                    isScrollViewEmbedded ? .horizontal : [],
                    -Constants.defaultPadding
                )

            VStack(spacing: Constants.verticalSpacing) {
                HStack {
                    Image(systemName: viewModel.status == .verified ? "checkmark.circle" : "exclamationmark.circle")
                    Text(viewModel.statusLabel)
                }
                .font(.subheadline)
                .foregroundStyle(viewModel.status == .verified ? Constants.green : Constants.red)

                Button(Localization.Button.label(for: viewModel.status)) {
                    actionType = .validateOrConfirm
                    switch viewModel.status {
                    case .verified:
                        dismiss()
                    case .unverified:
                        Task { @MainActor in
                            await viewModel.remotelyValidateAddress()
                        }
                    case .missingInformation:
                        break
                    }
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isLoading &&
                                                       actionType == .validateOrConfirm))
                .disabled(viewModel.status == .missingInformation)
                .renderedIf(!viewModel.canConfirmWithoutVerification)

                Button(Localization.useAddressAsEntered) {
                    actionType = .proceedWithoutValidation
                    viewModel.proceedWithInputAddress()
                }
                .buttonStyle(SecondaryLoadingButtonStyle(isLoading: viewModel.isLoading &&
                                                         actionType == .proceedWithoutValidation))
                .renderedIf(viewModel.canConfirmWithoutVerification)
            }
            .padding(isScrollViewEmbedded ? .vertical : .all)
        }
        .background(Color(uiColor: .systemBackground))
    }

    private struct AddressTextField: View {
        @ObservedObject var field: WooShippingAddressField

        /// The focused state of the field.
        @FocusState.Binding var focused: WooShippingAddressFieldType?

        var keyboardType = UIKeyboardType.default

        var body: some View {
            VStack(spacing: Constants.innerSpacing) {
                HStack(spacing: Constants.requiredLabelSpacing) {
                    Text(Localization.title(for: field.type))
                    if field.required {
                        Text("*")
                    }
                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(Color(.text))
                TextField(Localization.title(for: field.type), text: $field.value, prompt: Text(field.required ? "" : Localization.optional))
                    .keyboardType(keyboardType)
                    .focused($focused, equals: field.type)
                    .onChange(of: field.value) {
                        field.clearError()
                    }
                    .padding()
                    .roundedBorder(cornerRadius: Constants.cornerRadius,
                                   lineColor: Constants.fieldBorderColor(focused: focused == field.type, valid: field.errorMessage == nil),
                                   lineWidth: focused == field.type ? 2 : Constants.defaultBorderWidth)
                if let errorMessage = field.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(Constants.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private struct AddressSelection: View {
        /// Which address field to display.
        @ObservedObject var field: WooShippingAddressField

        /// The action to perform when the button is tapped.
        var action: () -> Void

        var body: some View {
            VStack(spacing: Constants.innerSpacing) {
                HStack(spacing: Constants.requiredLabelSpacing) {

                    Text(Localization.title(for: field.type))
                    if field.required {
                        Text("*")
                    }
                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(Color(.text))
                Button {
                    action()
                } label: {
                    HStack {
                        Text(field.displayValue ?? field.value)
                            .bodyStyle()
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundStyle(Color(.accent))
                    }
                    .padding()
                    .roundedBorder(cornerRadius: Constants.cornerRadius,
                                   lineColor: Constants.defaultBorderColor,
                                   lineWidth: Constants.defaultBorderWidth)
                }
                if let errorMessage = field.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(Constants.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

extension WooShippingEditAddressView {

    /// Navigates to the next address field in the form.
    private func focusNextField() {
        switch focusedField {
        case .name:
            focusedField = viewModel.showCompanyField ? .company : .address
        case .company:
            focusedField = .address
        case .address:
            focusedField = .city
        case .city:
            focusedField = .postalCode
        case .postalCode:
            focusedField = .email
        case .email:
            focusedField = .phone
        case .phone:
            focusedField = nil
        case .none, .country, .state:
            break
        }
    }

    /// Navigates to the previous address field in the form.
    private func focusPreviousField() {
        switch focusedField {
        case .name:
            focusedField = nil
        case .company:
            focusedField = .name
        case .address:
            focusedField = viewModel.showCompanyField ? .company : .name
        case .city:
            focusedField = .address
        case .postalCode:
            focusedField = .city
        case .email:
            focusedField = .postalCode
        case .phone:
            focusedField = .email
        case .none, .country, .state:
            break
        }
    }

    /// Dismisses the keyboard.
    private func dismissKeyboard() {
        focusedField = nil
    }
}

private extension WooShippingEditAddressView {
    enum ActionType {
        case validateOrConfirm
        case proceedWithoutValidation
    }

    enum Constants {
        static let verticalSpacing: CGFloat = 16
        static let defaultPadding: CGFloat = 16
        static let innerSpacing: CGFloat = 8
        static let extraPadding: CGFloat = 24
        static let cornerRadius: CGFloat = 8
        static let defaultBorderColor = Color(.separator)
        static let defaultBorderWidth: CGFloat = 1
        static let green = Color(UIColor(light: .withColorStudio(.green, shade: .shade60),
                                         dark: .withColorStudio(.green, shade: .shade40)))
        static let red = Color(UIColor(light: .withColorStudio(.red, shade: .shade60),
                                       dark: .withColorStudio(.red, shade: .shade40)))
        static let requiredLabelSpacing: CGFloat = 4
        static func fieldBorderColor(focused: Bool, valid: Bool) -> Color {
            guard valid else {
                return red
            }
            return focused ? Color(.accent) : defaultBorderColor
        }
    }

    enum Localization {
        static func title(for type: WooShippingAddressFieldType) -> String {
            switch type {
            case .name: return Localization.name
            case .company: return Localization.company
            case .country: return Localization.country
            case .address: return Localization.address
            case .city: return Localization.city
            case .state: return Localization.state
            case .postalCode: return Localization.postalCode
            case .email: return Localization.email
            case .phone: return Localization.phone
            }
        }
        static let name = NSLocalizedString("wooShipping.createLabels.editAddress.name",
                                            value: "Name",
                                            comment: "Label for the name field when editing an address in the Woo Shipping label creation flow")
        static let company = NSLocalizedString("wooShipping.createLabels.editAddress.company",
                                                  value: "Company",
                                                    comment: "Label for the company field when editing an address in the Woo Shipping label creation flow")
        static let addCompany = NSLocalizedString("wooShipping.createLabels.editAddress.addCompany",
                                                    value: "Add company",
                                                    comment: "Button to add a company field when editing an address in the Woo Shipping label creation flow")
        static let country = NSLocalizedString("wooShipping.createLabels.editAddress.country",
                                                    value: "Country",
                                                    comment: "Label for the country field when editing an address in the Woo Shipping label creation flow")
        static let address = NSLocalizedString("wooShipping.createLabels.editAddress.address",
                                                    value: "Address",
                                                    comment: "Label for the address field when editing an address in the Woo Shipping label creation flow")
        static let city = NSLocalizedString("wooShipping.createLabels.editAddress.city",
                                                    value: "City",
                                                    comment: "Label for the city field when editing an address in the Woo Shipping label creation flow")
        static let state = NSLocalizedString("wooShipping.createLabels.editAddress.state",
                                                    value: "State",
                                                    comment: "Label for the state field when editing an address in the Woo Shipping label creation flow")
        static let postalCode = NSLocalizedString("wooShipping.createLabels.editAddress.postalCode",
                                                    value: "Postal code",
                                                    comment: "Label for the postal code field when editing an address in the Woo Shipping label creation flow")
        static let email = NSLocalizedString("wooShipping.createLabels.editAddress.email",
                                                    value: "Email Address",
                                                    comment: "Label for the email field when editing an address in the Woo Shipping label creation flow")
        static let phone = NSLocalizedString("wooShipping.createLabels.editAddress.phone",
                                                    value: "Phone",
                                                    comment: "Label for the phone field when editing an address in the Woo Shipping label creation flow")
        static let optional = NSLocalizedString("wooShipping.createLabels.editAddress.optional",
                                                    value: "Optional",
                                                    comment: "Text indicating that a field is optional")
        static let defaultAddress = NSLocalizedString("wooShipping.createLabels.editAddress.defaultAddress",
                                                    value: "Save as default origin address",
                                                    comment: "Label for the default address toggle in the Woo Shipping label creation flow")
        static let cancel = NSLocalizedString("wooShipping.createLabels.editAddress.cancel",
                                            value: "Cancel",
                                            comment: "Button to cancel editing an address in the Woo Shipping label creation flow")
        static let done = NSLocalizedString("wooShipping.createLabels.editAddress.done",
                                            value: "Done",
                                            comment: "Button to dismiss the keyboard")
        static let useAddressAsEntered = NSLocalizedString(
            "wooShipping.createLabels.editAddress.useAddressAsEntered",
            value: "Use address as entered",
            comment: "Button to proceed with the input address even when validation fails"
        )

        enum Button {
            static func label(for status: WooShippingAddressStatus) -> String {
                switch status {
                case .verified:
                    return close
                case .unverified:
                    return validateAddress
                case .missingInformation:
                    return addMissingInformation
                }
            }
            static let close = NSLocalizedString("wooShipping.createLabels.editAddress.close",
                                                 value: "Close",
                                                 comment: "Button to close the address editing view in the Woo Shipping label creation flow")
            static let validateAddress = NSLocalizedString("wooShipping.createLabels.editAddress.validateAddress",
                                                           value: "Validate & Save",
                                                           comment: "Button label indicating the address needs to be validated and saved for a Woo Shipping label")
            static let addMissingInformation = NSLocalizedString("wooShipping.createLabels.editAddress.addMissingInformation",
                                                                 value: "Add Missing Information",
                                                                 comment: "Button label indicating the address is missing information for a Woo Shipping label")
        }

        enum AlertButtons {
            static let retry = NSLocalizedString(
                "wooShipping.createLabels.editAddress.alert.retry",
                value: "Retry",
                comment: "Button label indicating the user wants to retry an action"
            )

            static let close = NSLocalizedString(
                "wooShipping.createLabels.editAddress.alert.close",
                value: "Close",
                comment: "Button label indicating the user wants to close an alert"
            )
        }
    }
}

#Preview("Without Company") {
    WooShippingEditAddressView(viewModel: .init(type: .origin,
                                                id: UUID().uuidString,
                                                name: "HEADQUARTERS",
                                                company: "",
                                                country: "UNITED STATES",
                                                address: "15 ALGONKIN ST",
                                                city: "TICONDEROGA",
                                                state: "NY",
                                                postalCode: "12883-1487",
                                                email: "",
                                                phone: "",
                                                isDefaultAddress: true,
                                                showCompanyField: false,
                                                isVerified: true))
}

#Preview("With Company") {
    WooShippingEditAddressView(viewModel: .init(type: .destination(orderID: 123),
                                                id: UUID().uuidString,
                                                name: "HEADQUARTERS",
                                                company: "COMPANY",
                                                country: "UNITED STATES",
                                                address: "15 ALGONKIN ST",
                                                city: "TICONDEROGA",
                                                state: "NY",
                                                postalCode: "12883-1487",
                                                email: "",
                                                phone: "",
                                                isDefaultAddress: false,
                                                showCompanyField: true,
                                                isVerified: false))
}
