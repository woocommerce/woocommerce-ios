import XCTest
@testable import WooCommerce
import struct Yosemite.BlazeCampaignListItem

final class BlazeCampaignListItemCustomizationsTests: XCTestCase {

    func test_budgetToDisplay_is_total_budget_for_non_evergreen_campaign() {
        // Given
        let campaign = BlazeCampaignListItem.fake().copy(totalBudget: 120, isEvergreen: false, durationDays: 6)

        // When
        let budgetToDisplay = campaign.budgetToDisplay
        let budgetTitle = campaign.budgetTitle

        // Then
        XCTAssertEqual(budgetToDisplay, "$120")
        XCTAssertEqual(budgetTitle, "Total budget")
    }

    func test_budgetToDisplay_is_weekly_budget_for_evergreen_campaign() {
        // Given
        let campaign = BlazeCampaignListItem.fake().copy(totalBudget: 1820, isEvergreen: true, durationDays: 364)

        // When
        let budgetToDisplay = campaign.budgetToDisplay
        let budgetTitle = campaign.budgetTitle

        // Then
        XCTAssertEqual(budgetToDisplay, "$35")
        XCTAssertEqual(budgetTitle, "Weekly budget")
    }
}
