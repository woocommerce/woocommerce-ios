import Combine
import SwiftUI
import UIKit
import Yosemite
import Experiments

/// Hosting controller that wraps an `EditOrderAddressForm`.
///
final class EditOrderAddressHostingController: UIHostingController<EditOrderAddressForm<EditOrderAddressFormViewModel>> {

    /// References to keep the Combine subscriptions alive within the lifecycle of the object.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    /// Presents an error notice in the current modal presentation context
    ///
    private lazy var modalNoticePresenter: NoticePresenter = {
        let presenter = DefaultNoticePresenter()
        presenter.presentingViewController = self
        return presenter
    }()

    /// Presents a success notice in the tab bar context after this `self` is dismissed.
    ///
    private let systemNoticePresenter: NoticePresenter

    init(viewModel: EditOrderAddressFormViewModel, systemNoticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.systemNoticePresenter = systemNoticePresenter
        super.init(rootView: EditOrderAddressForm(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismiss = { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set presentation delegate to track the user dismiss flow event
        if let navigationController = navigationController {
            navigationController.presentationController?.delegate = self
        } else {
            presentationController?.delegate = self
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Show any notice that should have been presented before the underlying disappears.
        enqueuePendingNotice(rootView.viewModel.notice, using: systemNoticePresenter)
    }
}

/// Intercepts to the dismiss drag gesture.
///
extension EditOrderAddressHostingController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        !rootView.viewModel.hasPendingChanges
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self) { [weak self] in
            self?.dismiss(animated: true)
            self?.rootView.viewModel.userDidCancelFlow()
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        rootView.viewModel.userDidCancelFlow()
    }
}

enum EditOrderAddressFormDismissAction {
    case cancel
    case done
}

/// Allows merchant to edit the customer provided address of an order.
///
struct EditOrderAddressForm<ViewModel: AddressFormViewModelProtocol>: View {

    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: ((EditOrderAddressFormDismissAction) -> Void) = { _ in }

    /// View Model for the view
    ///
    @ObservedObject private(set) var viewModel: ViewModel

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets
    @State private var showingCustomerSearch: Bool = false

    var body: some View {
        Group {
            ScrollView {
                SingleAddressForm(fields: $viewModel.fields,
                                  countryViewModelClosure: viewModel.createCountryViewModel,
                                  stateViewModelClosure: viewModel.createStateViewModel,
                                  sectionTitle: viewModel.sectionTitle,
                                  showEmailField: viewModel.showEmailField,
                                  showPhoneCountryCodeField: viewModel.showPhoneCountryCodeField,
                                  showStateFieldAsSelector: viewModel.showStateFieldAsSelector)
                         .accessibilityElement(children: .contain)
                         .accessibilityIdentifier("order-address-form")

                if viewModel.showAlternativeUsageToggle, let alternativeUsageToggleTitle = viewModel.alternativeUsageToggleTitle {
                    TitleAndToggleRow(title: alternativeUsageToggleTitle, isOn: $viewModel.fields.useAsToggle)
                        .padding(.horizontal, Constants.horizontalPadding)
                        .padding(.vertical, Constants.verticalPadding)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(.systemBackground))
                        .addingTopAndBottomDividers()
                }

                if viewModel.showDifferentAddressToggle, let differentAddressToggleTitle = viewModel.differentAddressToggleTitle {
                    TitleAndToggleRow(title: differentAddressToggleTitle, isOn: $viewModel.showDifferentAddressForm)
                        .padding(.horizontal, Constants.horizontalPadding)
                        .padding(.vertical, Constants.verticalPadding)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(.systemBackground))
                        .addingTopAndBottomDividers()
                        .accessibilityIdentifier("order-creation-customer-details-shipping-address-toggle")
                }

                if viewModel.showDifferentAddressForm {
                    SingleAddressForm(fields: $viewModel.secondaryFields,
                                      countryViewModelClosure: viewModel.createSecondaryCountryViewModel,
                                      stateViewModelClosure: viewModel.createSecondaryStateViewModel,
                                      sectionTitle: viewModel.secondarySectionTitle,
                                      showEmailField: false,
                                      showPhoneCountryCodeField: viewModel.showPhoneCountryCodeField,
                                      showStateFieldAsSelector: viewModel.showSecondaryStateFieldAsSelector)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("secondary-order-address-form")
                }

                Spacer(minLength: safeAreaInsets.bottom)
            }
            .disableAutocorrection(true)
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        }
        .navigationTitle(viewModel.viewTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.close, action: {
                    dismiss(.cancel)
                    viewModel.userDidCancelFlow()
                })
            }

