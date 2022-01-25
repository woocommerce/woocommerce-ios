import Combine
import SwiftUI
import UIKit
import Yosemite

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
        rootView.dismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        // Set up notices
        bindNoticeIntent()
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

    /// Observe the present notice intent and set it back after presented.
    ///
    private func bindNoticeIntent() {
        rootView.viewModel.$presentNotice
            .compactMap { $0 }
            .sink { [weak self] notice in

                switch notice {
                case .success:
                    self?.systemNoticePresenter.enqueue(notice: .init(title: Localization.success, feedbackType: .error))

                case .error(let error):
                    switch error {
                    case .unableToLoadCountries:
                        self?.systemNoticePresenter.enqueue(notice: .init(title: error.errorDescription ?? "", feedbackType: .error))
                        self?.dismiss(animated: true) // Dismiss VC because we need country information to continue.

                    case .unableToUpdateAddress:
                        self?.modalNoticePresenter.enqueue(notice: .init(title: error.errorDescription ?? "",
                                                                         message: error.recoverySuggestion,
                                                                         feedbackType: .error))
                    }
                }

                // Nullify the presentation intent.
                self?.rootView.viewModel.presentNotice = nil
            }
            .store(in: &subscriptions)
    }
}

/// Intercepts to the dismiss drag gesture.
///
extension EditOrderAddressHostingController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        !rootView.viewModel.hasPendingChanges()
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

/// Allows merchant to edit the customer provided address of an order.
///
struct EditOrderAddressForm<ViewModel: AddressFormViewModelProtocol>: View {

    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: (() -> Void) = {}

    /// View Model for the view
    ///
    @ObservedObject private(set) var viewModel: ViewModel

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        Group {
            ScrollView {
                SingleAddressForm(fields: $viewModel.fields,
                                  countryViewModelClosure: viewModel.createCountryViewModel,
                                  stateViewModelClosure: viewModel.createStateViewModel,
                                  sectionTitle: viewModel.sectionTitle,
                                  showEmailField: viewModel.showEmailField,
                                  showStateFieldAsSelector: viewModel.showStateFieldAsSelector)

                if viewModel.showAlternativeUsageToggle, let alternativeUsageToggleTitle = viewModel.alternativeUsageToggleTitle {
                    TitleAndToggleRow(title: alternativeUsageToggleTitle, isOn: $viewModel.fields.useAsToggle)
                        .padding(.horizontal, Constants.horizontalPadding)
                        .padding(.vertical, Constants.verticalPadding)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(.systemBackground))
                }

                if viewModel.showDifferentAddressToggle, let differentAddressToggleTitle = viewModel.differentAddressToggleTitle {
                    TitleAndToggleRow(title: differentAddressToggleTitle, isOn: $viewModel.showDifferentAddressForm)
                        .padding(.horizontal, Constants.horizontalPadding)
                        .padding(.vertical, Constants.verticalPadding)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(.systemBackground))
                }

