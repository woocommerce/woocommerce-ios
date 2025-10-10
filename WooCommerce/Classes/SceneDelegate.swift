import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private(set) var appCoordinator: AppCoordinator?
    var universalLinkRouter: UniversalLinkRouter?

    var tabBarController: MainTabBarController? { appCoordinator?.tabBarController }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.makeKeyAndVisible()
        self.window = window

        let coordinator = AppCoordinator(window: window)
        self.appCoordinator = coordinator
        coordinator.start()

        // Scene-scoped initializations that need UI
        setupNoticePresenter()
        setupUniversalLinkRouter()

        // Cold-start deep links / activities
        if let urlContext = connectionOptions.urlContexts.first {
            self.scene(scene, openURLContexts: [urlContext])
        }
        if let activity = connectionOptions.userActivities.first {
            self.scene(scene, continue: activity)
        }

        // Update AppDelegate-scoped dependencies that rely on a base VC
        AppDelegate.shared.requirementsChecker.baseViewController = tabBarController
    }

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {
        AppDelegate.shared.refreshCardPresentPaymentsOnboardingIfNeeded()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        AppDelegate.shared.appRefreshHandler.scheduleAppRefresh()
    }

    // MARK: - URL / Activity Handling
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        if let universalLinkRouter, universalLinkRouter.canHandle(url: url) {
            universalLinkRouter.handle(url: url)
            return
        }
        if let rootVC = window?.rootViewController {
            _ = AppDelegate.shared.handleAuthenticationUrl(url, options: [:], rootViewController: rootVC)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleWebActivity(userActivity)
    }

    // MARK: - Scene-scoped helpers moved from AppDelegate
    private func setupNoticePresenter() {
        var noticePresenter = ServiceLocator.noticePresenter
        noticePresenter.presentingViewController = tabBarController
    }

    private func setupUniversalLinkRouter() {
        guard let tabBarController = tabBarController else { return }
        universalLinkRouter = UniversalLinkRouter.defaultUniversalLinkRouter(tabBarController: tabBarController)
    }

    func handleWebActivity(_ activity: NSUserActivity) {
        guard let linkURL = activity.webpageURL else { return }
        universalLinkRouter?.handle(url: linkURL)
    }
}
