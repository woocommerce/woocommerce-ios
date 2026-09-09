import Combine
import SwiftUI
import UIKit

/// Presents the HTTPS configuration warning above the content of UIKit-backed tabs.
@MainActor
final class HTTPSConfigurationWarningPresenter {
    private final class Presentation {
        let view: UIView
        weak var hostViewController: UIViewController?
        weak var navigationBar: UINavigationBar?
        var originalTopSafeAreaInset: CGFloat?
        var constraints: [NSLayoutConstraint] = []

        init(view: UIView) {
            self.view = view
        }
    }

    private struct Host {
        let viewController: UIViewController
        let containerView: UIView
        let navigationBar: UINavigationBar?
    }

    private let viewModel: HTTPSConfigurationWarningViewModel
    private weak var presentingViewController: UIViewController?
    private let tabViewController: (WooTab) -> UIViewController?
    private let visibleTabs: () -> [WooTab]
    private let selectedTab: () -> WooTab?
    private let onAction: () -> Void

    private var presentations: [WooTab: Presentation] = [:]
    private var visibilitySubscription: AnyCancellable?
    private var navigationSubscription: AnyCancellable?

    init(viewModel: HTTPSConfigurationWarningViewModel,
         presentingViewController: UIViewController,
         tabViewController: @escaping (WooTab) -> UIViewController?,
         visibleTabs: @escaping () -> [WooTab],
         selectedTab: @escaping () -> WooTab?,
         onAction: @escaping () -> Void) {
        self.viewModel = viewModel
        self.presentingViewController = presentingViewController
        self.tabViewController = tabViewController
        self.visibleTabs = visibleTabs
        self.selectedTab = selectedTab
        self.onAction = onAction
    }

