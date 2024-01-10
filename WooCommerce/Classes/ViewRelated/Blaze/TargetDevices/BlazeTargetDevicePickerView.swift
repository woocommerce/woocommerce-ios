import SwiftUI
import struct Yosemite.BlazeTargetDevice

/// View for picking target devices for a Blaze campaign
struct BlazeTargetDevicePickerView: View {

    @ObservedObject private var viewModel: BlazeTargetDevicePickerViewModel
    @State private var selectedDevices: Set<BlazeTargetDevice>?

    private let onDismiss: () -> Void

    init(viewModel: BlazeTargetDevicePickerViewModel,
         selectedDevices: Set<BlazeTargetDevice>?,
         onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.selectedDevices = selectedDevices
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationView {
            Group {
                MultiSelectionList(allOptionsTitle: Localization.allTitle,
                                   contents: viewModel.devices,
                                   contentKeyPath: \.name,
                                   selectedItems: $selectedDevices)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButtonTitle, action: onDismiss)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.saveButtonTitle) {
                        viewModel.confirmSelection(selectedDevices)
                        onDismiss()
                    }
                    .disabled(selectedDevices?.isEmpty == true)
                }
            }
            .task {
                await viewModel.syncDevices()
            }
        }
    }
}

private extension BlazeTargetDevicePickerView {
    enum Localization {
        static let title = NSLocalizedString(
            "blazeTargetDevicePickerView.title",
            value: "Devices",
            comment: "Title of the target device picker view for Blaze campaign creation"
        )
        static let allTitle = NSLocalizedString(
            "blazeTargetDevicePickerView.allTitle",
            value: "All devices",
            comment: "Title of the row to select all target devices for Blaze campaign creation"
        )
        static let cancelButtonTitle = NSLocalizedString(
            "blazeTargetDevicePickerView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the target device picker for campaign creation"
        )
        static let saveButtonTitle = NSLocalizedString(
            "blazeTargetDevicePickerView.save",
            value: "Save",
            comment: "Button to save the selections on the target device picker for campaign creation"
        )
    }
}

struct BlazeTargetDevicePickerView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeTargetDevicePickerView(viewModel: BlazeTargetDevicePickerViewModel(siteID: 123) { _ in }, selectedDevices: [], onDismiss: {})
    }
}