            ToolbarItemGroup(placement: .automatic) {
                if viewModel.showSearchButton {
                    Button(action: {
                        showingCustomerSearch = true
                    }, label: {
                        Image(systemName: "magnifyingglass")
                    })
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                navigationBarTrailingItem()
            }
        }
        .wooNavigationBarStyle()
        .redacted(reason: viewModel.showPlaceholders ? .placeholder : [])
        .shimmering(active: viewModel.showPlaceholders)
        .onAppear {
            viewModel.onLoadTrigger.send()
        }
        .notice($viewModel.notice)
        .sheet(isPresented: $showingCustomerSearch, content: {
            OrderCustomerListView(siteID: viewModel.siteID, onCustomerTapped: { customer in
                viewModel.customerSelectedFromSearch(customer: customer)
                showingCustomerSearch = false
            })
        })
    }

    /// Decides if the navigation trailing item should be a done button or a loading indicator.
    ///
    @ViewBuilder func navigationBarTrailingItem() -> some View {
        switch viewModel.navigationTrailingItem {
        case .done(let enabled):
            Button(Localization.done) {
                viewModel.saveAddress(onFinish: { success in
                    if success {
                        dismiss(.done)
                    }
                })
            }
            .accessibilityIdentifier("order-customer-details-done-button")
            .disabled(!enabled)
        case .loading:
            ProgressView()
        }
    }
}

struct SingleAddressForm: View {

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    @Binding var fields: AddressFormFields

    let countryViewModelClosure: () -> CountrySelectorViewModel
    let stateViewModelClosure: () -> StateSelectorViewModel

    let sectionTitle: String
    let showEmailField: Bool
    let showPhoneCountryCodeField: Bool
    let showStateFieldAsSelector: Bool

    /// Set it to `true` to present the country selector.
    ///
    @State private var showCountrySelector = false

    /// Set it to `true` to present the state selector.
    ///
    @State private var showStateSelector = false

    /// Stores shared value derived from max title width among all the fields.
    ///
    @State private var titleWidth: CGFloat? = nil

    var body: some View {
        content
            .onPreferenceChange(MaxWidthPreferenceKey.self) { value in
                if let value = value {
                    titleWidth = value
                }
            }
    }

