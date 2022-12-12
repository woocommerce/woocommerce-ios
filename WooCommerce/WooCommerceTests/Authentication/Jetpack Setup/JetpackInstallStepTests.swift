import XCTest
@testable import WooCommerce

final class JetpackInstallStepTests: XCTestCase {
    private let testURL = "https://test.com"

    func test_analyticsDescription_has_correct_key() throws {
        // Given
        let sut = try XCTUnwrap(JetpackInstallStep.allCases.randomElement())

        // Then
        XCTAssertEqual("jetpack_install_step", sut.analyticsDescription.keys.first)
    }

    func test_analyticsDescription_has_correct_value_for_installation_step() throws {
        // Given
        let sut = JetpackInstallStep.installation

        // Then
        XCTAssertEqual("installation", sut.analyticsDescription.values.first)
    }

    func test_analyticsDescription_has_correct_value_for_activation_step() throws {
        // Given
        let sut = JetpackInstallStep.activation

        // Then
        XCTAssertEqual("activation", sut.analyticsDescription.values.first)
    }

    func test_analyticsDescription_has_correct_value_for_connection_step() throws {
        // Given
        let sut = JetpackInstallStep.connection

        // Then
        XCTAssertEqual("connection", sut.analyticsDescription.values.first)
    }

    func test_analyticsDescription_has_correct_value_for_done_step() throws {
        // Given
        let sut = JetpackInstallStep.done

        // Then
        XCTAssertEqual("all_done", sut.analyticsDescription.values.first)
    }
}
