import Foundation
import Combine
import SwiftUI

/// Hosting controller that wraps an `EditAddressView`.
///
final class EditAddressHostingController: UIHostingController<EditAddressView> {

    init() {
        super.init(rootView: EditAddressView())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Allows merchant to edit the customer provided address of an order.
///
struct EditAddressView: View {
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
                            .padding(.leading, insets: geometry.safeAreaInsets)
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndTextFieldRow(title: Localization.address1Field,
                                             placeholder: "",
                                             text: .constant(""),
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, insets: geometry.safeAreaInsets)
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndTextFieldRow(title: Localization.address2Field,
                                             placeholder: "Optional",
                                             text: .constant(""),
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, insets: geometry.safeAreaInsets)
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndTextFieldRow(title: Localization.cityField,
                                             placeholder: "",
                                             text: .constant(""),
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, insets: geometry.safeAreaInsets)
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndTextFieldRow(title: Localization.postcodeField,
                                             placeholder: "",
                                             text: .constant(""),
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, insets: geometry.safeAreaInsets)
                            .padding(.leading, Constants.dividerPadding)
                    }

                    Group {
                        TitleAndValueRow(title: Localization.countryField, value: Localization.placeholderSelectOption, selectable: true) { }
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
    }
}

// MARK: Constants
private extension EditAddressView {
    enum Constants {
        static let dividerPadding: CGFloat = 16
    }

    enum Localization {
        static let shippingTitle = NSLocalizedString("Shipping Address", comment: "Title for the Edit Shipping Address screen")
        static let done = NSLocalizedString("Done", comment: "Text for the done button in the Edit Address screen")

        static let detailsSection = NSLocalizedString("DETAILS", comment: "Details section title in the Edit Address screen")
        static let shippingAddressSection = NSLocalizedString("SHIPPING ADDRESS", comment: "Details section title in the Edit Address screen")

        static let firstNameField = NSLocalizedString("First name", comment: "Text field name in Edit Address screen")
        static let lastNameField = NSLocalizedString("Last name", comment: "Text field name in Edit Address screen")
        static let emailField = NSLocalizedString("Email", comment: "Text field email in Edit Address screen")
        static let phoneField = NSLocalizedString("Phone", comment: "Text field phone in Edit Address screen")

        static let companyField = NSLocalizedString("Company", comment: "Text field company in Edit Address screen")
        static let address1Field = NSLocalizedString("Address 1", comment: "Text field address 1 in Edit Address screen")
        static let address2Field = NSLocalizedString("Address 2", comment: "Text field address 2 in Edit Address screen")
        static let cityField = NSLocalizedString("City", comment: "Text field city in Edit Address screen")
        static let postcodeField = NSLocalizedString("Postcode", comment: "Text field postcode in Edit Address screen")
        static let countryField = NSLocalizedString("Country", comment: "Text field country in Edit Address screen")
        static let stateField = NSLocalizedString("State", comment: "Text field state in Edit Address screen")

        static let placeholderRequired = NSLocalizedString("Required", comment: "Text field placeholder in Edit Address screen")
        static let placeholderOptional = NSLocalizedString("Optional", comment: "Text field placeholder in Edit Address screen")
        static let placeholderSelectOption = NSLocalizedString("Select an option", comment: "Text field placeholder in Edit Address screen")
    }
}

#if DEBUG

struct EditAddressView_Previews: PreviewProvider {
    static var previews: some View {
        EditAddressView()
    }
}

#endif
