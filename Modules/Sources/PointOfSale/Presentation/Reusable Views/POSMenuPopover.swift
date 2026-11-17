import SwiftUI
import UIKit

/// Uses a custom UIKit presentation because the system popover and menu add their own material and shadow.
struct POSMenuPopover<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var pointer: POSMenuPointer
    @Environment(\.posMetrics) private var metrics
    @ViewBuilder let content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, pointer: $pointer, metrics: metrics)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        context.coordinator.update(anchor: controller, content: content, isPresented: $isPresented, pointer: $pointer, metrics: metrics)
    }

    static func dismantleUIViewController(_ controller: UIViewController, coordinator: Coordinator) {
        coordinator.dismiss(animated: false)
    }

    @MainActor
    final class Coordinator: NSObject, UIViewControllerTransitioningDelegate {
        private var isPresented: Binding<Bool>
        private var pointer: Binding<POSMenuPointer>
        private var metrics: POSMetrics
        private var hostingController: POSMenuHostingController<Content>?
        private weak var anchor: UIViewController?

        init(isPresented: Binding<Bool>, pointer: Binding<POSMenuPointer>, metrics: POSMetrics) {
            self.isPresented = isPresented
            self.pointer = pointer
            self.metrics = metrics
        }

        func update(anchor: UIViewController, content: () -> Content, isPresented: Binding<Bool>, pointer: Binding<POSMenuPointer>, metrics: POSMetrics) {
            self.isPresented = isPresented
            self.pointer = pointer
            self.metrics = metrics
            self.anchor = anchor
            guard isPresented.wrappedValue else {
                dismiss(animated: true)
                return
            }
            if let hostingController {
                hostingController.rootView = content()
                (hostingController.presentationController as? POSMenuPresentationController)?.metrics = metrics
                hostingController.presentationController?.containerView?.setNeedsLayout()
                return
            }
            guard let window = anchor.view.window else {
                Task { @MainActor [weak self] in
                    guard let self, self.anchor?.view.window == nil else { return }
                    self.isPresented.wrappedValue = false
                }
                return
            }
            let host = POSMenuHostingController(rootView: content())
            host.modalPresentationStyle = .custom
            host.modalTransitionStyle = .crossDissolve
            host.transitioningDelegate = self
            host.sizingOptions = .preferredContentSize
            // The presentation controller already applies the window's safe area, including space for the shadow.
            host.safeAreaRegions = []
            host.view.backgroundColor = .clear
            host.view.clipsToBounds = false
            host.preferredContentSize = host.sizeThatFits(in: window.bounds.size)
            host.closeMenu = { [weak self] in
                self?.isPresented.wrappedValue = false
            }
            hostingController = host
            anchor.present(host, animated: true)
        }

        func dismiss(animated: Bool) {
            guard let hostingController, !hostingController.isBeingDismissed else { return }
            hostingController.dismiss(animated: animated) { [weak self] in
                self?.hostingController = nil
                self?.isPresented.wrappedValue = false
            }
        }

        func presentationController(forPresented presented: UIViewController,
                                    presenting: UIViewController?,
                                    source: UIViewController) -> UIPresentationController? {
            POSMenuPresentationController(presentedViewController: presented,
                                          presenting: presenting,
                                          sourceView: anchor?.view,
                                          metrics: metrics,
                                          updatePointer: { [weak self] pointer in
                Task { @MainActor [weak self] in
                    guard let self, self.isPresented.wrappedValue, self.pointer.wrappedValue != pointer else {
                        return
                    }
                    self.pointer.wrappedValue = pointer
                }
            }, closeMenu: { [weak self] in
                self?.isPresented.wrappedValue = false
            })
        }
    }
}

private final class POSMenuHostingController<Content: View>: UIHostingController<Content> {
    var closeMenu: (() -> Void)?

    override var keyCommands: [UIKeyCommand]? {
        [UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(close))]
    }

    override func accessibilityPerformEscape() -> Bool {
        closeMenu?()
        return true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.accessibilityViewIsModal = true
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }

    @objc private func close() {
        closeMenu?()
    }
}

