import XCTest
@testable import WooCommerce

final class DashboardTopPerformersViewModelTests: XCTestCase {
    // MARK: - Initializer in different states

    func test_init_with_loading_state_sets_isRedacted_and_placeholder_rows() throws {
        // Given
        let viewModel = DashboardTopPerformersViewModel(state: .loading, onTap: { _ in })

        // Then
        XCTAssertTrue(viewModel.isRedacted)
        XCTAssertEqual(viewModel.rows.count, 3)
    }

    func test_init_with_loaded_state_and_empty_rows_sets_isRedacted_and_empty_rows() throws {
        // Given
        let viewModel = DashboardTopPerformersViewModel(state: .loaded(rows: []), onTap: { _ in })

        // Then
        XCTAssertFalse(viewModel.isRedacted)
        XCTAssertEqual(viewModel.rows.count, 0)
    }

    func test_init_with_loaded_state_and_nonempty_rows_sets_isRedacted_and_rows() throws {
        // Given
        let viewModel = DashboardTopPerformersViewModel(state: .loaded(rows: [.fake()]), onTap: { _ in })

        // Then
        XCTAssertFalse(viewModel.isRedacted)
        XCTAssertEqual(viewModel.rows.count, 1)
    }

    // MARK: - `update(state:)`

    func test_updateState_with_loading_state_sets_isRedacted_and_placeholder_rows() throws {
        // Given
        let viewModel = DashboardTopPerformersViewModel(state: .loaded(rows: [.fake()]), onTap: { _ in })

        // When
        viewModel.update(state: .loading)

        // Then
        XCTAssertTrue(viewModel.isRedacted)
        XCTAssertEqual(viewModel.rows.count, 3)
    }

    func test_updateState_with_loaded_state_sets_isRedacted_and_rows() throws {
        // Given
        let viewModel = DashboardTopPerformersViewModel(state: .loading, onTap: { _ in })

        // When
        viewModel.update(state: .loaded(rows: [.fake()]))

        // Then
        XCTAssertFalse(viewModel.isRedacted)
        XCTAssertEqual(viewModel.rows.count, 1)
    }
}
