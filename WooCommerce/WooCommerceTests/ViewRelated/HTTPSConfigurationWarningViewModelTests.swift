import Foundation
import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct HTTPSConfigurationWarningViewModelTests {
    @Test func update_when_site_url_was_normalized_shows_warning_and_persists_requirement() {
        // Given
        let harness = Harness()
        let viewModel = harness.makeViewModel()

        // When
        viewModel.update(site: .fake().copy(siteID: harness.siteID, wasURLNormalizedToHTTPS: .some(true)), fallbackSiteAddress: nil)

        // Then
        #expect(viewModel.isVisible)
        #expect(harness.requiresUpdate == true)
    }

    @Test func update_when_requirement_is_unavailable_and_fallback_site_address_uses_http_shows_warning() {
        // Given
        let harness = Harness()
        let viewModel = harness.makeViewModel()

        // When
        viewModel.update(site: .fake().copy(siteID: harness.siteID, wasURLNormalizedToHTTPS: .some(nil)),
                         fallbackSiteAddress: "http://example.com")

        // Then
        #expect(viewModel.isVisible)
    }

    @Test func update_when_fresh_site_url_is_https_clears_warning_even_if_fallback_address_still_uses_http() {
        // Given
        let harness = Harness(requiresUpdate: true)
        let viewModel = harness.makeViewModel()
        let fallbackSiteAddress = "http://example.com"

        // When
        viewModel.update(site: .fake().copy(siteID: harness.siteID, wasURLNormalizedToHTTPS: .some(false)),
                         fallbackSiteAddress: fallbackSiteAddress)

        // Then
        #expect(!viewModel.isVisible)
        #expect(harness.requiresUpdate == false)
    }

    @Test func update_when_restored_site_has_persisted_requirement_shows_warning() {
        // Given
        let harness = Harness(requiresUpdate: true)
        let viewModel = harness.makeViewModel()

        // When
        viewModel.update(site: .fake().copy(siteID: harness.siteID, wasURLNormalizedToHTTPS: .some(nil)), fallbackSiteAddress: nil)

        // Then
        #expect(viewModel.isVisible)
    }

    @Test func update_when_warning_was_dismissed_less_than_one_day_ago_hides_warning() {
        // Given
        let now = Date(timeIntervalSince1970: 1_000_000)
        let harness = Harness(requiresUpdate: true, lastDismissedDate: now.addingTimeInterval(-86_399), now: now)
        let viewModel = harness.makeViewModel()

        // When
        viewModel.update(site: .fake().copy(siteID: harness.siteID, wasURLNormalizedToHTTPS: .some(nil)), fallbackSiteAddress: nil)

        // Then
        #expect(!viewModel.isVisible)
    }

    @Test func update_when_warning_was_dismissed_one_day_ago_shows_warning_again() {
        // Given
        let now = Date(timeIntervalSince1970: 1_000_000)
        let harness = Harness(requiresUpdate: true, lastDismissedDate: now.addingTimeInterval(-86_400), now: now)
        let viewModel = harness.makeViewModel()

        // When
        viewModel.update(site: .fake().copy(siteID: harness.siteID, wasURLNormalizedToHTTPS: .some(nil)), fallbackSiteAddress: nil)

        // Then
        #expect(viewModel.isVisible)
    }

    @Test func dismiss_records_current_time_and_hides_warning() {
        // Given
        let now = Date(timeIntervalSince1970: 1_000_000)
        let harness = Harness(requiresUpdate: true, now: now)
        let viewModel = harness.makeViewModel()
        viewModel.update(site: .fake().copy(siteID: harness.siteID, wasURLNormalizedToHTTPS: .some(nil)), fallbackSiteAddress: nil)

        // When
        viewModel.dismiss()

        // Then
        #expect(!viewModel.isVisible)
        #expect(harness.lastDismissedDate == now)
    }
}

@MainActor
private final class Harness {
    let siteID: Int64 = 123
    var requiresUpdate: Bool?
    var lastDismissedDate: Date?

    private let stores = MockStoresManager(sessionManager: .makeForTesting())
    private let now: Date

    init(requiresUpdate: Bool? = nil, lastDismissedDate: Date? = nil, now: Date = Date()) {
        self.requiresUpdate = requiresUpdate
        self.lastDismissedDate = lastDismissedDate
        self.now = now

        stores.whenReceivingAction(ofType: AppSettingsAction.self) { [weak self] action in
            guard let self else { return }
            switch action {
            case let .setHTTPSConfigurationUpdateRequired(_, required):
                self.requiresUpdate = required
            case let .getHTTPSConfigurationWarningState(_, onCompletion):
                onCompletion(self.requiresUpdate, self.lastDismissedDate)
            case let .dismissHTTPSConfigurationWarning(_, time):
                self.lastDismissedDate = time
            default:
                break
            }
        }
    }

    func makeViewModel() -> HTTPSConfigurationWarningViewModel {
        HTTPSConfigurationWarningViewModel(stores: stores, currentDate: { [now] in now })
    }
}
