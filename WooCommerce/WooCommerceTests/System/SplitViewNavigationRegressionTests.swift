import Testing
import UIKit
import Yosemite
import YosemiteTestHelpers

@testable import WooCommerce

// Exercise real UIKit trait transitions with the production stack helper and product screens.
@MainActor
@Suite(.serialized, .timeLimit(.minutes(5)))
struct SplitViewNavigationRegressionTests {
    @Test
    func test_discard_when_product_form_is_in_compact_layout_then_returns_to_primary_root() async throws {
        // Given
        let sessionID = "splitNavigationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: sessionID))
        defer { defaults.removePersistentDomain(forName: sessionID) }
        let session = SessionManager(defaults: defaults, keychainServiceName: sessionID)
        let stores = MockStoresManager(sessionManager: session)
        let product = makeProduct(stores: stores)
        let rig = ProductNavigationRig(form: product.form)
        let host = try HostedNavigation(content: rig.split)
        defer { host.close() }
        try await host.layout(.regular)
        try await host.layout(.compact)
        rig.showProduct(product.form)
        await host.settle()
        try #require(rig.primary.topViewController === product.form)
        try #require(product.form.view.window != nil)
        product.viewModel.updateName("Unsaved product")
        try #require(product.viewModel.hasUnsavedChanges())
        var completionCalled = false

        // When: call the actual form entry and invoke its actual destructive action.
        product.form.close(completion: { completionCalled = true })
        let alert = try #require(product.form.presentedViewController as? UIAlertController)
        await host.settle(extra: alert)
        let discardIndex = try #require(alert.actions.firstIndex(where: { $0.style == .destructive }))
        // Existing tapButton calls only the handler. Dismiss through UIKit first to avoid a fake
        // still-presented alert changing the navigation result. This is not a physical UI tap test.
        await withCheckedContinuation { continuation in
            alert.dismiss(animated: false) { continuation.resume() }
        }
        alert.tapButton(atIndex: discardIndex)
        await host.settle()

        // Then: do not claim all edits were reset; Discard must complete and navigate Back.
        #expect(completionCalled)
        #expect(rig.primary.topViewController === rig.list)
        #expect(product.form.navigationController == nil)
    }

    @Test
    func test_round_trip_when_product_inventory_is_open_then_preserves_both_controllers() async throws {
        // Given: real form and inventory screens, selected after compact entry.
        let sessionID = "splitNavigationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: sessionID))
        defer { defaults.removePersistentDomain(forName: sessionID) }
        let session = SessionManager(defaults: defaults, keychainServiceName: sessionID)
        let stores = MockStoresManager(sessionManager: session)
        let product = makeProduct(stores: stores)
        let rig = ProductNavigationRig(form: product.form)
        let host = try HostedNavigation(content: rig.split)
        defer { host.close() }
        try await host.layout(.regular)
        try await host.layout(.compact)
        rig.showProduct(product.form)
        await host.settle()
        let inventory = ProductInventorySettingsViewController(product: product.viewModel.productModel) { _ in }
        rig.primary.pushViewController(inventory, animated: true)
        await host.settle()
        try #require(rig.primary.viewControllers == [rig.list, product.form, inventory])
        try #require(inventory.view.window != nil)

        product.viewModel.updateName("Unsaved product")

        // When: UIKit invokes the actual split delegate repeatedly in both directions.
        for _ in 0..<3 {
            try await host.layout(.regular)
            try #require(rig.secondary.viewControllers == [product.form, inventory])
            try await host.layout(.compact)
        }

        // Then: changing presentation must retain the open screens and their state owners.
        #expect(rig.primary.viewControllers == [rig.list, product.form, inventory])
        #expect(product.form.navigationController === rig.primary)
        #expect(inventory.navigationController === rig.primary)
        #expect(product.viewModel.productModel.name == "Unsaved product")
        #expect(product.viewModel.hasUnsavedChanges())
    }
}

