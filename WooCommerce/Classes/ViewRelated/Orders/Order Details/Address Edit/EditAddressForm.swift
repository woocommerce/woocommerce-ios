import Foundation
import Combine
import SwiftUI
import UIKit

/// Hosting controller that wraps an `EditAddressForm`.
///
final class EditAddressHostingController: UIHostingController<EditAddressForm> {

    init(viewModel: EditAddressFormViewModel) {
        super.init(rootView: EditAddressForm(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        // Set presentation delegate to track the user dismiss flow event
        presentationController?.delegate = self
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Intercepts to the dismiss drag gesture.
///
extension EditAddressHostingController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // track dimiss gesture
    }
}

/// Allows merchant to edit the customer provided address of an order.
///
struct EditAddressForm: View {

    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: (() -> Void) = {}

    @ObservedObject private var viewModel: EditAddressFormViewModel

    /// Set it to `true` to present the country selector.
    ///
    @State var showCountrySelector: Bool = false

    init(viewModel: EditAddressFormViewModel) {
        self.viewModel = viewModel
    }

    /// Set it to `true` to present the state selector.
    ///
    @State var showStateSelector = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ListHeaderView(text: Localization.detailsSection, alignment: .left)
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                VStack(spacing: 0) {
                    TitleAndTextFieldRow(title: Localization.firstNameField,
                                         placeholder: "",
                                         text: $viewModel.fields.firstName,
                                         symbol: nil,
                                         keyboardType: .default)
                    Divider()
                        .padding(.leading, Constants.dividerPadding)
                    TitleAndTextFieldRow(title: Localization.lastNameField,
                                         placeholder: "",
                                         text: $viewModel.fields.lastName,
                                         symbol: nil,
                                         keyboardType: .default)
                    Divider()
                        .padding(.leading, Constants.dividerPadding)
                    TitleAndTextFieldRow(title: Localization.emailField,
                                         placeholder: "",
                                         text: $viewModel.fields.email,
                                         symbol: nil,
                                         keyboardType: .emailAddress)
                    Divider()
                        .padding(.leading, Constants.dividerPadding)
                    TitleAndTextFieldRow(title: Localization.phoneField,
                                         placeholder: "",
                                         text: $viewModel.fields.phone,
                                         symbol: nil,
                                         keyboardType: .phonePad)
                }
                .padding(.horizontal, insets: geometry.safeAreaInsets)
                .background(Color(.systemBackground))

                ListHeaderView(text: sectionTitle, alignment: .left)
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                VStack(spacing: 0) {
                    Group {
                        TitleAndTextFieldRow(title: Localization.companyField,
                                             placeholder: Localization.placeholderOptional,
                                             text: $viewModel.fields.company,
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndTextFieldRow(title: Localization.address1Field,
                                             placeholder: "",
                                             text: $viewModel.fields.address1,
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndTextFieldRow(title: Localization.address2Field,
                                             placeholder: "Optional",
                                             text: $viewModel.fields.address2,
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndTextFieldRow(title: Localization.cityField,
                                             placeholder: "",
                                             text: $viewModel.fields.city,
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndTextFieldRow(title: Localization.postcodeField,
                                             placeholder: "",
                                             text: $viewModel.fields.postcode,
                                             symbol: nil,
                                             keyboardType: .default)
                        Divider()
                            .padding(.leading, Constants.dividerPadding)
                    }

                    Group {
                        TitleAndValueRow(title: Localization.countryField, value: viewModel.fields.country, selectable: true) {
                            showCountrySelector = true
                        }
                        Divider()
                            .padding(.leading, Constants.dividerPadding)
                        TitleAndValueRow(title: Localization.stateField, value: viewModel.fields.state, selectable: true) {
                            showStateSelector = true
                        }
                    }
                }
                .padding(.horizontal, insets: geometry.safeAreaInsets)
                .background(Color(.systemBackground))
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        }
        .navigationTitle(viewTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: navigationBarTrailingItem())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Localization.close, action: {
                    dismiss()
                })
            }
        }
        .redacted(reason: viewModel.showPlaceholders ? .placeholder : [])
        .shimmering(active: viewModel.showPlaceholders)
        .onAppear {
            viewModel.onLoadTrigger.send()
        }

        // Go to edit country
        LazyNavigationLink(destination: FilterListSelector(viewModel: viewModel.createCountryViewModel()), isActive: $showCountrySelector) {
            EmptyView()
        }

        // Go to edit state
        // TODO: Move `StateSelectorViewModel` creation to the VM when it exists.
        LazyNavigationLink(destination: FilterListSelector(viewModel: viewModel.createStateViewModel()), isActive: $showStateSelector) {
            EmptyView()
        }

        ///
        /// iOS 14.5 has a bug where
        /// Pushing a view while having "exactly two" navigation links makes the pushed view to be popped when the initial view changes its state.
        /// EG: AddressForm -> CountrySelector -> Country is selected -> AddressForm updates country -> CountrySelector is popped automatically.
        /// Adding an extra and useless navigation link fixes the problem but throws a warning in the console.
        /// Ref: https://forums.swift.org/t/14-5-beta3-navigationlink-unexpected-pop/45279
        ///
        NavigationLink(destination: EmptyView()) {
            EmptyView()
        }
    }

    /// Decides if the navigation trailing item should be a done button or a loading indicator.
    ///
    @ViewBuilder private func navigationBarTrailingItem() -> some View {
        switch viewModel.navigationTrailingItem {
        case .done(let enabled):
            Button(Localization.done) {
                viewModel.updateRemoteAddress(onFinish: { success in
                    if success {
                        dismiss()
                    }
                })
            }
            .disabled(!enabled)
        case .loading:
            ProgressView()
        }
    }
}

// MARK: Constants
private extension EditAddressForm {

