import SwiftUI

/// Hosting controller that wraps the `DomainSettingsView` view.
final class DomainSettingsHostingController: UIHostingController<DomainSettingsView> {
    init(viewModel: DomainSettingsViewModel,
         addDomain: @escaping (_ hasDomainCredit: Bool, _ freeStagingDomain: String?) -> Void) {
        super.init(rootView: DomainSettingsView(viewModel: viewModel,
                                                addDomain: addDomain))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
    }
}

/// Shows a site's domains with actions to add a domain or redeem a domain credit.
struct DomainSettingsView: View {
    @ObservedObject private var viewModel: DomainSettingsViewModel
    private let addDomain: (_ hasDomainCredit: Bool, _ freeStagingDomain: String?) -> Void

    init(viewModel: DomainSettingsViewModel, addDomain: @escaping (Bool, String?) -> Void) {
        self.viewModel = viewModel
        self.addDomain = addDomain
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                if let freeDomain = viewModel.freeStagingDomain {
                    HStack {
                        FreeStagingDomainView(domain: freeDomain)
                        Spacer()
                    }
                    .padding(.horizontal, insets: Layout.defaultHorizontalPadding)
                }

                if viewModel.hasDomainCredit {
                    DomainSettingsDomainCreditView() {
                        addDomain(viewModel.hasDomainCredit, viewModel.freeStagingDomain?.name)
                    }
                }

                if viewModel.domains.isNotEmpty {
                    DomainSettingsListView(domains: viewModel.domains) {
                        addDomain(viewModel.hasDomainCredit, viewModel.freeStagingDomain?.name)
                    }
                }
            }
            .padding(Layout.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.domains.isEmpty {
                VStack {
                    Divider()
                        .frame(height: Layout.dividerHeight)
                        .foregroundColor(Color(.separator))
                    Button(Localization.searchDomainButton) {
                        addDomain(viewModel.hasDomainCredit, viewModel.freeStagingDomain?.name)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(Layout.bottomContentPadding)
                }
                .background(Color(.systemBackground))
            }
        }
        .navigationBarTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
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
        static let bottomContentPadding: EdgeInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
        static let contentPadding: EdgeInsets = .init(top: 39, leading: 0, bottom: 16, trailing: 0)
        static let defaultHorizontalPadding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let contentSpacing: CGFloat = 36
    }
}

#if DEBUG

import Yosemite
import enum Networking.DotcomError

/// StoresManager that specifically handles actions for `DomainSettingsView` previews.
final class DomainSettingsViewStores: DefaultStoresManager {
    private let domainsResult: Result<[SiteDomain], Error>
    private let sitePlanResult: Result<WPComSitePlan, Error>

    init(domainsResult: Result<[SiteDomain], Error>,
         sitePlanResult: Result<WPComSitePlan, Error>) {
        self.domainsResult = domainsResult
        self.sitePlanResult = sitePlanResult
        super.init(sessionManager: ServiceLocator.stores.sessionManager)
    }

    override func dispatch(_ action: Action) {
        if let action = action as? DomainAction {
            if case let .loadDomains(_, completion) = action {
                completion(domainsResult)
            }
        } else if let action = action as? PaymentAction {
            if case let .loadSiteCurrentPlan(_, completion) = action {
                completion(sitePlanResult)
            }
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
                                // There is one free domain and two paid domains.
                                domainsResult: .success([
                                    .init(name: "free.test", isPrimary: true),
                                    .init(name: "one.test", isPrimary: false, renewalDate: .distantFuture),
                                    .init(name: "duo.test", isPrimary: true, renewalDate: .now)
                                ]),
                                // The site has domain credit.
                                sitePlanResult: .success(.init(hasDomainCredit: true)))),
                                   addDomain: { _, _ in })
            }

            NavigationView {
                DomainSettingsView(viewModel:
                        .init(siteID: 134,
                              stores: DomainSettingsViewStores(
                                // There is one free domain and no other paid domains.
                                domainsResult: .success([
                                    .init(name: "free.test", isPrimary: true)
                                ]),
                                sitePlanResult: .success(.init(hasDomainCredit: true)))),
                                   addDomain: { _, _ in })
            }
        }
    }
}

#endif
