import SwiftUI
import struct Yosemite.BlazeTargetDevice

/// View for picking target devices for a Blaze campaign
struct BlazeTargetDevicePickerView: View {

    @ObservedObject private var viewModel: BlazeTargetDevicePickerViewModel

    private let onDismiss: () -> Void

    init(viewModel: BlazeTargetDevicePickerViewModel,
         onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationView {
            Group {
                switch viewModel.syncState {
                case .syncing:
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                case .result(let devices):
                    MultiSelectionList(allOptionsTitle: Localization.allTitle,
                                       contents: devices,
                                       contentKeyPath: \.name,
                                       selectedItems: $viewModel.selectedDevices)
                case .error:
                    ErrorStateView(title: Localization.errorMessage,
                                   image: .errorImage,
                                   actionTitle: Localization.tryAgain,
                                   actionHandler: {
                        Task {
                            await viewModel.syncDevices()
                        }
                    })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButtonTitle, action: onDismiss)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.saveButtonTitle) {
                        viewModel.confirmSelection()
                        onDismiss()
                    }
                    .disabled(viewModel.shouldDisableSaveButton)
                }
            }
        }
        .navigationViewStyle(.stack)
        .task {
            await viewModel.syncDevices()
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
        static let errorMessage = NSLocalizedString(
            "blazeTargetDevicePickerView.errorMessage",
            value: "Error syncing target devices. Please try again.",
            comment: "Error message when data syncing fails on the target device picker for campaign creation"
        )
        static let tryAgain = NSLocalizedString(
            "blazeTargetDevicePickerView.tryAgain",
            value: "Try Again",
            comment: "Button to retry syncing data on the target device picker for campaign creation"
        )
    }
}

struct BlazeTargetDevicePickerView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeTargetDevicePickerView(viewModel: BlazeTargetDevicePickerViewModel(siteID: 123, selectedDevices: nil) { _ in }, onDismiss: {})
    }
}
