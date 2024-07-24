import XCTest
@testable import WooCommerce

final class TopPerformersPeriodViewModelTests: XCTestCase {
    // MARK: - Initializer in different states

    func test_init_with_loading_state_sets_isRedacted_and_placeholder_rows() throws {
        // Given
        let viewModel = TopPerformersPeriodViewModel(state: .loading(cached: []), onTap: { _ in })

        // Then
        XCTAssertTrue(viewModel.redacted.rows)
        XCTAssertTrue(viewModel.redacted.header)
        XCTAssertTrue(viewModel.redacted.actionButton)
        XCTAssertEqual(viewModel.rows.count, 3)
    }

    func test_init_with_loading_cached_state_sets_isRedacted_and_cached_rows() throws {
        // Given
        let viewModel = TopPerformersPeriodViewModel(state: .loading(cached: [.fake()]), onTap: { _ in })

        // Then
        XCTAssertFalse(viewModel.redacted.rows)
        XCTAssertFalse(viewModel.redacted.header)
        XCTAssertTrue(viewModel.redacted.actionButton)
        XCTAssertEqual(viewModel.rows.count, 1)
    }

    func test_init_with_loaded_state_and_empty_rows_sets_isRedacted_and_empty_rows() throws {
        // Given
        let viewModel = TopPerformersPeriodViewModel(state: .loaded(rows: []), onTap: { _ in })

        // Then
        XCTAssertFalse(viewModel.redacted.rows)
        XCTAssertFalse(viewModel.redacted.header)
        XCTAssertFalse(viewModel.redacted.actionButton)
        XCTAssertEqual(viewModel.rows.count, 0)
    }

    func test_init_with_loaded_state_and_nonempty_rows_sets_isRedacted_and_rows() throws {
        // Given
        let viewModel = TopPerformersPeriodViewModel(state: .loaded(rows: [.fake()]), onTap: { _ in })

        // Then
        XCTAssertFalse(viewModel.redacted.rows)
        XCTAssertFalse(viewModel.redacted.header)
        XCTAssertFalse(viewModel.redacted.actionButton)
        XCTAssertEqual(viewModel.rows.count, 1)
    }

    // MARK: - `update(state:)`

    func test_updateState_with_loading_state_sets_isRedacted_and_placeholder_rows() throws {
        // Given
        let viewModel = TopPerformersPeriodViewModel(state: .loaded(rows: [.fake()]), onTap: { _ in })

        // When
        viewModel.update(state: .loading(cached: []))

        // Then
        XCTAssertTrue(viewModel.redacted.rows)
        XCTAssertTrue(viewModel.redacted.header)
        XCTAssertTrue(viewModel.redacted.actionButton)
        XCTAssertEqual(viewModel.rows.count, 3)
    }

    func test_updateState_with_loaded_state_sets_isRedacted_and_rows() throws {
        // Given
        let viewModel = TopPerformersPeriodViewModel(state: .loading(cached: []), onTap: { _ in })

        // When
        viewModel.update(state: .loaded(rows: [.fake()]))

        // Then
        XCTAssertFalse(viewModel.redacted.rows)
        XCTAssertFalse(viewModel.redacted.header)
        XCTAssertFalse(viewModel.redacted.actionButton)
        XCTAssertEqual(viewModel.rows.count, 1)
    }
}
