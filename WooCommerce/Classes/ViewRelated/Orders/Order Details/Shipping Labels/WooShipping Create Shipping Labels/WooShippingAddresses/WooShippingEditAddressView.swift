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
                LabelAndTextField(title: Localization.name, text: $name)
                if showCompanyField {
                    LabelAndTextField(title: Localization.company, text: $company, required: false)
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
                LabelAndTextField(title: Localization.country, text: $country)
                    .padding(.top, Constants.extraPadding)
                LabelAndTextField(title: Localization.address, text: $address)
                LabelAndTextField(title: Localization.city, text: $city)
                AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .top, spacing: Constants.innerSpacing) {
                    LabelAndTextField(title: Localization.state, text: $state)
                    LabelAndTextField(title: Localization.postalCode, text: $postalCode)
                }
            }
            .padding()
        }
    }

    private struct LabelAndTextField: View {
        let title: String
        @Binding var text: String
        var required: Bool = true

        var body: some View {
            VStack(spacing: Constants.innerSpacing) {
                HStack {
                    Text(title)
                    if required {
                        Text("*")
                    }
                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(Color(.text))
                TextField(title, text: $text, prompt: Text(required ? "" : Localization.optional))
                    .padding()
                    .roundedBorder(cornerRadius: Constants.cornerRadius, lineColor: Constants.borderColor, lineWidth: Constants.borderWidth)
            }
        }
    }
}

private extension WooShippingEditAddressView {
    enum Constants {
        static let verticalSpacing: CGFloat = 16
        static let innerSpacing: CGFloat = 8
        static let extraPadding: CGFloat = 24
        static let cornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 1
        static let borderColor: Color = Color(.separator)
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
