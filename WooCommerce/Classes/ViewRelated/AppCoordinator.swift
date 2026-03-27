import Combine
import Experiments
import SafariServices
import UIKit
import WordPressAuthenticator
import Yosemite
import class AutomatticTracks.CrashLogging
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

@MainActor
final class AppCoordinator {
    let tabBarController: MainTabBarController

    private let window: UIWindow
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private var authenticationManager: Authentication
    private let roleEligibilityUseCase: RoleEligibilityUseCaseProtocol
    private let analytics: Analytics
    private let loggedOutAppSettings: LoggedOutAppSettingsProtocol
    private let pushNotesManager: PushNotesManager
    private let featureFlagService: FeatureFlagService
    private let switchStoreUseCase: SwitchStoreUseCaseProtocol
    private let localOperatorSessionController: LocalOperatorSessionControlling

    private var storePickerCoordinator: StorePickerCoordinator?
    private var authStatesSubscription: AnyCancellable?
    private var localNotificationResponsesSubscription: AnyCancellable?
    private var localOperatorLockSubscription: AnyCancellable?
    private var isLoggedIn: Bool = false
    private let themeInstaller: ThemeInstaller

    /// Checks on whether the Apple ID credential is valid when the app is logged in and becomes active.
    ///
    private lazy var appleIDCredentialChecker = AppleIDCredentialChecker()

    /// Handles the age range verification process and corresponding app/UI state behaviour.
    private let ageRangeVerificationCoordinator: AgeRangeVerificationCoordinatorProtocol = AgeRangeVerificationCoordinator()

    init(window: UIWindow,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         authenticationManager: Authentication = ServiceLocator.authenticationManager,
         roleEligibilityUseCase: RoleEligibilityUseCaseProtocol = RoleEligibilityUseCase(),
         analytics: Analytics = ServiceLocator.analytics,
         loggedOutAppSettings: LoggedOutAppSettingsProtocol = LoggedOutAppSettings(userDefaults: .standard),
         pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         localOperatorSessionController: LocalOperatorSessionControlling? = nil,
         switchStoreUseCase: SwitchStoreUseCaseProtocol? = nil,
         themeInstaller: ThemeInstaller = DefaultThemeInstaller()) {
        self.window = window
        self.tabBarController = {
            let storyboard = UIStoryboard(name: "Main", bundle: nil) // Main is the name of storyboard
            guard let tabBarController = storyboard.instantiateInitialViewController() as? MainTabBarController else {
                fatalError("Cannot load main tab bar controller from Storyboard")
            }
            return tabBarController
        }()
        self.stores = stores
        self.storageManager = storageManager
        self.authenticationManager = authenticationManager
        self.roleEligibilityUseCase = roleEligibilityUseCase
        self.analytics = analytics
        self.loggedOutAppSettings = loggedOutAppSettings
        self.pushNotesManager = pushNotesManager
        self.featureFlagService = featureFlagService
        self.localOperatorSessionController = localOperatorSessionController ?? ServiceLocator.localOperatorSessionController
        self.switchStoreUseCase = switchStoreUseCase ?? SwitchStoreUseCase(stores: stores, storageManager: storageManager)
        authenticationManager.setLoggedOutAppSettings(loggedOutAppSettings)
        self.themeInstaller = themeInstaller

        // Configures authenticator first in case `WordPressAuthenticator` is used in other `AppDelegate` launch events.
        configureAuthenticator()

        schedulePOSSurveyNotificationIfNeeded()
    }

