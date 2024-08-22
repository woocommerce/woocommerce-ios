import XCTest
@testable import WooCommerce
import struct Yosemite.BlazeCampaignListItem

final class BlazeCampaignListItemCustomizationsTests: XCTestCase {

    func test_isActive_is_correct() {
        // Given
        let campaigns = BlazeCampaignListItem.Status.allCases.map { status in
            BlazeCampaignListItem.fake().copy(uiStatus: status.rawValue)
        }

        // Then
        let activeStatuses: [BlazeCampaignListItem.Status] = [.active, .pending, .scheduled]
        for campaign in campaigns {
            if activeStatuses.contains(campaign.status) {
                XCTAssertTrue(campaign.isActive)
            } else {
                XCTAssertFalse(campaign.isActive)
            }
        }
    }

    func test_budgetToDisplay_is_total_budget_for_inactive_non_evergreen_campaign() {
        // Given
        let campaign = BlazeCampaignListItem.fake().copy(uiStatus: "cancelled", totalBudget: 120, isEvergreen: false, durationDays: 6)

        // When
        let budgetToDisplay = campaign.budgetToDisplay
        let budgetTitle = campaign.budgetTitle

        // Then
        XCTAssertEqual(budgetToDisplay, "$120")
        XCTAssertEqual(budgetTitle, "Total")
    }

    func test_budgetToDisplay_is_remaining_budget_for_active_non_evergreen_campaign() {
        // Given
        let campaign = BlazeCampaignListItem.fake().copy(uiStatus: "active", totalBudget: 120, spentBudget: 50, isEvergreen: false, durationDays: 6)

        // When
        let budgetToDisplay = campaign.budgetToDisplay
        let budgetTitle = campaign.budgetTitle

        // Then
        XCTAssertEqual(budgetToDisplay, "$70")
        XCTAssertEqual(budgetTitle, "Remaining")
    }

    func test_budgetToDisplay_is_weekly_budget_for_evergreen_campaign() {
        // Given
        let campaign = BlazeCampaignListItem.fake().copy(totalBudget: 1820, isEvergreen: true, durationDays: 364)

        // When
        let budgetToDisplay = campaign.budgetToDisplay
        let budgetTitle = campaign.budgetTitle

        // Then
        XCTAssertEqual(budgetToDisplay, "$35")
        XCTAssertEqual(budgetTitle, "Weekly")
    }
}
