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
    @FocusState private var focusedField: AddressField?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.verticalSpacing) {
                AddressTextField(field: .name, text: $viewModel.name, required: viewModel.isRequired(.name), focused: $focusedField)
                if viewModel.showCompanyField {
                    AddressTextField(field: .company, text: $viewModel.company, required: viewModel.isRequired(.company), focused: $focusedField)
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
                AddressSelection(field: .country, selected: viewModel.country, required: viewModel.isRequired(.country)) {
                    // TODO: Handle country selection
                }
                .padding(.top, Constants.extraPadding)
                AddressTextField(field: .address, text: $viewModel.address, required: viewModel.isRequired(.address), focused: $focusedField)
                AddressTextField(field: .city, text: $viewModel.city, required: viewModel.isRequired(.city), focused: $focusedField)
                AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .top, spacing: Constants.innerSpacing) {
                    AddressSelection(field: .state, selected: viewModel.state, required: viewModel.isRequired(.state)) {
                        // TODO: Handle state selection
                    }
                    AddressTextField(field: .postalCode, text: $viewModel.postalCode, required: viewModel.isRequired(.postalCode), focused: $focusedField)
                }
                .padding(.bottom, Constants.extraPadding)
                AddressTextField(field: .email, text: $viewModel.email, required: viewModel.isRequired(.email), focused: $focusedField)
                AddressTextField(field: .phone, text: $viewModel.phone, required: viewModel.isRequired(.phone), focused: $focusedField)
                    .padding(.bottom, Constants.extraPadding)
                Toggle(Localization.defaultAddress, isOn: $viewModel.saveAsDefault)
                    .font(.subheadline)
                    .tint(Color(.accent))
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: {
                        focusPreviousField()
                    }, label: {
                        Image(systemName: "chevron.backward")
                    })
                    .disabled(focusedField == AddressField.allCases.first)
                    Button(action: {
                        focusNextField()
                    }, label: {
                        Image(systemName: "chevron.forward")
                    })
                    .disabled(focusedField == AddressField.allCases.last)
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
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: .zero) {
                Divider().ignoresSafeArea(edges: [.horizontal])
                VStack(spacing: Constants.verticalSpacing) {
                    HStack {
                        Image(systemName: viewModel.status == .verified ? "checkmark.circle" : "exclamationmark.circle")
                        Text(Localization.Status.label(for: viewModel.status))
                    }
                    .font(.subheadline)
                    .foregroundStyle(viewModel.status == .verified ? Constants.green : Constants.red)
                    Button(Localization.Button.label(for: viewModel.status)) {
                        if viewModel.status == .verified {
                            dismiss()
                        } else {
                            // TODO: Handle remote verification
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.status == .missingInformation)
                }
                .padding()
            }
            .background(Color(uiColor: .systemBackground))
        }
    }

    private struct AddressTextField: View {
        /// Which address field to display.
        let field: AddressField

        /// The text to display in the text field.
        @Binding var text: String

        /// Whether the field is required.
        let required: Bool

        /// The focused state of the field.
        @FocusState.Binding var focused: AddressField?

        var body: some View {
            VStack(spacing: Constants.innerSpacing) {
                HStack(spacing: Constants.requiredLabelSpacing) {
                    Text(field.title)
                    if required {
                        Text("*")
                    }
                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(Color(.text))
                TextField(field.title, text: $text, prompt: Text(required ? "" : Localization.optional))
                    .focused($focused, equals: field)
                    .padding()
                    .roundedBorder(cornerRadius: Constants.cornerRadius,
                                   lineColor: focused == field ? Color(.accent) : Constants.defaultBorderColor,
                                   lineWidth: focused == field ? 2 : Constants.defaultBorderWidth)
            }
        }
    }

    private struct AddressSelection: View {
        /// Which address field to display.
        let field: AddressField

        /// The text to display for the selection.
        let selected: String

        /// Whether the field is required.
        let required: Bool

        /// The action to perform when the button is tapped.
        var action: () -> Void

        var body: some View {
            VStack(spacing: Constants.innerSpacing) {
                HStack(spacing: Constants.requiredLabelSpacing) {
                    Text(field.title)
                    if required {
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
                        Text(selected)
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
            }
        }
    }
}

extension WooShippingEditAddressView {
    enum AddressField: CaseIterable {
        case name
        case company
        case country
        case address
        case city
        case state
        case postalCode
        case email
        case phone

        var title: String {
            switch self {
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
    }

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
    enum Constants {
        static let verticalSpacing: CGFloat = 16
        static let innerSpacing: CGFloat = 8
        static let extraPadding: CGFloat = 24
        static let cornerRadius: CGFloat = 8
        static let defaultBorderColor: Color = Color(.separator)
        static let defaultBorderWidth: CGFloat = 1
        static let green = Color(UIColor(light: .withColorStudio(.green, shade: .shade60),
                                         dark: .withColorStudio(.green, shade: .shade40)))
        static let red = Color(UIColor(light: .withColorStudio(.red, shade: .shade60),
                                       dark: .withColorStudio(.red, shade: .shade40)))
        static let requiredLabelSpacing: CGFloat = 4
    }

    enum Localization {
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

        enum Status {
            static func label(for status: WooShippingAddressStatus) -> String {
                switch status {
                case .verified:
                    return verified
                case .unverified:
                    return unverified
                case .missingInformation:
                    return missingInformation
                }
            }
            static let verified = NSLocalizedString("wooShipping.createLabels.editAddress.verified",
                                                    value: "Address verified",
                                                    comment: "Label when the address has been verified in the Woo Shipping label creation flow")
            static let unverified = NSLocalizedString("wooShipping.createLabels.editAddress.unverified",
                                                      value: "Unverified address",
                                                      comment: "Label when the address is unverified in the Woo Shipping label creation flow")
            static let missingInformation = NSLocalizedString("wooShipping.createLabels.editAddress.missingInformation",
                                                              value: "Missing information",
                                                              comment: "Label when the address is missing information in the Woo Shipping label creation flow")
        }

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
    }
}

#Preview("Without Company") {
    WooShippingEditAddressView(viewModel: .init(id: UUID().uuidString,
                                                name: "HEADQUARTERS",
                                                company: "",
                                                country: "UNITED STATES",
                                                address: "15 ALGONKIN ST",
                                                city: "TICONDEROGA",
                                                state: "NY",
                                                postalCode: "12883-1487",
                                                email: "",
                                                phone: "",
                                                saveAsDefault: true,
                                                showCompanyField: false,
                                                isVerified: true))
}

#Preview("With Company") {
    WooShippingEditAddressView(viewModel: .init(id: UUID().uuidString,
                                                name: "HEADQUARTERS",
                                                company: "COMPANY",
                                                country: "UNITED STATES",
                                                address: "15 ALGONKIN ST",
                                                city: "TICONDEROGA",
                                                state: "NY",
                                                postalCode: "12883-1487",
                                                email: "",
                                                phone: "",
                                                saveAsDefault: false,
                                                showCompanyField: true,
                                                isVerified: false))
}