    func start() {
        authStatesSubscription = Publishers.CombineLatest(stores.isLoggedInPublisher, stores.needsDefaultStorePublisher)
            .sink {  [weak self] isLoggedIn, needsDefaultStore in
                guard let self = self else { return }

                // More details about the UI states: https://github.com/woocommerce/woocommerce-ios/pull/3498
                switch (isLoggedIn, needsDefaultStore) {
                case (false, true):
                    self.displayAuthenticatorWithOnboardingIfNeeded()
                case (false, false):
                    // This is not an expected auth state. When the user is logged out, we expect the default store will not be set.
                    // Starting the auth flow from this state seems to cause a crash: peaMlT-hY-p2
                    // To get into the expected logged-out state, we can fully deauthenticate before starting the auth flow.
                    DDLogWarn("⚠️ Unexpected authentication state: Unauthenticated user has a default store set.")
                    stores.deauthenticate()
                    self.displayAuthenticatorWithOnboardingIfNeeded()
                case (true, true):
                    self.displayLoggedInStateWithoutDefaultStore()
                case (true, false):
                    self.validateRoleEligibility {
                        self.displayLoggedInUI()
                        self.triggerAgeVerification()
                        self.synchronizeAndShowWhatsNew()
                    }
                }
                self.isLoggedIn = isLoggedIn
            }

        localNotificationResponsesSubscription = pushNotesManager.localNotificationUserResponses.sink { [weak self] response in
            self?.handleLocalNotificationResponse(response)
        }

        if let localOperatorSessionController = localOperatorSessionController as? LocalOperatorSessionController {
            localOperatorLockSubscription = localOperatorSessionController.$isLocked
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isLocked in
                    guard let self, self.isLoggedIn else { return }
                    if isLocked, localOperatorSessionController.isDeviceStaffModeEnabled {
                        self.presentLocalOperatorFlowIfNeeded()
                    } else {
                        self.dismissLocalOperatorFlowIfNeeded()
                    }
                }
        }
        updateSitePropertiesIfNeeded()
    }
}

private extension AppCoordinator {
    func schedulePOSSurveyNotificationIfNeeded() {
        Task { @MainActor in
            await POSNotificationScheduler(stores: stores).scheduleLocalNotificationIfEligible(for: .currentMerchant)
        }
    }
}

private extension AppCoordinator {
    // Fetch latest site properties and update the default store if anything has changed:
    //
    func updateSitePropertiesIfNeeded() {
        if let siteID = stores.sessionManager.defaultSite?.siteID {
            let action = SiteAction.syncSite(siteID: siteID, completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let site):
                    self.stores.updateDefaultStore(site)
                case .failure(let error):
                    DDLogError("⛔️ Failed to sync default store \(error)")
                }
            })
            stores.dispatch(action)
        }
    }

    func handleLocalNotificationResponse(_ response: UNNotificationResponse) {
        let identifier = response.notification.request.identifier

        let userInfo = response.notification.request.content.userInfo
        guard response.actionIdentifier != UNNotificationDismissActionIdentifier else {
            analytics.track(event: .LocalNotification.dismissed(type: LocalNotification.Scenario.identifierForAnalytics(identifier),
                                                                userInfo: userInfo))
            return
        }

        let posSurveyScenarios = [
            LocalNotification.Scenario.pointOfSalePotentialMerchant.identifier,
            LocalNotification.Scenario.pointOfSaleCurrentMerchant.identifier,
        ]

        if posSurveyScenarios.contains(identifier),
           let surveyURLString = userInfo[LocalNotification.UserInfoKey.surveyURL] as? String,
           let surveyURL = URL(string: surveyURLString) {
            presentSurveyWebView(url: surveyURL)
        }

        analytics.track(event: .LocalNotification.tapped(type: LocalNotification.Scenario.identifierForAnalytics(identifier),
                                                         userInfo: userInfo))
    }

    private func presentSurveyWebView(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        // POS mode is presented via a UIHostingController as full-screen view on top of the tabBarController, so
        // we have to target the topmost VC if we want to present a web view on top of this when tapping on the local notification.
        if let topmostPresentedViewController = window.topmostPresentedViewController {
            topmostPresentedViewController.present(safariViewController, animated: true)
        } else {
            tabBarController.present(safariViewController, animated: true)
        }
    }
}