@MainActor
private func makeProduct(stores: MockStoresManager) -> (form: ProductFormViewController<ProductFormViewModel>,
                                                     viewModel: ProductFormViewModel,
                                                     uploader: MockProductImageUploader) {
    let product = Product.fake().copy(siteID: -3932, productID: 123, name: "Saved product")
    stores.whenReceivingAction(ofType: ProductAction.self) { action in
        if case let .retrieveProduct(_, _, completion) = action {
            completion(.success(product))
        }
    }
    let uploader = MockProductImageUploader()
    let storage = MockStorageManager()
    let imageHandler = ProductImageActionHandler(siteID: product.siteID,
                                                 productID: .product(id: product.productID),
                                                 imageStatuses: product.imageStatuses,
                                                 stores: stores)
    let viewModel = ProductFormViewModel(product: EditableProductModel(product: product),
                                         formType: .edit,
                                         productImageActionHandler: imageHandler,
                                         stores: stores,
                                         storageManager: storage,
                                         productImagesUploader: uploader,
                                         analytics: WooAnalytics(analyticsProvider: MockAnalyticsProvider()),
                                         blazeEligibilityChecker: MockBlazeEligibilityChecker(),
                                         favoriteProductsUseCase: MockFavoriteProductsUseCase())
    let form = ProductFormViewController(viewModel: viewModel,
                                         eventLogger: ProductFormEventLogger(),
                                         productImageActionHandler: imageHandler,
                                         currency: "$",
                                         storageManager: storage,
                                         presentationStyle: .navigationStack,
                                         productImageUploader: uploader,
                                         onDuplicateCompletion: { _, _ in })
    return (form, viewModel, uploader)
}

@MainActor
private final class ProductNavigationRig {
    let primary = WooTabNavigationController()
    let secondary = WooNavigationController()
    let list = UIViewController()
    private lazy var stack: SplitViewNavigationStack = .init(splitViewController: split,
                                                       primaryNavigationController: primary,
                                                       secondaryNavigationController: secondary)
    lazy var split: WooSplitViewController = .init(columnForCollapsingHandler: { [weak self] _ in
        self?.stack.prepareForCollapsing(showsSecondaryContent: true)
        return .primary
    }, didCollapseHandler: { [weak self] _ in
        self?.stack.didCollapse()
    }, didExpandHandler: { [weak self] _ in
        self?.stack.didExpand()
    })

    func showProduct(_ form: UIViewController) {
        stack.setContentViewControllers([form], showsInCollapsedLayout: true)
    }

    init(form: UIViewController) {
        list.title = "Products"
        primary.setViewControllers([list], animated: false)
        secondary.setViewControllers([form], animated: false)
        split.setViewController(primary, for: .primary)
        split.setViewController(secondary, for: .secondary)
    }
}

@MainActor
private final class HostedNavigation {
    let root = UIViewController()
    let content: UIViewController
    let split: WooSplitViewController
    let window: UIWindow
    private weak var previousKeyWindow: UIWindow?

    init(content: UIViewController) throws {
        self.content = content
        content.loadViewIfNeeded()
        split = try #require(firstDescendant(of: WooSplitViewController.self, in: content))
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
            window = UIWindow(windowScene: scene)
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }
        root.addChild(content)
        try overrideHorizontalSizeClass(.regular)
        root.view.addSubview(content.view)
        content.view.frame = root.view.bounds
        content.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        content.didMove(toParent: root)
        window.rootViewController = root
        window.makeKeyAndVisible()
    }

    func layout(_ sizeClass: UIUserInterfaceSizeClass) async throws {
        try overrideHorizontalSizeClass(sizeClass)
        root.view.setNeedsLayout()
        root.view.layoutIfNeeded()
        await settle()
        try #require(split.view.window === window)
        try #require(split.isCollapsed == (sizeClass == .compact), "UIKit must perform the requested real transition")
    }

    func settle(extra: UIViewController? = nil) async {
        if let coordinator = extra?.transitionCoordinator ?? split.transitionCoordinator ??
            (split.viewController(for: .primary) as? UINavigationController)?.transitionCoordinator ??
            (split.viewController(for: .secondary) as? UINavigationController)?.transitionCoordinator {
            await withCheckedContinuation { continuation in
                let accepted = coordinator.animate(alongsideTransition: nil) { _ in continuation.resume() }
                if !accepted { continuation.resume() }
            }
        }
        // Deliver already queued UIKit/layout work once. This is not a sleep or condition-polling loop.
        await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
        root.view.layoutIfNeeded()
    }

    func close() {
        window.isHidden = true
        window.rootViewController = nil
        previousKeyWindow?.makeKey()
    }

    private func overrideHorizontalSizeClass(_ sizeClass: UIUserInterfaceSizeClass) throws {
        guard #available(iOS 17.0, *) else {
            throw CocoaError(.featureUnsupported)
        }
        content.traitOverrides.horizontalSizeClass = sizeClass
    }
}

@MainActor
private func firstDescendant<T: UIViewController>(of type: T.Type, in root: UIViewController) -> T? {
    if let match = root as? T { return match }
    for child in root.children {
        if let match = firstDescendant(of: type, in: child) { return match }
    }
    return nil
}
