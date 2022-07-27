import Combine
import Experiments
import UIKit
import Yosemite
import class AutomatticTracks.CrashLogging

/// Coordinates app navigation based on authentication state: tab bar UI is shown when the app is logged in, and authentication UI is shown
/// when the app is logged out.
///
final class AppCoordinator {
    let tabBarController: MainTabBarController

    private let window: UIWindow
    private let stores: StoresManager
    private let authenticationManager: Authentication
    private let roleEligibilityUseCase: RoleEligibilityUseCaseProtocol
    private let analytics: Analytics
    private let loggedOutAppSettings: LoggedOutAppSettingsProtocol
    private let featureFlagService: FeatureFlagService

    private var storePickerCoordinator: StorePickerCoordinator?
    private var authStatesSubscription: AnyCancellable?
    private var localNotificationResponsesSubscription: AnyCancellable?
    private var isLoggedIn: Bool = false

    init(window: UIWindow,
         stores: StoresManager = ServiceLocator.stores,
         authenticationManager: Authentication = ServiceLocator.authenticationManager,
         roleEligibilityUseCase: RoleEligibilityUseCaseProtocol = RoleEligibilityUseCase(),
         analytics: Analytics = ServiceLocator.analytics,
         loggedOutAppSettings: LoggedOutAppSettingsProtocol = LoggedOutAppSettings(userDefaults: .standard),
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.window = window
        self.tabBarController = {
            let storyboard = UIStoryboard(name: "Main", bundle: nil) // Main is the name of storyboard
            guard let tabBarController = storyboard.instantiateInitialViewController() as? MainTabBarController else {
                fatalError("Cannot load main tab bar controller from Storyboard")
            }
            return tabBarController
        }()
        self.stores = stores
        self.authenticationManager = authenticationManager
        self.roleEligibilityUseCase = roleEligibilityUseCase
        self.analytics = analytics
        self.loggedOutAppSettings = loggedOutAppSettings
        self.featureFlagService = featureFlagService
    }

    func start() {
        authStatesSubscription = Publishers.CombineLatest(stores.isLoggedInPublisher, stores.needsDefaultStorePublisher)
            .sink {  [weak self] isLoggedIn, needsDefaultStore in
                guard let self = self else { return }

                // More details about the UI states: https://github.com/woocommerce/woocommerce-ios/pull/3498
                switch (isLoggedIn, needsDefaultStore) {
                case (false, true), (false, false):
                    self.displayAuthenticator()
                case (true, true):
                    self.displayStorePicker()
                case (true, false):
                    self.validateRoleEligibility {
                        self.displayLoggedInUI()
                        self.synchronizeAndShowWhatsNew()
                    }
                }
                self.isLoggedIn = isLoggedIn
            }

        localNotificationResponsesSubscription = ServiceLocator.pushNotesManager.localNotificationResponses.sink { [weak self] response in
            self?.handleLocalNotificationResponse(response)
        }
    }
}

private extension AppCoordinator {