// MARK: Theme install
//
private extension AppCoordinator {
    /// Installs themes for newly created store.
    ///
    func installPendingThemeIfNeeded(siteID: Int64) {
        Task {
            do {
                try await themeInstaller.installPendingThemeIfNeeded(siteID: siteID)
            } catch {
                DDLogError("⛔️ AppCoordinator - Error installing pending theme: \(error)")
            }
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
    func displayAuthenticatorWithOnboardingIfNeeded() {
        if canPresentLoginOnboarding() {
            // Sets a placeholder view controller as the window's root view as it is required
            // at the end of app launch.
            setWindowRootViewControllerAndAnimateIfNeeded(.init())
            presentLoginOnboarding { [weak self] in
                guard let self = self else { return }
                // Only displays the authenticator when dismissing onboarding to allow time for A/B test setup.
                self.displayAuthenticator()
            }
        } else {
            displayAuthenticator()
        }
    }

    /// Configures the WPAuthenticator for usage in both logged-in and logged-out states.
    func configureAuthenticator() {
        if isRunningTests {
            /// This is needed to fix crashes in unit tests.
            /// The authenticator is initialized in AppDelegate when running the app.
            authenticationManager.initialize()
        }
        authenticationManager.setLoggedOutAppSettings(loggedOutAppSettings)
        authenticationManager.displayAuthenticatorIfLoggedOut = { [weak self] in
            guard let self, self.isLoggedIn == false else { return nil }
            guard let loginNavigationController = self.window.rootViewController as? LoginNavigationController else {
                return self.displayAuthenticator() as? LoginNavigationController
            }
            return loginNavigationController
        }
        appleIDCredentialChecker.observeLoggedInStateForAppleIDObservations()
    }

    @discardableResult
    func displayAuthenticator() -> UIViewController {
        let authenticationUI = authenticationManager.authenticationUI()
        setWindowRootViewControllerAndAnimateIfNeeded(authenticationUI) { [weak self] _ in
            guard let self = self else { return }
            self.tabBarController.removeViewControllers()
        }
        ServiceLocator.analytics.track(.openedLogin)
        return authenticationUI
    }

    /// Determines whether the login onboarding should be shown.
    func canPresentLoginOnboarding() -> Bool {
        // Since we cannot control the user defaults in the simulator where UI tests are run on,
        // login onboarding is not shown in UI tests for now.
        // If we want to add UI tests for the login onboarding, we can add another launch argument
        // so that we can show/hide the onboarding screen consistently.
        let isUITesting: Bool = CommandLine.arguments.contains("-ui_testing")
        guard isUITesting == false else {
            return false
        }

        return loggedOutAppSettings.hasFinishedOnboarding == false
    }

    /// Presents onboarding on top of the authentication UI under certain criteria.
    /// - Parameter onDismiss: invoked when the onboarding is dismissed.
    func presentLoginOnboarding(onDismiss: @escaping () -> Void) {
        let onboardingViewController = LoginOnboardingViewController { [weak self] action in
            guard let self = self else { return }
            onDismiss()
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
        presentLocalOperatorFlowIfNeeded()
    }

    /// If the app is authenticated but there is no default store ID on launch,
    /// check for errors and display store picker if none exists.
    ///
    func displayLoggedInStateWithoutDefaultStore() {
        // Store picker is only displayed by `AppCoordinator` on launch, when the window's root is uninitialized.
        // In other cases when the app is authenticated but there is no default store ID, the store picker is shown by authentication UI.
        guard window.rootViewController == nil else {
            return
        }

        /// If authenticating with site credentials only is incomplete,
        /// show the prologue screen to force the user to log in again.
        guard stores.isAuthenticatedWithoutWPCom == false else {
            return displayAuthenticatorWithOnboardingIfNeeded()
        }

        let matcher = ULAccountMatcher(storageManager: storageManager)
        matcher.refreshStoredSites()

        // Show error for the current site URL if exists.
        if let siteURL = loggedOutAppSettings.errorLoginSiteAddress {
            if let authenticationUI = authenticationManager.authenticationUI() as? UINavigationController,
               let errorController = authenticationManager.errorViewController(for: siteURL,
                                                                               with: matcher,
                                                                               credentials: nil,
                                                                               navigationController: authenticationUI,
                                                                               onStorePickerDismiss: {}) {
                window.rootViewController = authenticationUI
                // don't let user navigate back to the login screen unless they tap log out.
                errorController.navigationItem.hidesBackButton = true
                authenticationUI.show(errorController, sender: nil)
                return
            }
        }

        // All good, show store picker
        let navigationController = WooNavigationController()
        setWindowRootViewControllerAndAnimateIfNeeded(navigationController)
        DDLogInfo("💬 Authenticated user does not have a Woo store selected — launching store picker.")
        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .standard)
        storePickerCoordinator?.start()
        storePickerCoordinator?.onDismiss = { [weak self] in
            guard let self = self else { return }
            if self.isLoggedIn == false {
                self.displayAuthenticatorWithOnboardingIfNeeded()
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
        ServiceLocator.analytics.track(event: .Login.insufficientRole(currentRoles: errorInfo.roles))
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
}

private extension AppCoordinator {
    func presentLocalOperatorFlowIfNeeded() {
        guard localOperatorSessionController.isDeviceStaffModeEnabled,
              localOperatorSessionController.isLocked else {
            return
        }

        let presenter = window.topmostPresentedViewController ?? window.rootViewController
        guard (presenter is LocalOperatorHostingController) == false else {
            return
        }

        presenter?.present(LocalOperatorHostingController(sessionController: localOperatorSessionController), animated: false)
    }

    func dismissLocalOperatorFlowIfNeeded() {
        let presenter = window.topmostPresentedViewController ?? window.rootViewController
        if presenter is LocalOperatorHostingController {
            presenter?.dismiss(animated: false)
        }
    }

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
    func triggerAgeVerification(onAllowed: @escaping () -> Void = { }) {
        ageRangeVerificationCoordinator.triggerAgeVerificationIfNeeded(
            hostingWindow: window
        ) { [weak self] appAccessDescision, _ in
            guard let self else { return }
            if appAccessDescision == .allow {
                onAllowed()
            } else {
                self.forceLogoutAndShowAgeAlert()
            }

            //TODO: consider adding analytics event with the result
        }
    }

    /// Centralized flow to log out and present the login/onboarding UI.
    func forceLogoutAndReturnToLogin() {
        stores.deauthenticate()
        displayAuthenticatorWithOnboardingIfNeeded()
    }

    func forceLogoutAndShowAgeAlert() {
        forceLogoutAndReturnToLogin()

        DispatchQueue.main.async { [weak self] in
            guard
                let self,
                let presenter = self.window.topmostPresentedViewController
            else { return }
            let alert = UIAlertController(
                title: Localization.AgeVerificationAlert.title,
                message: String(
                    format: Localization.AgeVerificationAlert.message,
                    AgeRangeVerificationCoordinator.Constants.minimumTOSRequiredAge
                ),
                preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(
                    title: Localization.AgeVerificationAlert.confirmationButton,
                    style: .default,
                    handler: nil
                )
            )
            presenter.present(alert, animated: true)
        }
    }
}

private extension AppCoordinator {
    enum Constants {
        static let animationDuration = TimeInterval(0.3)
    }

    enum Localization {
        enum AgeVerificationAlert {
            static let title = NSLocalizedString(
                "appCoordinator.ineligibleAgeRangeAlert.title",
                value: "Access Restricted",
                comment: "Alert title displayed when user identified as underage and taken to force logout."
            )

            static let message = NSLocalizedString(
                "appCoordinator.ineligibleAgeRangeAlert.message",
                value: "Your Apple account age is below the minimum required for this app (%1d+).",
                comment: "Alert message displayed when user identified as underage and taken to force logout." +
                "The %1d placeholder is the minimum required age."
            )

            static let confirmationButton = NSLocalizedString(
                "appCoordinator.ineligibleAgeRangeAlert.confirmationButton",
                value: "Got it",
                comment: "Alert confirmation button displayed when user identified as underage and taken to force logout."
            )
        }

        enum StoreReadyAlert {
            static let title = NSLocalizedString("appCoordinator.storeReadyAlert.title",
                                                 value: "Your new store is ready.",
                                                 comment: "Title of the alert to ask confirmation to switch to the newly created store.")
            static let message = NSLocalizedString("appCoordinator.storeReadyAlert.message",
                                                   value: "Do you want to start managing it now?",
                                                   comment: "Message of the alert to ask confirmation to switch to the newly created store.")
            static let switchStoreButton = NSLocalizedString("appCoordinator.storeReadyAlert.switchStoreButton",
                                                             value: "Switch Store",
                                                             comment: "Button to switch to the new store.")
            static let cancelButton = NSLocalizedString("appCoordinator.storeReadyAlert.cancelButton",
                                                        value: "Cancel",
                                                        comment: "Button to dismiss the alert asking for confirmation to switch store.")
        }
    }
}