                if viewModel.showDifferentAddressForm {
                    SingleAddressForm(fields: $viewModel.fields,
                                      countryViewModelClosure: viewModel.createCountryViewModel,
                                      stateViewModelClosure: viewModel.createStateViewModel,
                                      sectionTitle: viewModel.sectionTitle,
                                      showEmailField: false,
                                      showStateFieldAsSelector: viewModel.showStateFieldAsSelector)
                }
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
                    dismiss()
                    viewModel.userDidCancelFlow()
                })
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
    }

    /// Decides if the navigation trailing item should be a done button or a loading indicator.
    ///
    @ViewBuilder func navigationBarTrailingItem() -> some View {
        switch viewModel.navigationTrailingItem {
        case .done(let enabled):
            Button(Localization.done) {
                viewModel.saveAddress(onFinish: { success in
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

struct SingleAddressForm: View {

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    @Binding var fields: AddressFormFields

    let countryViewModelClosure: () -> CountrySelectorViewModel
    let stateViewModelClosure: () -> StateSelectorViewModel

    let sectionTitle: String
    let showEmailField: Bool
    let showStateFieldAsSelector: Bool

    /// Set it to `true` to present the country selector.
    ///
    @State private var showCountrySelector = false

    /// Set it to `true` to present the state selector.
    ///
    @State private var showStateSelector = false

    var body: some View {
        ListHeaderView(text: Localization.detailsSection, alignment: .left)
            .padding(.horizontal, insets: safeAreaInsets)
        VStack(spacing: 0) {
            TitleAndTextFieldRow(title: Localization.firstNameField,
                                 placeholder: "",
                                 text: $fields.firstName,
                                 symbol: nil,
                                 keyboardType: .default)
            Divider()
                .padding(.leading, Constants.dividerPadding)
            TitleAndTextFieldRow(title: Localization.lastNameField,
                                 placeholder: "",
                                 text: $fields.lastName,
                                 symbol: nil,
                                 keyboardType: .default)
            Divider()
                .padding(.leading, Constants.dividerPadding)

            if showEmailField {
                TitleAndTextFieldRow(title: Localization.emailField,
                                     placeholder: "",
                                     text: $fields.email,
                                     symbol: nil,
                                     keyboardType: .emailAddress)
                    .autocapitalization(.none)
                Divider()
                    .padding(.leading, Constants.dividerPadding)

            }

            TitleAndTextFieldRow(title: Localization.phoneField,
                                 placeholder: "",
                                 text: $fields.phone,
                                 symbol: nil,
                                 keyboardType: .phonePad)
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.systemBackground))

        ListHeaderView(text: sectionTitle, alignment: .left)
            .padding(.horizontal, insets: safeAreaInsets)
        VStack(spacing: 0) {
            Group {
                TitleAndTextFieldRow(title: Localization.companyField,
                                     placeholder: Localization.placeholderOptional,
                                     text: $fields.company,
                                     symbol: nil,
                                     keyboardType: .default)
                Divider()
                    .padding(.leading, Constants.dividerPadding)
                TitleAndTextFieldRow(title: Localization.address1Field,
                                     placeholder: "",
                                     text: $fields.address1,
                                     symbol: nil,
                                     keyboardType: .default)
                Divider()
                    .padding(.leading, Constants.dividerPadding)
                TitleAndTextFieldRow(title: Localization.address2Field,
                                     placeholder: Localization.placeholderOptional,
                                     text: $fields.address2,
                                     symbol: nil,
                                     keyboardType: .default)
                Divider()
                    .padding(.leading, Constants.dividerPadding)
                TitleAndTextFieldRow(title: Localization.cityField,
                                     placeholder: "",
                                     text: $fields.city,
                                     symbol: nil,
                                     keyboardType: .default)
                Divider()
                    .padding(.leading, Constants.dividerPadding)
                TitleAndTextFieldRow(title: Localization.postcodeField,
                                     placeholder: "",
                                     text: $fields.postcode,
                                     symbol: nil,
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

                TitleAndValueRow(title: Localization.countryField,
                                 value: .init(placeHolder: Localization.placeholderSelectOption, content: fields.countryName),
                                 selectable: true) {
                    showCountrySelector = true
                }
                Divider()
                    .padding(.leading, Constants.dividerPadding)
                stateRow()
            }
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.systemBackground))
    }

    /// Decides if the state row should be rendered as a list selector field or as a text input field.
    ///
    @ViewBuilder private func stateRow() -> some View {
        if showStateFieldAsSelector {
            TitleAndValueRow(title: Localization.stateField,
                             value: .init(placeHolder: Localization.placeholderSelectOption, content: fields.stateName),
                             selectable: true) {
                showStateSelector = true
            }
        } else {
            TitleAndTextFieldRow(title: Localization.stateField,
                                 placeholder: "",
                                 text: $fields.stateName,
                                 symbol: nil,
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

    static let success = NSLocalizedString("Address successfully updated.", comment: "Notice text after updating the shipping or billing address")
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
                                   fees: [],
                                   taxes: [])

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