    /// Synchronize announcements and present What's New Screen if needed
    ///
    func synchronizeAndShowWhatsNew() {
        stores.dispatch(AnnouncementsAction.synchronizeAnnouncements(onCompletion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let announcement):
                DDLogInfo("📣 Announcements Synced! AppVersion: \(announcement.appVersionName) | AnnouncementVersion: \(announcement.announcementVersion)")
            case .failure(let error):
                if error as? AnnouncementsError == .announcementNotFound {
                    DDLogInfo("📣 Announcements synced, but nothing received.")
                } else {
                    DDLogError("⛔️ Failed to synchronize announcements: \(error.localizedDescription)")
                }
            }
            self.showWhatsNewIfNeeded()
        }))
    }

    /// Load saved announcement and display it on What's New component if it was not displayed yet
    ///
    func showWhatsNewIfNeeded() {
        stores.dispatch(AnnouncementsAction.loadSavedAnnouncement(onCompletion: { [weak self] result in
            guard let self = self else { return }
            guard let (announcement, displayed) = try? result.get(), !displayed else {
                return DDLogInfo("📣 There are no announcements to show!")
            }
            ServiceLocator.analytics.track(event: .featureAnnouncementShown(source: .appUpgrade))
            let whatsNewViewController = WhatsNewFactory.whatsNew(announcement) { [weak self] in
                self?.tabBarController.dismiss(animated: true)
            }
            self.tabBarController.present(whatsNewViewController, animated: true, completion: nil)
        }))
    }

    /// Displays the WordPress.com Authentication UI.
    ///
    func displayAuthenticator() {
        let authenticationUI = authenticationManager.authenticationUI()
        setWindowRootViewControllerAndAnimateIfNeeded(authenticationUI) { [weak self] _ in
            guard let self = self else { return }
            self.tabBarController.removeViewControllers()

            self.presentLoginOnboarding()
        }
        ServiceLocator.analytics.track(.openedLogin)
    }

    /// Presents onboarding on top of the authentication UI under certain criteria.
    func presentLoginOnboarding() {
        // Since we cannot control the user defaults in the simulator where UI tests are run on,
        // login onboarding is not shown in UI tests for now.
        // If we want to add UI tests for the login onboarding, we can add another launch argument
        // so that we can show/hide the onboarding screen consistently.
        let isUITesting: Bool = CommandLine.arguments.contains("-ui_testing")
        guard isUITesting == false else {
            return
        }

        guard featureFlagService.isFeatureFlagEnabled(.loginPrologueOnboarding),
        loggedOutAppSettings.hasFinishedOnboarding == false else {
            return
        }
        let onboardingViewController = LoginOnboardingViewController { [weak self] action in
            guard let self = self else { return }
            self.loggedOutAppSettings.setHasFinishedOnboarding(true)
            self.window.rootViewController?.dismiss(animated: true)

            switch action {
            case .next:
                self.analytics.track(event: .LoginOnboarding.loginOnboardingNextButtonTapped(isFinalPage: true))
            case .skip:
                self.analytics.track(event: .LoginOnboarding.loginOnboardingSkipButtonTapped())
            }
        }
        onboardingViewController.modalPresentationStyle = .fullScreen
        onboardingViewController.modalTransitionStyle = .crossDissolve
        window.rootViewController?.present(onboardingViewController, animated: false)

        analytics.track(event: .LoginOnboarding.loginOnboardingShown())
    }

    /// Displays logged in tab bar UI.
    ///
    func displayLoggedInUI() {
        setWindowRootViewControllerAndAnimateIfNeeded(tabBarController)
    }

    /// If the app is authenticated but there is no default store ID on launch: Let's display the Store Picker.
    ///
    func displayStorePicker() {
        // Store picker is only displayed by `AppCoordinator` on launch, when the window's root is uninitialized.
        // In other cases when the app is authenticated but there is no default store ID, the store picker is shown by authentication UI.
        guard window.rootViewController == nil else {
            return
        }

        DDLogInfo("💬 Authenticated user does not have a Woo store selected — launching store picker.")
        let navigationController = WooNavigationController()
        setWindowRootViewControllerAndAnimateIfNeeded(navigationController)
        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .standard)
        storePickerCoordinator?.start()
        storePickerCoordinator?.onDismiss = { [weak self] in
            guard let self = self else { return }
            if self.isLoggedIn == false {
                self.displayAuthenticator()
            }
        }
    }

    /// Displays the role error page as the root view.
    ///
    func displayRoleErrorUI(for siteID: Int64, errorInfo: StorageEligibilityErrorInfo) {
        let errorViewModel = RoleErrorViewModel(siteID: siteID, title: errorInfo.name, subtitle: errorInfo.humanizedRoles)
        let errorViewController = RoleErrorViewController(viewModel: errorViewModel)

        // when the retry is successful, resume the intention to display the main tab bar.
        errorViewModel.onSuccess = {
            self.displayLoggedInUI()
        }

        errorViewModel.onDeauthenticationRequest = {
            self.stores.deauthenticate()
        }

        // this needs to be wrapped within a navigation controller to properly show the right bar button for Help.
        setWindowRootViewControllerAndAnimateIfNeeded(WooNavigationController(rootViewController: errorViewController))
    }

    /// Synchronously check if there's any `EligibilityErrorInfo` stored locally. If there is, then let's show the role error UI instead.
    ///
    /// Note: this method should be *only* be called in authenticated state, and defaultStoreID exists.
    /// otherwise, this may indicate an implementation error.
    ///
    /// - Parameter onSuccess: Closure to be called when the user is eligible.
    ///
    func validateRoleEligibility(onSuccess: @escaping () -> Void) {
        guard stores.isAuthenticated, let storeID = stores.sessionManager.defaultStoreID else {
            return
        }

        let action = AppSettingsAction.loadEligibilityErrorInfo { [weak self] result in
            guard let self = self else { return }

            // if the previous role check indicates that the user is ineligible, let's show the error message.
            if let errorInfo = try? result.get() {
                self.displayRoleErrorUI(for: storeID, errorInfo: errorInfo)
                return
            }

            // Even if the previous check was successful, we need to check if the user is still eligible *now*.
            // The latest eligibility status will be fetched asynchronously.
            self.roleEligibilityUseCase.checkEligibility(for: storeID) { result in
                // we only care about the insufficientRole error, because that indicates that the user is no longer eligible.
                // in this case, we'll forcefully show the role error page.
                if let error = result.failure, case let .insufficientRole(errorInfo) = error {
                    self.displayRoleErrorUI(for: storeID, errorInfo: errorInfo)
                }
            }

            onSuccess()
        }
        stores.dispatch(action)
    }

    func handleLocalNotificationResponse(_ response: UNNotificationResponse) {
        switch response.actionIdentifier {
        case LocalNotification.Action.contactSupport.rawValue:
            guard let viewController = window.rootViewController else {
                return
            }
            ZendeskProvider.shared.showNewRequestIfPossible(from: viewController, with: nil)
            analytics.track(.loginLocalNotificationTapped, withProperties: [
                "action": "contact_support",
                "type": response.notification.request.identifier
            ])
        case UNNotificationDefaultActionIdentifier:
            // Triggered when the user taps on the notification itself instead of one of the actions.
            switch response.notification.request.identifier {
            case LocalNotification.Scenario.loginSiteAddressError.rawValue:
                analytics.track(.loginLocalNotificationTapped, withProperties: [
                    "action": "default",
                    "type": response.notification.request.identifier
                ])
            default:
                break
            }
        case UNNotificationDismissActionIdentifier:
            // Triggered when the user taps on the notification's "Clear" action.
            switch response.notification.request.identifier {
            case LocalNotification.Scenario.loginSiteAddressError.rawValue:
                analytics.track(.loginLocalNotificationDismissed, withProperties: [
                    "type": response.notification.request.identifier
                ])
            default:
                break
            }
        default:
            break
        }
    }
}

private extension AppCoordinator {
    /// Sets the app window's root view controller, with animation only if the root view controller is previously non-nil.
    /// - Parameters:
    ///   - rootViewController: view controller to be set as the window's root view controller.
    ///   - onCompletion: called after the root view controller is set after animation if needed.
    ///                   The boolean value indicates whether or not the animations actually finished before the completion handler was called.
    func setWindowRootViewControllerAndAnimateIfNeeded(_ rootViewController: UIViewController, onCompletion: @escaping (Bool) -> Void = { _ in }) {
        // Animates window transition only if the root view controller is non-nil originally.
        let shouldAnimate = window.rootViewController != nil
        window.rootViewController = rootViewController
        if shouldAnimate {
            UIView.transition(with: window, duration: Constants.animationDuration, options: .transitionCrossDissolve, animations: {}, completion: onCompletion)
        } else {
            onCompletion(false)
        }
    }
}

private extension AppCoordinator {
    enum Constants {
        static let animationDuration = TimeInterval(0.3)
    }
}
