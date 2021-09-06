import Foundation
import Combine
import SwiftUI
import UIKit

/// Hosting controller that wraps an `EditAddressForm`.
///
final class EditAddressHostingController: UIHostingController<EditAddressForm> {

    init() {
        super.init(rootView: EditAddressForm())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Allows merchant to edit the customer provided address of an order.
///
struct EditAddressForm: View {

    /// Set it to `true` to present the country selector.
    ///
    @State var showCountrySelector = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ListHeaderView(text: Localization.detailsSection, alignment: .left)
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                VStack(spacing: 0) {
                    TitleAndTextFieldRow(title: Localization.firstNameField,
                                         placeholder: "",
                                         text: .constant(""),
                                         symbol: nil,
                                         keyboardType: .default)
                    Divider()
                        .padding(.leading, Constants.dividerPadding)
                    TitleAndTextFieldRow(title: Localization.lastNameField,
                                         placeholder: "",
                                         text: .constant(""),
                                         symbol: nil,
                                         keyboardType: .default)
                    Divider()
                        .padding(.leading, Constants.dividerPadding)
                    TitleAndTextFieldRow(title: Localization.emailField,
                                         placeholder: "",
                                         text: .constant(""),
                                         symbol: nil,
                                         keyboardType: .emailAddress)
                    Divider()
                        .padding(.leading, Constants.dividerPadding)
                    TitleAndTextFieldRow(title: Localization.phoneField,
                                         placeholder: "",
                                         text: .constant(""),
                                         symbol: nil,
                                         keyboardType: .phonePad)
                }
                .padding(.horizontal, insets: geometry.safeAreaInsets)
                .background(Color(.systemBackground))

                ListHeaderView(text: Localization.shippingAddressSection, alignment: .left)
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                VStack(spacing: 0) {
                    Group {
                        TitleAndTextFieldRow(title: Localization.companyField,
                                             placeholder: Localization.placeholderOptional,
                                             text: .constant(""),
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndTextFieldRow(title: Localization.address1Field,
                                             placeholder: "",
                                             text: .constant(""),
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndTextFieldRow(title: Localization.address2Field,
                                             placeholder: "Optional",
                                             text: .constant(""),
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndTextFieldRow(title: Localization.cityField,
                                             placeholder: "",
                                             text: .constant(""),
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndTextFieldRow(title: Localization.postcodeField,
                                             placeholder: "",
                                             text: .constant(""),
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, Constants.dividerPadding)
                    }

                    Group {
                        TitleAndValueRow(title: Localization.countryField, value: Localization.placeholderSelectOption, selectable: true) {
                            showCountrySelector = true
                        }
                        Divider()
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndValueRow(title: Localization.stateField, value: Localization.placeholderSelectOption, selectable: true) { }
                    }
                }
                .padding(.horizontal, insets: geometry.safeAreaInsets)
                .background(Color(.systemBackground))
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        }
        .navigationTitle(Localization.shippingTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(Localization.done) {
            // TODO: save changes
        }
        .disabled(true) // TODO: enable if there are pending changes
        )

        // Go to edit country
        // TODO: Move `CountrySelectorViewModel` to the VM when it exists.
        NavigationLink(destination: CountrySelector(viewModel: CountrySelectorViewModel()), isActive: $showCountrySelector) {
            EmptyView()
        }
    }
}

// MARK: Constants
private extension EditAddressForm {
    enum Constants {
        static let dividerPadding: CGFloat = 16
    }

    enum Localization {
        static let shippingTitle = NSLocalizedString("Shipping Address", comment: "Title for the Edit Shipping Address Form")
        static let done = NSLocalizedString("Done", comment: "Text for the done button in the Edit Address Form")

        static let detailsSection = NSLocalizedString("DETAILS", comment: "Details section title in the Edit Address Form")
        static let shippingAddressSection = NSLocalizedString("SHIPPING ADDRESS", comment: "Details section title in the Edit Address Form")

        static let firstNameField = NSLocalizedString("First name", comment: "Text field name in Edit Address Form")
        static let lastNameField = NSLocalizedString("Last name", comment: "Text field name in Edit Address Form")
        static let emailField = NSLocalizedString("Email", comment: "Text field email in Edit Address Form")
        static let phoneField = NSLocalizedString("Phone", comment: "Text field phone in Edit Address Form")

        static let companyField = NSLocalizedString("Company", comment: "Text field company in Edit Address Form")
        static let address1Field = NSLocalizedString("Address 1", comment: "Text field address 1 in Edit Address Form")
        static let address2Field = NSLocalizedString("Address 2", comment: "Text field address 2 in Edit Address Form")
        static let cityField = NSLocalizedString("City", comment: "Text field city in Edit Address Form")
        static let postcodeField = NSLocalizedString("Postcode", comment: "Text field postcode in Edit Address Form")
        static let countryField = NSLocalizedString("Country", comment: "Text field country in Edit Address Form")
        static let stateField = NSLocalizedString("State", comment: "Text field state in Edit Address Form")

        static let placeholderRequired = NSLocalizedString("Required", comment: "Text field placeholder in Edit Address Form")
        static let placeholderOptional = NSLocalizedString("Optional", comment: "Text field placeholder in Edit Address Form")
        static let placeholderSelectOption = NSLocalizedString("Select an option", comment: "Text field placeholder in Edit Address Form")
    }
}

#if DEBUG

struct EditAddressForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditAddressForm()
        }
    }
}

#endif
