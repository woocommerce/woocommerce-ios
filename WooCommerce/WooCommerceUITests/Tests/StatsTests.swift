import UITestsFoundation
import XCTest

final class StatsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()

        try LoginFlow.logInWithWPcom()
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
        var hourlyRevenue = ""
        var dailyRevenue = ""
        var weeklyRevenue = ""
        var monthlyRevenue = ""
        var yearlyRevenue = ""

        try TabNavComponent()
            .goToMyStoreScreen()

        dailyRevenue = try MyStoreScreen().getRevenueValue()
        try MyStoreScreen().tapChart()
        hourlyRevenue = try MyStoreScreen().getRevenueValue()

        try MyStoreScreen().verifyRevenueUpdated(originalRevenue: dailyRevenue, updatedRevenue: hourlyRevenue)
        try MyStoreScreen().goToThisWeekTab()

        weeklyRevenue = try MyStoreScreen().getRevenueValue()
        try MyStoreScreen().tapChart()
        dailyRevenue = try MyStoreScreen().getRevenueValue()

        try MyStoreScreen().verifyRevenueUpdated(originalRevenue: weeklyRevenue, updatedRevenue: dailyRevenue)
        try MyStoreScreen().goToThisMonthTab()

        monthlyRevenue = try MyStoreScreen().getRevenueValue()
        try MyStoreScreen().tapChart()
        weeklyRevenue = try MyStoreScreen().getRevenueValue()

        try MyStoreScreen().verifyRevenueUpdated(originalRevenue: monthlyRevenue, updatedRevenue: weeklyRevenue)
        try MyStoreScreen().goToThisYearTab()

        yearlyRevenue = try MyStoreScreen().getRevenueValue()
        try MyStoreScreen().tapChart()
        monthlyRevenue = try MyStoreScreen().getRevenueValue()

        try MyStoreScreen().verifyRevenueUpdated(originalRevenue: yearlyRevenue, updatedRevenue: monthlyRevenue)
    }
}
