import SwiftUI

/// View for editing an address in the Woo Shipping label creation flow.
struct WooShippingEditAddressView: View {
    @State private var name: String
    @State private var company: String
    @State private var country: String
    @State private var address: String
    @State private var city: String
    @State private var state: String
    @State private var postalCode: String

    /// Whether to show the company text field.
    @State private var showCompanyField: Bool

    /// Tracks the focused address field.
    @FocusState private var focusedField: AddressField?

    init(name: String,
         company: String,
         country: String,
         address: String,
         city: String,
         state: String,
         postalCode: String) {
        _name = State(initialValue: name)
        _company = State(initialValue: company)
        _country = State(initialValue: country)
        _address = State(initialValue: address)
        _city = State(initialValue: city)
        _state = State(initialValue: state)
        _postalCode = State(initialValue: postalCode)
        _showCompanyField = State(initialValue: !company.isEmpty)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.verticalSpacing) {
                AddressTextField(field: .name, text: $name, focused: $focusedField)
                if showCompanyField {
                    AddressTextField(field: .company, text: $company, focused: $focusedField)
                } else {
                    Button {
                        showCompanyField = true
                    } label: {
                        Text(Localization.addCompany)
                    }
                    .buttonStyle(PlusButtonStyle())
                    .font(.subheadline)
                    .bold()
                }
                AddressTextField(field: .country, text: $country, focused: $focusedField)
                    .padding(.top, Constants.extraPadding)
                AddressTextField(field: .address, text: $address, focused: $focusedField)
                AddressTextField(field: .city, text: $city, focused: $focusedField)
                AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .top, spacing: Constants.innerSpacing) {
                    AddressTextField(field: .state, text: $state, focused: $focusedField)
                    AddressTextField(field: .postalCode, text: $postalCode, focused: $focusedField)
                }
            }
            .padding()
        }
    }

    private struct AddressTextField: View {
        /// Which address field to display.
        let field: AddressField

        /// The text to display in the text field.
        @Binding var text: String

        /// The focused state of the field.
        var focused: FocusState<AddressField?>.Binding

        /// Whether the field is focused.
        private var isFocused: Bool {
            focused.wrappedValue == field
        }

        var body: some View {
            VStack(spacing: Constants.innerSpacing) {
                HStack {
                    Text(field.title)
                    if field.required {
                        Text("*")
                    }
                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(Color(.text))
                TextField(field.title, text: $text, prompt: Text(field.required ? "" : Localization.optional))
                    .focused(focused, equals: field)
                    .padding()
                    .roundedBorder(cornerRadius: Constants.cornerRadius,
                                   lineColor: isFocused ? Color(.accent) : Color(.separator),
                                   lineWidth: isFocused ? 2 : 1)
            }
        }
    }
}

private extension WooShippingEditAddressView {
    enum AddressField {
        case name, company, country, address, city, state, postalCode

        var title: String {
            switch self {
            case .name: return Localization.name
            case .company: return Localization.company
            case .country: return Localization.country
            case .address: return Localization.address
            case .city: return Localization.city
            case .state: return Localization.state
            case .postalCode: return Localization.postalCode
            }
        }

        var required: Bool {
            self != .company
        }
    }
}

private extension WooShippingEditAddressView {
    enum Constants {
        static let verticalSpacing: CGFloat = 16
        static let innerSpacing: CGFloat = 8
        static let extraPadding: CGFloat = 24
        static let cornerRadius: CGFloat = 8
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
        static let optional = NSLocalizedString("wooShipping.createLabels.editAddress.optional",
                                                    value: "Optional",
                                                    comment: "Text indicating that a field is optional")
    }
}

#Preview("Without Company") {
    WooShippingEditAddressView(name: "HEADQUARTERS",
                               company: "",
                               country: "UNITED STATES",
                               address: "15 ALGONKIN ST",
                               city: "TICONDEROGA",
                               state: "NY",
                               postalCode: "12883-1487")
}

#Preview("With Company") {
    WooShippingEditAddressView(name: "HEADQUARTERS",
                               company: "COMPANY",
                               country: "UNITED STATES",
                               address: "15 ALGONKIN ST",
                               city: "TICONDEROGA",
                               state: "NY",
                               postalCode: "12883-1487")
}