    func start() {
        visibilitySubscription = viewModel.$isVisible
            .removeDuplicates()
            .sink { [weak self] isVisible in
                isVisible ? self?.show() : self?.hide()
            }

        navigationSubscription = NotificationCenter.default
            .publisher(for: .wooNavigationControllerDidShowViewController)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.update()
                }
            }
    }

    func selectedTabDidChange(to tab: WooTab) {
        update(for: tab)
        DispatchQueue.main.async { [weak self] in
            self?.update(for: tab)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.splitViewRetryDelay) { [weak self] in
            self?.update(for: tab)
        }
    }

    func updateAll() {
        guard viewModel.isVisible else {
            return
        }
        visibleTabs()
            .filter { $0 != .pointOfSale && $0 != .hubMenu }
            .forEach { update(for: $0) }
    }

    func update(for tab: WooTab? = nil) {
        guard viewModel.isVisible,
              let tab = tab ?? selectedTab(),
              tab != .pointOfSale,
              tab != .hubMenu,
              let host = host(for: tab),
              host.containerView.bounds.width > 0 else {
            return
        }
        let presentation = presentation(for: tab)
        let banner = presentation.view

        if needsReattachment(presentation, banner: banner, to: host) {
            reattach(presentation, banner: banner, to: host)
        }

        let originalTopInset = presentation.originalTopSafeAreaInset ?? 0
        let height = banner.systemLayoutSizeFitting(
            CGSize(width: host.containerView.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        if host.viewController.additionalSafeAreaInsets.top != originalTopInset + height {
            host.viewController.additionalSafeAreaInsets.top = originalTopInset + height
        }
        banner.superview?.bringSubviewToFront(banner)
    }
}

private extension HTTPSConfigurationWarningPresenter {
    private func show() {
        updateAll()
        DispatchQueue.main.async { [weak self] in
            self?.update()
        }
        presentingViewController?.setNeedsStatusBarAppearanceUpdate()
    }

    private func hide() {
        for presentation in presentations.values {
            restoreHostSafeArea(for: presentation)
            NSLayoutConstraint.deactivate(presentation.constraints)
            presentation.view.removeFromSuperview()
        }
        presentations = [:]
    }

    private func presentation(for tab: WooTab) -> Presentation {
        if let presentation = presentations[tab] {
            return presentation
        }
        let banner = HTTPSConfigurationWarningBanner(onAction: onAction,
                                                      onDismiss: { [weak viewModel] in
                                                          viewModel?.dismiss()
                                                      })
        let contentView = UIHostingConfiguration {
            banner
        }
        .margins(.all, 0)
        .makeContentView()
        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let presentation = Presentation(view: contentView)
        presentations[tab] = presentation
        return presentation
    }

    private func needsReattachment(_ presentation: Presentation, banner: UIView, to host: Host) -> Bool {
        presentation.hostViewController !== host.viewController ||
            presentation.navigationBar !== host.navigationBar ||
            banner.superview !== host.containerView
    }

    private func reattach(_ presentation: Presentation, banner: UIView, to host: Host) {
        restoreHostSafeArea(for: presentation)
        NSLayoutConstraint.deactivate(presentation.constraints)
        banner.removeFromSuperview()

        host.viewController.loadViewIfNeeded()
        presentation.hostViewController = host.viewController
        presentation.originalTopSafeAreaInset = host.viewController.additionalSafeAreaInsets.top
        presentation.navigationBar = host.navigationBar

        host.containerView.addSubview(banner)
        presentation.constraints = makeConstraints(for: banner, in: host)
        NSLayoutConstraint.activate(presentation.constraints)
    }

    private func makeConstraints(for banner: UIView, in host: Host) -> [NSLayoutConstraint] {
        [
            banner.leadingAnchor.constraint(equalTo: host.containerView.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: host.containerView.trailingAnchor),
            makeTopConstraint(for: banner, in: host)
        ]
    }

    private func makeTopConstraint(for banner: UIView, in host: Host) -> NSLayoutConstraint {
        if let navigationBar = host.navigationBar {
            return banner.topAnchor.constraint(equalTo: navigationBar.bottomAnchor)
        }

        return banner.topAnchor.constraint(equalTo: host.containerView.topAnchor,
                                           constant: safeAreaTop(in: host.containerView))
    }

    private func safeAreaTop(in containerView: UIView) -> CGFloat {
        guard let window = containerView.window else {
            return containerView.safeAreaInsets.top
        }

        return containerView.convert(CGPoint(x: 0, y: window.safeAreaInsets.top), from: window).y
    }

    private func host(for tab: WooTab) -> Host? {
        guard let tabViewController = tabViewController(tab) else {
            return nil
        }
        let rootViewController: UIViewController
        if let container = tabViewController as? TabContainerController {
            guard let wrappedController = container.wrappedController else {
                return nil
            }
            rootViewController = wrappedController
        } else {
            rootViewController = tabViewController
        }
        guard rootViewController.isViewLoaded,
              let rootView = rootViewController.view else {
            return nil
        }

        if tab == .orders || tab == .products,
           let splitViewController = firstSplitViewController(in: rootViewController) {
            let column: UISplitViewController.Column = splitViewController.isCollapsed ? .primary : .secondary
            guard let navigationController = splitViewController.viewController(for: column) as? UINavigationController else {
                return nil
            }
            return host(for: navigationController)
        }

        if let navigationController = firstNavigationController(in: rootViewController, attachedTo: rootView),
           let host = host(for: navigationController) {
            return host
        }
        return Host(viewController: rootViewController,
                    containerView: rootView,
                    navigationBar: nil)
    }

    private func host(for navigationController: UINavigationController) -> Host? {
        guard navigationController.isViewLoaded,
              let contentViewController = navigationController.topViewController else {
            return nil
        }
        let navigationBar = navigationController.isNavigationBarHidden ? nil : navigationController.navigationBar
        guard navigationBar?.isDescendant(of: navigationController.view) != false else {
            return nil
        }
        return Host(viewController: contentViewController,
                    containerView: navigationController.view,
                    navigationBar: navigationBar)
    }

    private func firstSplitViewController(in viewController: UIViewController) -> UISplitViewController? {
        if let splitViewController = viewController as? UISplitViewController {
            return splitViewController
        }
        for child in viewController.children {
            if let splitViewController = firstSplitViewController(in: child) {
                return splitViewController
            }
        }
        return nil
    }

    private func firstNavigationController(in viewController: UIViewController, attachedTo containerView: UIView) -> UINavigationController? {
        if let navigationController = viewController as? UINavigationController,
           navigationController.isViewLoaded {
            let navigationViewIsAttached = navigationController.view === containerView ||
                navigationController.view.isDescendant(of: containerView)
            if navigationViewIsAttached,
               navigationController.navigationBar.isDescendant(of: containerView) {
                return navigationController
            }
        }
        for child in viewController.children {
            if let navigationController = firstNavigationController(in: child, attachedTo: containerView) {
                return navigationController
            }
        }
        return nil
    }

    private func restoreHostSafeArea(for presentation: Presentation) {
        if let hostViewController = presentation.hostViewController,
           let originalTopInset = presentation.originalTopSafeAreaInset {
            hostViewController.additionalSafeAreaInsets.top = originalTopInset
        }
        presentation.hostViewController = nil
        presentation.originalTopSafeAreaInset = nil
        presentation.navigationBar = nil
    }

    private enum Constants {
        static let splitViewRetryDelay = 0.2
    }
}
