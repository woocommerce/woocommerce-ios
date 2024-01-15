import UIKit

/// Coordinates navigation into the entry of the Blaze creation flow.
final class BlazeCampaignCreationCoordinator: Coordinator {
    enum CreateCampaignDestination: Equatable {
        case productSelector
        case campaignForm(productID: Int64)
        case webViewForm(productID: Int64?)
        case noProductAvailable
    }
    private lazy var blazeNavigationController = WooNavigationController()

    let siteID: Int64
    let siteURL: String
    let source: BlazeSource
    let destination: CreateCampaignDestination
    var navigationController: UINavigationController
    let didSelectCreateCampaign: ((BlazeSource) -> Void)?
    let onCampaignCreated: () -> Void

    init(siteID: Int64,
         siteURL: String,
         source: BlazeSource,
         destination: CreateCampaignDestination,
         navigationController: UINavigationController,
         didSelectCreateCampaign: ((BlazeSource) -> Void)? = nil,
         onCampaignCreated: @escaping () -> Void) {
        self.siteID = siteID
        self.siteURL = siteURL
        self.source = source
        self.destination = destination
        self.navigationController = navigationController
        self.didSelectCreateCampaign = didSelectCreateCampaign
        self.onCampaignCreated = onCampaignCreated
    }

    func start() {
        navigateToCampaignCreation(destination: destination)
    }

    func navigateToCampaignCreation(destination: CreateCampaignDestination) {
        switch destination {
        case .productSelector:
            navigateToBlazeProductSelector(source: source)
        case .campaignForm(let productID):
            navigateToNativeCampaignCreation(source: source, productID: productID)
        case .webViewForm(let productID):
            navigateToWebCampaignCreation(source: source, productID: productID)
        case .noProductAvailable:
            break // TODO 11685: add error alert.
        }
    }

    /// Handles navigation to the native Blaze creation
    func navigateToNativeCampaignCreation(source: BlazeSource, productID: Int64) {
        let controller = BlazeCampaignCreationFormHostingController(
            viewModel: .init(siteID: self.siteID,
                             productID: productID,
                             onCompletion: self.onCampaignCreated
                 )
        )

        // This function can be called from navigateToBlazeProductSelector(), in which case we need to show the
        // Campaign Creation Form from blazeNavigationController.
        // Otherwise, we show it from the current navigation controller.
        if self.blazeNavigationController.presentingViewController != nil {
            self.blazeNavigationController.show(controller, sender: self)
        } else {
            self.navigationController.show(controller, sender: self)
        }
    }

    /// Handles navigation to the webview Blaze creation
    func navigateToWebCampaignCreation(source: BlazeSource, productID: Int64? = nil) {
        let webViewModel = BlazeWebViewModel(siteID: siteID,
                                             source: source,
                                             siteURL: siteURL,
                                             productID: productID) { [weak self] in
            guard let self else { return }
            self.onCampaignCreated()
        }
        let webViewController = AuthenticatedWebViewController(viewModel: webViewModel)
        navigationController.show(webViewController, sender: self)
        didSelectCreateCampaign?(source)
    }

    /// Handles navigation to the Blaze product selector view
    func navigateToBlazeProductSelector(source: BlazeSource) {
        // View controller for product selector before going to campaign creation form.
        var productSelectorViewController: ProductSelectorViewController {
            let productSelectorViewModel = ProductSelectorViewModel(
                siteID: siteID,
                onProductSelectionStateChanged: { [weak self] product in
                    guard let self = self else { return }

                    // Navigate to Campaign Creation Form once any type of product is selected.
                    navigateToNativeCampaignCreation(source: source, productID: product.productID)
                },
                onCloseButtonTapped: { [weak self] in
                    guard let self = self else { return }

                    navigationController.dismiss(animated: true, completion: nil)
                }
            )
            return ProductSelectorViewController(configuration: ProductSelectorView.Configuration.configurationForBlaze,
                                                 source: .blaze,
                                                 viewModel: productSelectorViewModel)
        }

        blazeNavigationController.viewControllers = [productSelectorViewController]
        self.navigationController.present(blazeNavigationController, animated: true, completion: nil)
    }
}
