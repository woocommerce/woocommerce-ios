import SwiftUI
import struct Yosemite.DomainContactInfo

/// Hosting controller that wraps the `DomainContactInfoForm` view for the user to edit contact info for redeeming a domain.
final class DomainContactInfoFormHostingController: UIHostingController<DomainContactInfoForm> {
    /// - Parameters:
    ///   - viewModel: View model for the domain contact info form.
    ///   - onCompletion: Called when the contact info is complete and validated.
    init(viewModel: DomainContactInfoFormViewModel,
         onCompletion: @escaping (DomainContactInfo) async -> Void) {
        super.init(rootView: DomainContactInfoForm(viewModel: viewModel,
                                                  onCompletion: onCompletion))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
    }
}

/// Allows the user to edit contact info when claiming a domain with domain credit.
struct DomainContactInfoForm: View {
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets
    @State private var showingCustomerSearch: Bool = false
    @StateObject private var viewModel: DomainContactInfoFormViewModel
    private let onCompletion: (DomainContactInfo) async -> Void

    init(viewModel: DomainContactInfoFormViewModel,
         onCompletion: @escaping (DomainContactInfo) async -> Void) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onCompletion = onCompletion
    }

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

                Spacer(minLength: safeAreaInsets.bottom)
            }
            .disableAutocorrection(true)
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        }
        .navigationTitle(viewModel.viewTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
    }

    /// Decides if the navigation trailing item should be a done button or a loading indicator.
    ///
    @ViewBuilder func navigationBarTrailingItem() -> some View {
        switch viewModel.navigationTrailingItem {
        case .done(let enabled):
            Button(Localization.done) {
                Task { @MainActor in
                    do {
                        viewModel.performingNetworkRequest.send(true)
                        let contactInfo = try await viewModel.validateContactInfo()
                        await onCompletion(contactInfo)
                        viewModel.performingNetworkRequest.send(false)
                    } catch {
                        viewModel.performingNetworkRequest.send(false)
                    }
                }
            }
            .disabled(!enabled)
        case .loading:
            ProgressView()
        }
    }
}

private extension DomainContactInfoForm {
    enum Localization {
        static let done = NSLocalizedString("Done", comment: "Text for the done button in the domain contact info form.")
    }
}

#if DEBUG

import Yosemite

/// StoresManager that specifically handles `DomainAction` for `DomainSelectorView` previews.
final private class DomainContactInfoFormStores: DefaultStoresManager {
    init() {
        super.init(sessionManager: ServiceLocator.stores.sessionManager)
    }

    override func dispatch(_ action: Action) {
        if let action = action as? DataAction {
            if case let .synchronizeCountries(_, completion) = action {
                completion(.success([.init(code: "US", name: "United States", states: [.init(code: "CA", name: "California")])]))
            }
        }
    }
}


struct DomainContactInfoForm_Previews: PreviewProvider {
    private static let viewModelWithoutContactInfo = DomainContactInfoFormViewModel(siteID: 134,
                                                                                    contactInfoToEdit: nil,
                                                                                    domain: "",
                                                                                    stores: DomainContactInfoFormStores())
    private static let contactInfo = DomainContactInfo(firstName: "Woo",
                                                       lastName: "Testing",
                                                       organization: "WooCommerce org",
                                                       address1: "335 2nd St",
                                                       address2: "Apt 222",
                                                       postcode: "94111",
                                                       city: "San Francisco",
                                                       state: "CA",
                                                       countryCode: "US",
                                                       phone: "+886.911123456",
                                                       email: "woo@store.com")
    private static let viewModelWithContactInfo = DomainContactInfoFormViewModel(siteID: 134,
                                                                                 contactInfoToEdit: contactInfo,
                                                                                 domain: "",
                                                                                 stores: DomainContactInfoFormStores())

    static var previews: some View {
        NavigationView {
            DomainContactInfoForm(viewModel: viewModelWithoutContactInfo) { _ in }
        }
        .previewDisplayName("Empty contact info")

        NavigationView {
            DomainContactInfoForm(viewModel: viewModelWithContactInfo) { _ in }
        }
        .previewDisplayName("Pre-filled contact info")
    }
}

#endif
