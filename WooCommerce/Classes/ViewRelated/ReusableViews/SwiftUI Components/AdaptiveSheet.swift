import SwiftUI
import UIKit

/// This view implements a bottom popover that adapts to in compact size classes.
/// It uses a `UIHostingController` instance with a popover presentation style and medium/large detents depending on the screen orientation.
/// Once iOS 15 is dropped, we can discontinue this solution and use the SwiftUI approach by applying `presentationDetents` to the view.
///
struct AdaptiveSheet<T: View>: ViewModifier {
    let sheetContent: T
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> T) {
        self.sheetContent = content()
        self._isPresented = isPresented
    }
    func body(content: Content) -> some View {
        ZStack {
            content
            AdaptiveSheetViewControllerRepresentable(isPresented: $isPresented, content: { sheetContent })
            .frame(width: 0, height: 0)
        }
    }
}

extension View {
    func adaptiveSheet<T: View>(isPresented: Binding<Bool>,
                                @ViewBuilder content: @escaping () -> T)-> some View {
        modifier(AdaptiveSheet(isPresented: isPresented,
                               content: content))
    }
}

struct AdaptiveSheetViewControllerRepresentable<Content: View>: UIViewControllerRepresentable {
    let content: Content
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>,
         @ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        self._isPresented = isPresented
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> AdaptiveSheetViewController<Content> {
        AdaptiveSheetViewController(coordinator: context.coordinator,
                                  content: {content})
    }

    func updateUIViewController(_ uiViewController: AdaptiveSheetViewController<Content>, context: Context) {
        if isPresented {
            uiViewController.presentModalView()
        } else if uiViewController.presentedViewController != nil {
            uiViewController.dismissModalView()
        }
    }

    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var parent: AdaptiveSheetViewControllerRepresentable
        init(_ parent: AdaptiveSheetViewControllerRepresentable) {
            self.parent = parent
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            //Adjust the variable when the user dismisses with a swipe
            parent.isPresented = false
        }
    }
}

class AdaptiveSheetViewController<Content: View>: UIViewController {
    let content: Content
    let coordinator: AdaptiveSheetViewControllerRepresentable<Content>.Coordinator
    private var isLandscape: Bool = UIDevice.current.orientation.isLandscape

    init(coordinator: AdaptiveSheetViewControllerRepresentable<Content>.Coordinator,
         @ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: .main)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func dismissModalView() {
        dismiss(animated: true, completion: nil)
    }
    func presentModalView() {
        let hostingController = UIHostingController(rootView: content)

        hostingController.modalPresentationStyle = .popover
        hostingController.presentationController?.delegate = coordinator as UIAdaptivePresentationControllerDelegate
        hostingController.modalTransitionStyle = .coverVertical
        if let hostPopover = hostingController.popoverPresentationController {
            hostPopover.sourceView = super.view
            let sheet = hostPopover.adaptiveSheetPresentationController
            sheet.detents = (isLandscape ? [.large()] : [.medium()])

        }
        if presentedViewController == nil {
            present(hostingController, animated: true, completion: nil)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.orientation.isLandscape {
            isLandscape = true
            self.presentedViewController?.popoverPresentationController?.adaptiveSheetPresentationController.detents = [.large()]
        } else {
            isLandscape = false
            self.presentedViewController?.popoverPresentationController?.adaptiveSheetPresentationController.detents = [.medium()]
        }
    }
}
