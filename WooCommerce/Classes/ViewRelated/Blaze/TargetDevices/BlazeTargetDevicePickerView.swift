import SwiftUI
import struct Yosemite.BlazeTargetDevice

/// View for picking target devices for a Blaze campaign
struct BlazeTargetDevicePickerView: View {

    @ObservedObject private var viewModel: BlazeTargetDevicePickerViewModel

    private let selectedDevices: Set<BlazeTargetDevice>?
    private let onDismiss: () -> Void

    init(viewModel: BlazeTargetDevicePickerViewModel,
         selectedDevices: Set<BlazeTargetDevice>?,
         onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.selectedDevices = selectedDevices
        self.onDismiss = onDismiss
    }

    var body: some View {
        MultiSelectionList(title: Localization.title,
                           allOptionsTitle: Localization.allTitle,
                           contents: viewModel.devices,
                           contentKeyPath: \.name,
                           selectedItems: selectedDevices,
                           onDismiss: onDismiss,
                           onCompletion: { selectedDevices in
                                viewModel.confirmSelection(selectedDevices)
                                onDismiss()
                            })
        .task {
            await viewModel.syncDevices()
        }

    }
}

private extension BlazeTargetDevicePickerView {
    enum Localization {
        static let title = NSLocalizedString(
            "blazeTargetLanguagePickerView.title",
            value: "Devices",
            comment: "Title of the target device picker view for Blaze campaign creation"
        )
        static let allTitle = NSLocalizedString(
            "blazeTargetLanguagePickerView.allTitle",
            value: "All devices",
            comment: "Title of the row to select all target devices for Blaze campaign creation"
        )
    }
}

struct BlazeTargetDevicePickerView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeTargetDevicePickerView(viewModel: BlazeTargetDevicePickerViewModel(siteID: 123) { _ in }, selectedDevices: nil, onDismiss: {})
    }
}
