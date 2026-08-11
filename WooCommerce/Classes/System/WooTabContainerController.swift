import UIKit

enum NarrowWindowLayout {
    static let compactLayoutThreshold: CGFloat = 700
}

protocol UsesCompactLayoutInNarrowWindow: AnyObject {}

/// Adopted by tab root content controllers that need custom handling when their tab is re-selected.
protocol TabReselectionHandling {
    func handleTabReselection()
}

/// Container for a Woo tab, shown as the root view controller of one of the tabs.
/// Provided as an alternative to `WooTabNavigationController`, for root controllers which should not be in a nav view
/// For example, a Split View, which will not work correctly on iPhone when wrapped in a navigation view.
/// This wraps a controller which can be replaced when the selected site changes.
final class TabContainerController: UIViewController {
    private var appliedWrappedControllerHorizontalSizeClass: UIUserInterfaceSizeClass?

    var wrappedController: UIViewController? {
        willSet {
            appliedWrappedControllerHorizontalSizeClass = nil
            wrappedController?.willMove(toParent: nil)
            wrappedController?.view.removeFromSuperview()
            wrappedController?.removeFromParent()
        }

        didSet {
            guard let newWrappedController = wrappedController else {
                return
            }

            addChild(newWrappedController)
            view.addSubview(newWrappedController.view)
            newWrappedController.didMove(toParent: self)

            applyHorizontalSizeClassToWrappedController()

            newWrappedController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                newWrappedController.view.topAnchor.constraint(equalTo: view.topAnchor),
                newWrappedController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                newWrappedController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                newWrappedController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            tabBarItem = newWrappedController.tabBarItem
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        observeTraitChanges()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        applyHorizontalSizeClassToWrappedController()
    }
}

private extension TabContainerController {
    func observeTraitChanges() {
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: Self, _) in
                self.applyHorizontalSizeClassToWrappedController()
            }
        }
    }

    func applyHorizontalSizeClassToWrappedController() {
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            guard let wrappedController else {
                return
            }

            // Liquid Glass uses the real iPad size class for native tabs. Wrapped split-view roots still need
            // a compact layout in narrow Stage Manager windows, so forward that effective size class to them.
            let effectiveHorizontalSizeClass = effectiveHorizontalSizeClassForWrappedController()
            guard appliedWrappedControllerHorizontalSizeClass != effectiveHorizontalSizeClass else {
                return
            }

            wrappedController.traitOverrides.horizontalSizeClass = effectiveHorizontalSizeClass
            appliedWrappedControllerHorizontalSizeClass = effectiveHorizontalSizeClass
        }
    }

    func effectiveHorizontalSizeClassForWrappedController() -> UIUserInterfaceSizeClass {
        guard #available(iOS 26.0, *),
              wrappedController is UsesCompactLayoutInNarrowWindow,
              view.bounds.width < NarrowWindowLayout.compactLayoutThreshold else {
            return traitCollection.horizontalSizeClass
        }

        return .compact
    }
}
