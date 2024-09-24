import UIKit
import Combine
import Yosemite

protocol MainTabBarControllerProtocol: UIViewController, UIViewControllerTransitioningDelegate, DeepLinkNavigator {
    // Properties
    var childForStatusBarStyle: UIViewController? { get }
    var preferredStatusBarStyle: UIStatusBarStyle { get }

    // Methods
    func navigateTo(_ tab: WooTab, animated: Bool, completion: (() -> Void)?)
    func navigateToTabWithViewController(_ tab: WooTab, animated: Bool, completion: ((UIViewController) -> Void)?)
    func removeViewControllers()
    func presentCollectPayment()

    func switchToMyStoreTab(animated: Bool)
    func switchToOrdersTab(completion: (() -> Void)?)
    func switchToProductsTab(completion: (() -> Void)?)
    func switchToHubMenuTab(completion: ((HubMenuViewController?) -> Void)?)
    func presentNotificationDetails(for noteID: Int64)
    func switchStoreIfNeededAndPresentNotificationDetails(notification: WooCommerce.PushNotification)
    func presentAddProductFlow()
    func navigateToOrderDetails(with orderID: Int64, siteID: Int64)
    func navigateToBlazeCampaignDetails(using note: Note)
    func navigateToBlazeCampaignCreation(for siteID: Int64)
    func presentOrderCreationFlow(for customerID: Int64, billing: Address?, shipping: Address?)
    func presentPayments()
    func presentCoupons()
    func navigateToPrivacySettings()

    // Protocol Methods
    func navigate(to destination: any DeepLinkDestinationProtocol)
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController?
}
