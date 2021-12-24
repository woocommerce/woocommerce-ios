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

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: shareSheet.activityItems, applicationActivities: nil)
        controller.excludedActivityTypes = shareSheet.excludedActivityTypes
        controller.completionWithItemsHandler = { activityType, completed, items, error in
            shareSheet.completion?(activityType, completed, items, error)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // nothing to do here
    }
}

extension View {
    func shareSheet(isPresented: Binding<Bool>, content: @escaping () -> ShareSheet) -> some View {
        sheet(isPresented: isPresented) {
            ShareSheetView(shareSheet: content())
        }
    }

    func sharePopover(isPresented: Binding<Bool>, content: @escaping () -> ShareSheet) -> some View {
        popover(isPresented: isPresented) {
            ShareSheetView(shareSheet: content())
        }
    }
}