struct POSMenuLayout: Equatable {
    let frame: CGRect
    let pointer: POSMenuPointer

    /// `preferredSize` and `frame` include the shadow margin around the menu card. `safeBounds` limits the card.
    init(source: CGRect, safeBounds: CGRect, preferredSize: CGSize, isRightToLeft: Bool, metrics: POSMetrics) {
        let shadowMargin = metrics.padding.xxLarge
        let gap = metrics.spacing.small
        let frameBounds = safeBounds.insetBy(dx: -shadowMargin, dy: -shadowMargin)

        let cardHeight = max(0, preferredSize.height - shadowMargin * 2)
        let spaceBelow = max(0, safeBounds.maxY - source.maxY - gap)
        let spaceAbove = max(0, source.minY - safeBounds.minY - gap)
        let showsBelow = spaceBelow >= cardHeight || spaceBelow >= spaceAbove

        let width = min(preferredSize.width, frameBounds.width)
        let height = min(cardHeight, showsBelow ? spaceBelow : spaceAbove) + shadowMargin * 2
        let x = isRightToLeft ? source.minX - shadowMargin : source.maxX + shadowMargin - width
        let y = showsBelow ? source.maxY + gap - shadowMargin : source.minY - gap + shadowMargin - height
        frame = CGRect(x: min(max(x, frameBounds.minX), frameBounds.maxX - width),
                       y: min(max(y, frameBounds.minY), frameBounds.maxY - height),
                       width: width,
                       height: height)

        let cardWidth = max(1, width - shadowMargin * 2)
        pointer = POSMenuPointer(edge: showsBelow ? .top : .bottom,
                                 fraction: min(max((source.midX - frame.minX - shadowMargin) / cardWidth, 0), 1))
    }
}

private final class POSMenuPresentationController: UIPresentationController {
    var metrics: POSMetrics
    private weak var sourceView: UIView?
    private let updatePointer: (POSMenuPointer) -> Void
    private var lastPointer: POSMenuPointer?
    private let closeMenu: () -> Void
    private let outsideButton = UIButton(type: .custom)

    init(presentedViewController: UIViewController,
         presenting: UIViewController?,
         sourceView: UIView?,
         metrics: POSMetrics,
         updatePointer: @escaping (POSMenuPointer) -> Void,
         closeMenu: @escaping () -> Void) {
        self.sourceView = sourceView
        self.metrics = metrics
        self.updatePointer = updatePointer
        self.closeMenu = closeMenu
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }

    override var shouldRemovePresentersView: Bool {
        false
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        makeLayout()?.frame ?? .zero
    }

    private func makeLayout() -> POSMenuLayout? {
        guard let containerView, let sourceView else {
            return nil
        }
        let safeBounds = containerView.bounds.inset(by: containerView.safeAreaInsets)
            .insetBy(dx: metrics.padding.medium, dy: metrics.padding.medium)
        return POSMenuLayout(source: sourceView.convert(sourceView.bounds, to: containerView),
                             safeBounds: safeBounds,
                             preferredSize: presentedViewController.preferredContentSize,
                             isRightToLeft: sourceView.effectiveUserInterfaceLayoutDirection == .rightToLeft,
                             metrics: metrics)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        outsideButton.backgroundColor = .clear
        outsideButton.isAccessibilityElement = false
        outsideButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        containerView?.insertSubview(outsideButton, at: 0)
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        outsideButton.frame = containerView?.bounds ?? .zero
        let layout = makeLayout()
        presentedView?.frame = layout?.frame ?? .zero
        if let pointer = layout?.pointer, pointer != lastPointer {
            lastPointer = pointer
            updatePointer(pointer)
        }
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        containerView?.setNeedsLayout()
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            outsideButton.removeFromSuperview()
        }
    }

    @objc private func close() {
        closeMenu()
    }
}
