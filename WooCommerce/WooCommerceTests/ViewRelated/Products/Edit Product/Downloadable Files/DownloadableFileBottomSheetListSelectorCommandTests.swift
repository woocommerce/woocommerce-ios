import XCTest
@testable import WooCommerce
@testable import Yosemite

final class DownloadableFileBottomSheetListSelectorCommandTests: XCTestCase {
    // MARK: - `handleSelectedChange`

    func test_callback_is_called_on_selection() {
        // Arrange
        let actions: [DownloadableFileSource] = [.deviceMedia, .deviceDocument, .wordPressMediaLibrary, .fileURL]
        var selectedActions = [DownloadableFileSource]()
        let command = DownloadableFileBottomSheetListSelectorCommand(actions: actions) { selected in
                                                                    selectedActions.append(selected)
        }

        // Action
        command.handleSelectedChange(selected: .fileURL)
        command.handleSelectedChange(selected: .wordPressMediaLibrary)
        command.handleSelectedChange(selected: .deviceMedia)
        command.handleSelectedChange(selected: .deviceDocument)

        // Assert
        let expectedActions: [DownloadableFileSource] = [
            .fileURL,
            .wordPressMediaLibrary,
            .deviceMedia,
            .deviceDocument
        ]
        XCTAssertEqual(selectedActions, expectedActions)
    }
}
