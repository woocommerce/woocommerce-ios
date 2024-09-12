import XCTest
@testable import WooCommerce
@testable import Yosemite
@testable import Networking

final class MarkOrderAsReadUseCaseTests: XCTestCase {

    @MainActor
    func test_markOrderNoteAsReadIfNeeded_with_stores() async {
        let stores: StoresManager = MockStoresManager(sessionManager: .makeForTesting())

        let noteID: Int64 = 1
        let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(stores: stores, noteID: noteID, orderID: 1)
        switch result {
        case .success(let markedNote):
            XCTAssertEqual(noteID, markedNote.noteID)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func test_markOrderNoteAsReadIfNeeded_with_network() async {
        let network: Network = MockNetwork()

        let noteID: Int64 = 1
        let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(network: network, noteID: 1, orderID: 1)
        switch result {
        case .success(let markedNoteID):
            XCTAssertEqual(noteID, markedNoteID)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
}
