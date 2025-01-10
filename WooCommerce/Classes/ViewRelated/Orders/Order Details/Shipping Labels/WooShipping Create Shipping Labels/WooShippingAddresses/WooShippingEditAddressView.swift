import SwiftUI

/// View for editing an address in the Woo Shipping label creation flow.
struct WooShippingEditAddressView: View {
    @State var name: String
    @State var company: String
    @State var country: String
    @State var address: String
    @State var city: String
    @State var state: String
    @State var postalCode: String
    @State var email: String
    @State var phone: String
    @State var saveAsDefault: Bool

    /// Whether to show the company field by default.
    @State var showCompanyField: Bool

    /// Tracks the focused address field.
    @FocusState private var focusedField: AddressField?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.verticalSpacing) {
                AddressTextField(field: .name, text: $name, focused: $focusedField)
                if showCompanyField {
                    AddressTextField(field: .company, text: $company, focused: $focusedField)
                } else {
                    Button {
                        withAnimation {
                            showCompanyField = true
                        }
                    } label: {
                        Text(Localization.addCompany)
                    }
                    .buttonStyle(PlusButtonStyle())
                    .font(.subheadline)
                    .bold()
                }
                AddressSelection(field: .country, selected: country) {
                    // TODO: Handle country selection
                }
                .padding(.top, Constants.extraPadding)
                AddressTextField(field: .address, text: $address, focused: $focusedField)
                AddressTextField(field: .city, text: $city, focused: $focusedField)
                AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .top, spacing: Constants.innerSpacing) {
                    AddressSelection(field: .state, selected: state) {
                        // TODO: Handle state selection
                    }
                    AddressTextField(field: .postalCode, text: $postalCode, focused: $focusedField)
                }
                .padding(.bottom, Constants.extraPadding)
                AddressTextField(field: .email, text: $email, focused: $focusedField)
                AddressTextField(field: .phone, text: $phone, focused: $focusedField)
                    .padding(.bottom, Constants.extraPadding)
                Toggle(Localization.defaultAddress, isOn: $saveAsDefault)
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
    }

    private struct AddressTextField: View {
        /// Which address field to display.
        let field: AddressField

        /// The text to display in the text field.
        @Binding var text: String

        /// The focused state of the field.
        @FocusState.Binding var focused: AddressField?

        var body: some View {
            VStack(spacing: Constants.innerSpacing) {
                HStack(spacing: Constants.requiredLabelSpacing) {
                    Text(field.title)
                    if field.required {
                        Text("*")
                    }
                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(Color(.text))
                TextField(field.title, text: $text, prompt: Text(field.required ? "" : Localization.optional))
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

        /// The action to perform when the button is tapped.
        var action: () -> Void

        var body: some View {
            VStack(spacing: Constants.innerSpacing) {
                HStack(spacing: Constants.requiredLabelSpacing) {
                    Text(field.title)
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

private extension WooShippingEditAddressView {
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

        var required: Bool {
            switch self {
            case .name, .country, .address, .city, .state, .postalCode, .email, .phone:
                return true
            case .company:
                return false
            }
        }
    }

    /// Navigates to the next address field in the form.
    func focusNextField() {
        switch focusedField {
        case .name:
            focusedField = showCompanyField ? .company : .address
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
    func focusPreviousField() {
        switch focusedField {
        case .name:
            focusedField = nil
        case .company:
            focusedField = .name
        case .address:
            focusedField = showCompanyField ? .company : .name
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
    func dismissKeyboard() {
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
    }
}

#Preview("Without Company") {
    WooShippingEditAddressView(name: "HEADQUARTERS",
                               company: "",
                               country: "UNITED STATES",
                               address: "15 ALGONKIN ST",
                               city: "TICONDEROGA",
                               state: "NY",
                               postalCode: "12883-1487",
                               email: "",
                               phone: "",
                               saveAsDefault: true,
                               showCompanyField: false)
}

#Preview("With Company") {
    WooShippingEditAddressView(name: "HEADQUARTERS",
                               company: "COMPANY",
                               country: "UNITED STATES",
                               address: "15 ALGONKIN ST",
                               city: "TICONDEROGA",
                               state: "NY",
                               postalCode: "12883-1487",
                               email: "",
                               phone: "",
                               saveAsDefault: false,
                               showCompanyField: true)
}