    var viewTitle: String {
        switch viewModel.type {
        case .shipping:
            return Localization.shippingTitle
        case .billing:
            return Localization.billingTitle
        }
    }

    var sectionTitle: String {
        switch viewModel.type {
        case .shipping:
            return Localization.shippingAddressSection
        case .billing:
            return Localization.billingAddressSection
        }
    }

    enum Constants {
        static let dividerPadding: CGFloat = 16
    }

    enum Localization {
        static let shippingTitle = NSLocalizedString("Shipping Address", comment: "Title for the Edit Shipping Address Form")
        static let billingTitle = NSLocalizedString("Billing Address", comment: "Title for the Edit Billing Address Form")
        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Edit Address Form")
        static let done = NSLocalizedString("Done", comment: "Text for the done button in the Edit Address Form")

        static let detailsSection = NSLocalizedString("DETAILS", comment: "Details section title in the Edit Address Form")
        static let shippingAddressSection = NSLocalizedString("SHIPPING ADDRESS", comment: "Details section title in the Edit Address Form")
        static let billingAddressSection = NSLocalizedString("BILLING ADDRESS", comment: "Details section title in the Edit Address Form")

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

import struct Yosemite.Order
import struct Yosemite.Address

struct EditAddressForm_Previews: PreviewProvider {
    static let sampleOrder = Order(siteID: 123,
                                   orderID: 456,
                                   parentID: 2,
                                   customerID: 11,
                                   number: "789",
                                   status: .processing,
                                   currency: "USD",
                                   customerNote: "",
                                   dateCreated: Date(),
                                   dateModified: Date(),
                                   datePaid: Date(),
                                   discountTotal: "0.00",
                                   discountTax: "0.00",
                                   shippingTotal: "0.00",
                                   shippingTax: "0.00",
                                   total: "31.20",
                                   totalTax: "1.20",
                                   paymentMethodID: "stripe",
                                   paymentMethodTitle: "Credit Card (Stripe)",
                                   items: [],
                                   billingAddress: sampleAddress,
                                   shippingAddress: sampleAddress,
                                   shippingLines: [],
                                   coupons: [],
                                   refunds: [],
                                   fees: [])

    static let sampleAddress = Address(firstName: "Johnny",
                                       lastName: "Appleseed",
                                       company: nil,
                                       address1: "234 70th Street",
                                       address2: nil,
                                       city: "Niagara Falls",
                                       state: "NY",
                                       postcode: "14304",
                                       country: "US",
                                       phone: "333-333-3333",
                                       email: "scrambled@scrambled.com")

    static let sampleViewModel = EditAddressFormViewModel(order: sampleOrder, type: .shipping)

    static var previews: some View {
        NavigationView {
            EditAddressForm(viewModel: sampleViewModel)
        }
    }
}

#endif
