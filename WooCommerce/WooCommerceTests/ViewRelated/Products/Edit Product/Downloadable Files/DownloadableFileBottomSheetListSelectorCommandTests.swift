import XCTest
@testable import WooCommerce
@testable import Yosemite

final class DownloadableFileBottomSheetListSelectorCommandTests: XCTestCase {
    // MARK: - `handleSelectedChange`

    func testCallbackIsCalledOnSelection() {
        // Arrange
        let actions: [DownloadableFileFormBottomSheetAction] = [.fromDevice, .fromWordPressMediaLibrary, .fromFileURL]
        var selectedActions = [DownloadableFileFormBottomSheetAction]()
        let command = DownloadableFileBottomSheetListSelectorCommand(actions: actions) { selected in
                                                                    selectedActions.append(selected)
        }

        // Action
        command.handleSelectedChange(selected: .fromFileURL)
        command.handleSelectedChange(selected: .fromWordPressMediaLibrary)
        command.handleSelectedChange(selected: .fromDevice)

        // Assert
        let expectedActions: [DownloadableFileFormBottomSheetAction] = [
            .fromFileURL,
            .fromWordPressMediaLibrary,
            .fromDevice
        ]
        XCTAssertEqual(selectedActions, expectedActions)
    }
}