    @ViewBuilder
    var content: some View {
        VStack {
        ListHeaderView(text: Localization.detailsSection, alignment: .left)
            .padding(.horizontal, insets: safeAreaInsets)
            .accessibility(addTraits: .isHeader)
        VStack(spacing: 0) {
            TitleAndTextFieldRow(title: Localization.firstNameField,
                                 titleWidth: $titleWidth,
                                 placeholder: Localization.firstNameHint,
                                 text: $fields.firstName,
                                 symbol: nil,
                                 fieldAlignment: .leading,
                                 keyboardType: .default)
                .accessibilityIdentifier("order-address-form-first-name-field")

            Divider()
                .padding(.leading, Constants.dividerPadding)
            TitleAndTextFieldRow(title: Localization.lastNameField,
                                 titleWidth: $titleWidth,
                                 placeholder: Localization.lastNameHint,
                                 text: $fields.lastName,
                                 symbol: nil,
                                 fieldAlignment: .leading,
                                 keyboardType: .default)
            Divider()
                .padding(.leading, Constants.dividerPadding)

            if showEmailField {
                TitleAndTextFieldRow(title: Localization.emailField,
                                     titleWidth: $titleWidth,
                                     placeholder: Localization.emailHint,
                                     text: $fields.email,
                                     symbol: nil,
                                     fieldAlignment: .leading,
                                     keyboardType: .emailAddress)
                    .autocapitalization(.none)
                Divider()
                    .padding(.leading, Constants.dividerPadding)

            }

            if showPhoneCountryCodeField {
                TitleAndTextFieldRow(title: Localization.phoneCountryCodeField,
                                     titleWidth: $titleWidth,
                                     placeholder: Localization.phoneCountryCodeHint,
                                     text: $fields.phoneCountryCode,
                                     symbol: nil,
                                     fieldAlignment: .leading,
                                     keyboardType: .asciiCapableNumberPad)
                .autocapitalization(.none)
                Divider()
                    .padding(.leading, Constants.dividerPadding)
            }

            TitleAndTextFieldRow(title: Localization.phoneField,
                                 titleWidth: $titleWidth,
                                 placeholder: Localization.phoneHint,
                                 text: $fields.phone,
                                 symbol: nil,
                                 fieldAlignment: .leading,
                                 keyboardType: .phonePad)
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.systemBackground))
        .addingTopAndBottomDividers()

        ListHeaderView(text: sectionTitle, alignment: .left)
            .padding(.horizontal, insets: safeAreaInsets)
            .accessibility(addTraits: .isHeader)
        VStack(spacing: 0) {
            Group {
                TitleAndTextFieldRow(title: Localization.companyField,
                                     titleWidth: $titleWidth,
                                     placeholder: Localization.hintOptional,
                                     text: $fields.company,
                                     symbol: nil,
                                     fieldAlignment: .leading,
                                     keyboardType: .default)
                Divider()
                    .padding(.leading, Constants.dividerPadding)
                TitleAndTextFieldRow(title: Localization.address1Field,
                                     titleWidth: $titleWidth,
                                     placeholder: Localization.address1Hint,
                                     text: $fields.address1,
                                     symbol: nil,
                                     fieldAlignment: .leading,
                                     keyboardType: .default)
                Divider()
                    .padding(.leading, Constants.dividerPadding)
                TitleAndTextFieldRow(title: Localization.address2Field,
                                     titleWidth: $titleWidth,
                                     placeholder: Localization.hintOptional,
                                     text: $fields.address2,
                                     symbol: nil,
                                     fieldAlignment: .leading,
                                     keyboardType: .default)
                Divider()
                    .padding(.leading, Constants.dividerPadding)
                TitleAndTextFieldRow(title: Localization.cityField,
                                     titleWidth: $titleWidth,
                                     placeholder: Localization.cityHint,
                                     text: $fields.city,
                                     symbol: nil,
                                     fieldAlignment: .leading,
                                     keyboardType: .default)
                Divider()
                    .padding(.leading, Constants.dividerPadding)
                TitleAndTextFieldRow(title: Localization.postcodeField,
                                     titleWidth: $titleWidth,
                                     placeholder: Localization.postcodeHint,
                                     text: $fields.postcode,
                                     symbol: nil,
                                     fieldAlignment: .leading,
                                     keyboardType: .default)
                Divider()
                    .padding(.leading, Constants.dividerPadding)
            }

            Group {
                // Go to edit country
                LazyNavigationLink(destination: FilterListSelector(viewModel: countryViewModelClosure()), isActive: $showCountrySelector) {
                    EmptyView()
                }

                // Go to edit state
                LazyNavigationLink(destination: FilterListSelector(viewModel: stateViewModelClosure()), isActive: $showStateSelector) {
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

                TitleAndValueRow(title: Localization.countryField,
                                 titleWidth: $titleWidth,
                                 value: .init(placeHolder: Localization.hintSelectOption, content: fields.country),
                                 valueTextAlignment: .leading,
                                 selectionStyle: .disclosure) {
                    showCountrySelector = true
                }
                Divider()
                    .padding(.leading, Constants.dividerPadding)
                stateRow()
            }
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.systemBackground))
        .addingTopAndBottomDividers()
    }
    }

    /// Decides if the state row should be rendered as a list selector field or as a text input field.
    ///
    @ViewBuilder private func stateRow() -> some View {
        if showStateFieldAsSelector {
            TitleAndValueRow(title: Localization.stateField,
                             titleWidth: $titleWidth,
                             value: .init(placeHolder: Localization.hintSelectOption, content: fields.state),
                             valueTextAlignment: .leading,
                             selectionStyle: .disclosure) {
                showStateSelector = true
            }
        } else {
            TitleAndTextFieldRow(title: Localization.stateField,
                                 titleWidth: $titleWidth,
                                 placeholder: Localization.stateHint,
                                 text: $fields.state,
                                 symbol: nil,
                                 fieldAlignment: .leading,
                                 keyboardType: .default)
        }
    }
}

