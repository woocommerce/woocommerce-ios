import SwiftUI

/// Hosting controller that wraps the `DomainSettingsView` view.
final class DomainSettingsHostingController: UIHostingController<DomainSettingsView> {
    /// - Parameters:
    ///   - viewModel: View model for the domain settings.
    init(viewModel: DomainSettingsViewModel) {
        super.init(rootView: DomainSettingsView(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
    }
}

final class DomainSettingsViewModel: ObservableObject {
    struct Domain {
        /// Whether the domain is the site's primary domain.
        let isPrimary: Bool

        /// The address of the domain.
        let name: String

        // The next renewal date.
        let autoRenewalDate: Date?
    }

    struct FreeStagingDomain {
        /// Whether the domain is the site's primary domain.
        let isPrimary: Bool

        /// The address of the domain.
        let name: String
    }

    @Published private(set) var hasDomainCredit: Bool = false
    @Published private(set) var domains: [Domain] = []
    @Published private(set) var freeStagingDomain: FreeStagingDomain?

    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    func onAppear() {
        stores.dispatch(DomainAction.loadDomains(siteID: siteID) { [weak self] result in
            self?.handleDomainsResult(result)
        })
    }
}

private extension DomainSettingsViewModel {
    func handleDomainsResult(_ result: Result<[SiteDomain], Error>) {
        switch result {
        case .success(let domains):
            let stagingDomain = domains.first(where: { $0.renewalDate == nil })
            freeStagingDomain = stagingDomain
                .map { FreeStagingDomain(isPrimary: $0.isPrimary, name: $0.name) }
            self.domains = domains.filter { $0 != stagingDomain }
                .map { Domain(isPrimary: $0.isPrimary, name: $0.name, autoRenewalDate: $0.renewalDate) }
        case .failure(let error):
            DDLogError("⛔️ Error retrieving domains for siteID \(siteID): \(error)")
        }
    }
}

struct DomainSettingsView: View {
    @ObservedObject private var viewModel: DomainSettingsViewModel

    init(viewModel: DomainSettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                if let freeDomain = viewModel.freeStagingDomain {
                    HStack {
                        FreeStagingDomainView(domain: freeDomain)
                        Spacer()
                    }
                }

                if viewModel.hasDomainCredit {
                    // TODO: 8558 - domain credit UI with redemption action
                }

                if viewModel.domains.isNotEmpty {
                    // TODO: 8558 - show domain list with search domain action
                }
            }
            .padding(.init(top: 39, leading: 16, bottom: 16, trailing: 16))
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.domains.isEmpty {
                VStack {
                    Divider()
                        .frame(height: Layout.dividerHeight)
                        .foregroundColor(Color(.separator))
                    Button(Localization.searchDomainButton) {
                        // TODO: 8558 - search domain action
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(Layout.defaultPadding)
                }
                .background(Color(.systemBackground))
            }
        }
        .navigationBarTitle(Localization.title)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.onAppear()
        }
    }
}

private extension DomainSettingsView {
    enum Localization {
        static let title = NSLocalizedString("Domain", comment: "Navigation bar title of the domain settings screen.")
        static let searchDomainButton = NSLocalizedString(
            "Search for a Domain",
            comment: "Title of the button on the domain settings screen to search for a domain."
        )
    }
}

private extension DomainSettingsView {
    enum Layout {
        static let dividerHeight: CGFloat = 1
        static let defaultPadding: EdgeInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
    }
}

#if DEBUG

import Yosemite
import enum Networking.DotcomError

/// StoresManager that specifically handles `DomainAction` for `DomainSettingsView` previews.
final class DomainSettingsViewStores: DefaultStoresManager {
    private let result: Result<[SiteDomain], Error>?

    init(result: Result<[SiteDomain], Error>?) {
        self.result = result
        super.init(sessionManager: ServiceLocator.stores.sessionManager)
    }

    override func dispatch(_ action: Action) {
        if let action = action as? DomainAction {
            if case let .loadDomains(_, completion) = action {
                if let result {
                    completion(result)
                }
            }
            // TODO: plan action
        }
    }
}

struct DomainSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                DomainSettingsView(viewModel:
                        .init(siteID: 134,
                              stores: DomainSettingsViewStores(
                                result: .success([
                                    .init(name: "free.test", isPrimary: true),
                                    .init(name: "one.test", isPrimary: false, renewalDate: .distantFuture),
                                    .init(name: "duo.test", isPrimary: true, renewalDate: .now)
                                ]))))
            }

            NavigationView {
                DomainSettingsView(viewModel:
                        .init(siteID: 134,
                              stores: DomainSettingsViewStores(
                                result: .success([
                                    .init(name: "free.test", isPrimary: true)
                                ]))))
            }
        }
    }
}

#endif
