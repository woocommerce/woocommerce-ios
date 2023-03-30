import SwiftUI
import Yosemite

/// View model for `StoreOnboardingLaunchStoreView`.
final class StoreOnboardingLaunchStoreViewModel: ObservableObject {
    /// UI state of the lauch store view.
    enum State {
        // Checking current site's plan to check for free trial
        case checkingSitePlan
        // Using free trial. Need to purchase plan before publishing site.
        case needsPlanUpgrade
        // Ready to publish site.
        case readyToPublish
        // Processing launch store request
        case launchingStore
    }

    let siteURL: URL

    @Published private(set) var state: State = .checkingSitePlan
    @Published var error: SiteLaunchError?

    lazy var upgradePlanAttributedString: NSAttributedString = {
        let font: UIFont = .body
        let foregroundColor: UIColor = .text
        let linkColor: UIColor = .textLink
        let linkContent = Localization.upgrade

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let attributedString = NSMutableAttributedString(
            string: .localizedStringWithFormat(Localization.upgradePlanToLaunchStore, linkContent),
            attributes: [.font: font,
                         .foregroundColor: foregroundColor,
                         .paragraphStyle: paragraphStyle,
                        ]
        )
        let upgradeLink = NSAttributedString(string: linkContent, attributes: [.font: font,
                                                                                      .foregroundColor: linkColor,
                                                                                      .underlineStyle: NSUnderlineStyle.single.rawValue,
                                                                                      .underlineColor: UIColor.textLink])
        attributedString.replaceFirstOccurrence(of: linkContent, with: upgradeLink)
        return attributedString
    }()

    private let siteID: Int64
    private let stores: StoresManager
    private let onLaunch: () -> Void

    /// Closure invoked when the merchants taps on the `Upgrade` button.
    ///
    private let onUpgradeTapped: () -> Void

    init(siteURL: URL,
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         onLaunch: @escaping () -> Void,
         onUpgradeTapped: @escaping () -> Void) {
        self.siteURL = siteURL
        self.siteID = siteID
        self.stores = stores
        self.onLaunch = onLaunch
        self.onUpgradeTapped = onUpgradeTapped
    }

    @MainActor
    func checkEligibilityToPublishStore() async {
        update(state: .checkingSitePlan)
        if await isFreeTrialPlan() {
            update(state: .needsPlanUpgrade)
        } else {
            update(state: .readyToPublish)
        }
    }

    @MainActor
    func launchStore() async {
        error = nil
        update(state: .launchingStore)
        let result = await launchStoreRemotely()
        switch result {
        case .success:
            onLaunch()
        case .failure(let error):
            self.error = error
            update(state: .readyToPublish)
        }
    }

    @MainActor
    func didTapUpgrade() {
        onUpgradeTapped()
    }
}

private extension StoreOnboardingLaunchStoreViewModel {
    @MainActor
    func update(state: State) {
        self.state = state
    }

    @MainActor
    func isFreeTrialPlan() async -> Bool {
        // Only fetch free trial information if the site is a WPCom site.
        guard stores.sessionManager.defaultSite?.isWordPressComStore == true else {
            return false
        }

        return await withCheckedContinuation({ continuation in
            let action = PaymentAction.loadSiteCurrentPlan(siteID: siteID) { result in
                switch result {
                case .success(let plan):
                    return continuation.resume(returning: plan.isFreeTrial)
                case .failure(let error):
                    DDLogError("⛔️ Error fetching the current site's plan information: \(error)")
                    return continuation.resume(returning: false)
                }
            }
            stores.dispatch(action)
        })
    }

    @MainActor
    func launchStoreRemotely() async -> Result<Void, SiteLaunchError> {
        await withCheckedContinuation { continuation in
            stores.dispatch(SiteAction.launchSite(siteID: siteID) { result in
                continuation.resume(returning: result)
            })
        }
    }
}

private extension StoreOnboardingLaunchStoreViewModel {
    enum Localization {
        static let upgradePlanToLaunchStore = NSLocalizedString(
            "To launch your store, you need to upgrade to our plan. %1$@",
            comment: "Message to ask the user to upgrade free trial plan to launch store."
            + "Reads - To launch your store, you need to upgrade to our plan. Upgrade"
        )
        static let upgrade = NSLocalizedString("Upgrade", comment: "Title on the button to upgrade a free trial plan.")
    }
}
