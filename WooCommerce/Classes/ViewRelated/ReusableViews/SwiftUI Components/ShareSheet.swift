import Foundation
import SwiftUI
import UIKit

struct ShareSheet {
    typealias Completion = (UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void
    let activityItems: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?
    let permittedArrowDirections: UIPopoverArrowDirection?
    let completion: Completion?

    init(activityItems: [Any],
         excludedActivityTypes: [UIActivity.ActivityType]? = nil,
         permittedArrowDirections: UIPopoverArrowDirection? = nil,
         completion: Completion? = nil) {
        self.activityItems = activityItems
        self.excludedActivityTypes = excludedActivityTypes
        self.permittedArrowDirections = permittedArrowDirections
        self.completion = completion
    }
}

private struct ShareSheetPresenterView: UIViewRepresentable {
    @Binding var isPresented: Bool
    let shareSheet: () -> ShareSheet

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.isPresented = $isPresented

        if isPresented {
            context.coordinator.present(shareSheet(), from: uiView)
        } else {
            context.coordinator.dismissPresentedShareSheet()
        }
    }
}

private extension ShareSheetPresenterView {
    final class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var isPresented: Binding<Bool>
        private weak var presentedController: UIActivityViewController?

        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }

        func present(_ shareSheet: ShareSheet, from sourceView: UIView) {
            guard presentedController == nil,
                  sourceView.window != nil,
                  let presentingController = sourceView.nearestViewController?.topmostViewControllerForShareSheet else {
                return
            }

            let controller = UIActivityViewController(activityItems: shareSheet.activityItems, applicationActivities: nil)
            controller.excludedActivityTypes = shareSheet.excludedActivityTypes
            controller.completionWithItemsHandler = { [weak self] activityType, completed, items, error in
                shareSheet.completion?(activityType, completed, items, error)
                self?.presentedController = nil
                self?.isPresented.wrappedValue = false
            }
            configurePresentation(for: controller, sourceView: sourceView, shareSheet: shareSheet)
            controller.presentationController?.delegate = self

            presentedController = controller
            presentingController.present(controller, animated: true)
        }

        func dismissPresentedShareSheet() {
            presentedController?.dismiss(animated: true)
            presentedController = nil
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            presentedController = nil
            isPresented.wrappedValue = false
        }

        private func configurePresentation(for controller: UIActivityViewController, sourceView: UIView, shareSheet: ShareSheet) {
            if let popoverController = controller.popoverPresentationController {
                popoverController.sourceItem = sourceView
                if let permittedArrowDirections = shareSheet.permittedArrowDirections {
                    popoverController.permittedArrowDirections = permittedArrowDirections
                }
            }
        }
    }
}

private extension UIView {
    var nearestViewController: UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
}

private extension UIViewController {
    var topmostViewControllerForShareSheet: UIViewController {
        if let presentedViewController {
            return presentedViewController.topmostViewControllerForShareSheet
        }

        if let navigationController = self as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.topmostViewControllerForShareSheet
        }

        if let tabBarController = self as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.topmostViewControllerForShareSheet
        }

        return self
    }
}

private struct ShareViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    let shareSheet: () -> ShareSheet

    func body(content: Content) -> some View {
        content.background(ShareSheetPresenterView(isPresented: $isPresented, shareSheet: shareSheet))
    }
}

extension View {
    func shareView(isPresented: Binding<Bool>, content: @escaping () -> ShareSheet) -> some View {
        modifier(ShareViewModifier(isPresented: isPresented, shareSheet: content))
    }
}
