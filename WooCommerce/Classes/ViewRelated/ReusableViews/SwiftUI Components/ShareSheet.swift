import Foundation
import SwiftUI
import UIKit

struct ShareSheet {
    typealias Completion = (UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void
    let activityItems: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?
    let completion: Completion?

    init(activityItems: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil, completion: Completion? = nil) {
        self.activityItems = activityItems
        self.excludedActivityTypes = excludedActivityTypes
        self.completion = completion
    }
}

private struct ShareSheetView: UIViewControllerRepresentable {
    let shareSheet: ShareSheet
    let sourceView: UIView?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: shareSheet.activityItems, applicationActivities: nil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            controller.modalPresentationStyle = .popover
        }
        controller.excludedActivityTypes = shareSheet.excludedActivityTypes
        controller.completionWithItemsHandler = { activityType, completed, items, error in
            shareSheet.completion?(activityType, completed, items, error)
        }
        configurePopover(for: controller)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        configurePopover(for: uiViewController)
    }

    private func configurePopover(for controller: UIActivityViewController) {
        guard let popoverController = controller.popoverPresentationController else {
            return
        }

        controller.loadViewIfNeeded()
        guard let anchorView = sourceView ?? controller.view else {
            return
        }

        popoverController.sourceView = anchorView
        popoverController.sourceRect = anchorView.bounds

        if self.sourceView == nil {
            popoverController.permittedArrowDirections = []
        }
    }
}

private struct ShareSheetAnchorView: UIViewRepresentable {
    @Binding var sourceView: UIView?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard sourceView !== uiView else {
            return
        }

        let sourceViewBinding = $sourceView
        DispatchQueue.main.async {
            sourceViewBinding.wrappedValue = uiView
        }
    }
}

private struct ShareSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let shareSheet: () -> ShareSheet

    @State private var sourceView: UIView?

    func body(content: Content) -> some View {
        content
            .background(ShareSheetAnchorView(sourceView: $sourceView))
            .sheet(isPresented: $isPresented) {
                ShareSheetView(shareSheet: shareSheet(), sourceView: sourceView)
                    .presentationDetents([.medium, .large])
            }
    }
}

private struct SharePopoverModifier: ViewModifier {
    @Binding var isPresented: Bool
    let shareSheet: () -> ShareSheet

    @State private var sourceView: UIView?

    func body(content: Content) -> some View {
        content
            .background(ShareSheetAnchorView(sourceView: $sourceView))
            .popover(isPresented: $isPresented) {
                ShareSheetView(shareSheet: shareSheet(), sourceView: sourceView)
            }
    }
}

extension View {
    func shareSheet(isPresented: Binding<Bool>, content: @escaping () -> ShareSheet) -> some View {
        modifier(ShareSheetModifier(isPresented: isPresented, shareSheet: content))
    }

    func sharePopover(isPresented: Binding<Bool>, content: @escaping () -> ShareSheet) -> some View {
        modifier(SharePopoverModifier(isPresented: isPresented, shareSheet: content))
    }
}