// MARK: Constants
private enum Constants {
    static let dividerPadding: CGFloat = 16
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 7
}

private enum Localization {
    static let close = NSLocalizedString("Close", comment: "Text for the close button in the Edit Address Form")
    static let done = NSLocalizedString("Done", comment: "Text for the done button in the Edit Address Form")

    static let detailsSection = NSLocalizedString("DETAILS", comment: "Details section title in the Edit Address Form")

    static let firstNameField = NSLocalizedString("First name", comment: "Text field name in Edit Address Form")
    static let firstNameHint = NSLocalizedString("Enter Name", comment: "Name field placeholder in Edit Address Form")
    static let lastNameField = NSLocalizedString("Last name", comment: "Text field name in Edit Address Form")
    static let lastNameHint = NSLocalizedString("Enter Last Name", comment: "Last name field placeholder in Edit Address Form")
    static let emailField = NSLocalizedString("Email", comment: "Text field email in Edit Address Form")
    static let emailHint = NSLocalizedString("Enter Email", comment: "Email field placeholder in Edit Address Form")
    static let phoneCountryCodeField = NSLocalizedString("Phone country code", comment: "Text field phone country code in Edit Address Form")
    static let phoneCountryCodeHint = NSLocalizedString("Enter Country Code", comment: "Phone country code field placeholder in Edit Address Form")
    static let phoneField = NSLocalizedString("Phone", comment: "Text field phone in Edit Address Form")
    static let phoneHint = NSLocalizedString("Enter Phone", comment: "Phone field placeholder in Edit Address Form")

    static let companyField = NSLocalizedString("Company", comment: "Text field company in Edit Address Form")
    static let address1Field = NSLocalizedString("Address 1", comment: "Text field address 1 in Edit Address Form")
    static let address1Hint = NSLocalizedString("Enter Address", comment: "Address field placeholder in Edit Address Form")
    static let address2Field = NSLocalizedString("Address 2", comment: "Text field address 2 in Edit Address Form")
    static let cityField = NSLocalizedString("City", comment: "Text field city in Edit Address Form")
    static let cityHint = NSLocalizedString("Enter City", comment: "City field placeholder in Edit Address Form")
    static let postcodeField = NSLocalizedString("Postcode", comment: "Text field postcode in Edit Address Form")
    static let postcodeHint = NSLocalizedString("Enter Postcode", comment: "Postcode field placeholder in Edit Address Form")
    static let countryField = NSLocalizedString("Country", comment: "Text field country in Edit Address Form")
    static let stateField = NSLocalizedString("State", comment: "Text field state in Edit Address Form")
    static let stateHint = NSLocalizedString("Enter State", comment: "State field placeholder in Edit Address Form")

    static let hintOptional = NSLocalizedString("Optional", comment: "Text field placeholder in Edit Address Form")
    static let hintSelectOption = NSLocalizedString("Select an option", comment: "Text field placeholder in Edit Address Form")
}

#if DEBUG

import struct Yosemite.Order
import struct Yosemite.Address

struct EditAddressForm_Previews: PreviewProvider {
    static let sampleOrder = Order(siteID: 123,
                                   orderID: 456,
                                   parentID: 2,
                                   customerID: 11,
                                   orderKey: "",
                                   isEditable: false,
                                   needsPayment: false,
                                   needsProcessing: false,
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
                                   paymentURL: nil,
                                   chargeID: nil,
                                   items: [],
                                   billingAddress: sampleAddress,
                                   shippingAddress: sampleAddress,
                                   shippingLines: [],
                                   coupons: [],
                                   refunds: [],
                                   fees: [],
                                   taxes: [],
                                   customFields: [],
                                   renewalSubscriptionID: nil,
                                   appliedGiftCards: [])

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

    static let sampleViewModel = EditOrderAddressFormViewModel(order: sampleOrder, type: .shipping)

    static var previews: some View {
        NavigationView {
            EditOrderAddressForm(viewModel: sampleViewModel)
        }
    }
}

#endif
