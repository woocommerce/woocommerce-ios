import SwiftUI
import XCTest
import Yosemite
@testable import WooCommerce

final class InboxNoteRowViewModelTests: XCTestCase {
    // MARK: - `InboxNoteRowViewModel`

    func test_initializing_InboxNoteRowViewModel_with_note_has_expected_title_content_actions() throws {
        // Given
        let action = InboxAction.fake().copy(id: 606)
        let note = InboxNote.fake().copy(actions: [action])

        // When
        let viewModel = InboxNoteRowViewModel(note: note)

        // Then
        XCTAssertEqual(viewModel.id, note.id)
        XCTAssertEqual(viewModel.title, note.title)
        XCTAssertEqual(viewModel.attributedContent.string, note.content)

        let actionViewModel = try XCTUnwrap(viewModel.actions.first)
        XCTAssertEqual(actionViewModel.id, action.id)
    }

    func test_initializing_InboxNoteRowViewModel_with_dateCreated_now_sets_date_to_now() throws {
        // Given
        // GMT Tuesday, February 15, 2022 6:55:28 AM
        let today = Date(timeIntervalSince1970: 1644908128)
        let note = InboxNote.fake().copy(dateCreated: today)
        let locale = Locale(identifier: "en_US")
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let calendar = Calendar(identifier: .gregorian, timeZone: timeZone)

        // When
        let viewModel = InboxNoteRowViewModel(note: note, today: today, locale: locale, calendar: calendar)

        // Then
        XCTAssertEqual(viewModel.date, "now")
    }

    func test_initializing_InboxNoteRowViewModel_with_dateCreated_2_months_ago_sets_date_accordingly() throws {
        // Given
        // GMT Tuesday, February 15, 2022 6:55:28 AM
        let today = Date(timeIntervalSince1970: 1644908128)
        // GMT Wednesday, December 15, 2021 6:55:28 AM
        let twoMonthsAgo = Date(timeIntervalSince1970: 1639551328)
        let note = InboxNote.fake().copy(dateCreated: twoMonthsAgo)
        let locale = Locale(identifier: "en_US")
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let calendar = Calendar(identifier: .gregorian, timeZone: timeZone)

        // When
        let viewModel = InboxNoteRowViewModel(note: note, today: today, locale: locale, calendar: calendar)

        // Then
        XCTAssertEqual(viewModel.date, "2 months ago")
    }

    func test_initializing_InboxNoteRowViewModel_with_dateCreated_2_months_later_sets_date_accordingly() throws {
        // Given
        // GMT Tuesday, February 15, 2022 6:55:28 AM
        let today = Date(timeIntervalSince1970: 1644908128)
        // GMT Friday, April 15, 2022 6:55:28 AM
        let twoMonthsLater = Date(timeIntervalSince1970: 1650005728)
        let note = InboxNote.fake().copy(dateCreated: twoMonthsLater)
        let locale = Locale(identifier: "en_US")
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let calendar = Calendar(identifier: .gregorian, timeZone: timeZone)

        // When
        let viewModel = InboxNoteRowViewModel(note: note, today: today, locale: locale, calendar: calendar)

        // Then
        XCTAssertEqual(viewModel.date, "in 2 months")
    }

    // MARK: - `InboxNoteRowActionViewModel`

    func test_initializing_InboxNoteRowActionViewModel_with_action_with_empty_URL_path_has_nil_URL() {
        // When
        let actionViewModel = InboxNoteRowActionViewModel(action: .init(id: 134, name: "wcpay_applepay_holiday2021",
                                                                        label: "Accept Apple Pay",
                                                                        status: "actioned",
                                                                        url: ""))

        // Then
        XCTAssertEqual(actionViewModel, .init(id: 134, title: "Accept Apple Pay", url: nil))
        XCTAssertNil(actionViewModel.url)
    }

    func test_initializing_InboxNoteRowActionViewModel_with_action_has_expected_properties() {
        // When
        let actionViewModel = InboxNoteRowActionViewModel(action: .init(id: 134, name: "wcpay_applepay_holiday2021",
                                                                        label: "Accept Apple Pay",
                                                                        status: "actioned",
                                                                        url: "https://woocommerce.com"))

        // Then
        XCTAssertEqual(actionViewModel, .init(id: 134, title: "Accept Apple Pay", url: .init(string: "https://woocommerce.com")))
        XCTAssertEqual(actionViewModel.id, 134)
        XCTAssertEqual(actionViewModel.title, "Accept Apple Pay")
        XCTAssertEqual(actionViewModel.url?.absoluteString, "https://woocommerce.com")
    }
}
