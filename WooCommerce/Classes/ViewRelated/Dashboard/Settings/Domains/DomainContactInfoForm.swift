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

struct DomainContactInfoForm_Previews: PreviewProvider {
    static let sampleViewModel = DomainContactInfoFormViewModel(siteID: 134,
                                                                stores: ServiceLocator.stores)

    static var previews: some View {
        NavigationView {
            DomainContactInfoForm(viewModel: sampleViewModel) { _ in }
        }
    }
}
