import UITestsFoundation
import XCTest

final class StatsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()

        try LoginFlow.login()
    }

    func test_load_stats_screen() throws {
        try TabNavComponent().goToMyStoreScreen()
            .verifyTodayStatsLoaded()
            .goToThisWeekTab()
            .verifyThisWeekStatsLoaded()
            .goToThisMonthTab()
            .verifyThisMonthStatsLoaded()
            .goToThisYearTab()
            .verifyThisYearStatsLoaded()
    }

    func test_view_detailed_chart_stats() throws {
        let myStoreScreen = try MyStoreScreen()

        var dailyRevenue = try TabNavComponent()
            .goToMyStoreScreen()
            .getRevenueValue()

        myStoreScreen.tapChart()
        let hourlyRevenue = myStoreScreen.getRevenueValue()
        myStoreScreen.verifyRevenueUpdated(originalRevenue: dailyRevenue, updatedRevenue: hourlyRevenue)

        myStoreScreen.goToThisWeekTab()
        var weeklyRevenue = try MyStoreScreen().getRevenueValue()
        myStoreScreen.tapChart()
        dailyRevenue = myStoreScreen.getRevenueValue()
        myStoreScreen.verifyRevenueUpdated(originalRevenue: weeklyRevenue, updatedRevenue: dailyRevenue)

        myStoreScreen.goToThisMonthTab()
        var monthlyRevenue = try MyStoreScreen().getRevenueValue()
        myStoreScreen.tapChart()
        weeklyRevenue = myStoreScreen.getRevenueValue()
        myStoreScreen.verifyRevenueUpdated(originalRevenue: monthlyRevenue, updatedRevenue: weeklyRevenue)

        myStoreScreen.goToThisYearTab()
        let yearlyRevenue = try MyStoreScreen().getRevenueValue()
        myStoreScreen.tapChart()
        monthlyRevenue = myStoreScreen.getRevenueValue()
        myStoreScreen.verifyRevenueUpdated(originalRevenue: yearlyRevenue, updatedRevenue: monthlyRevenue)
    }
}
