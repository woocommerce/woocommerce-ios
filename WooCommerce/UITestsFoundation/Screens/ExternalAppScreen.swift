import XCTest

public final class ExternalAppScreen {

    public private(set) var app: XCUIApplication!

    public init() {
        app = XCUIApplication()
    }

    // To open universal links without depending on mocks
    public func openUniversalLinkFromRemindersApp(link: String) {

        let reminders = XCUIApplication(bundleIdentifier: "com.apple.reminders")
        reminders.launch()

        // To dismiss the welcome screen if displayed
        let continueButton = reminders.buttons["Continue"]
        if continueButton.exists {
            continueButton.tap()
        }

        // Add universal link as reminder
        let remindersTable = reminders.otherElements["RemindersList.ID.RemindersTable"]
        if !reminders.textFields["Title"].exists { remindersTable.tap() }
        reminders.textFields["Title"].typeText("\(link)")
        remindersTable.tap()

        // Mark reminder as done to remove from list on next visit
        reminders.buttons["CompleteOff"].tap()

        // Tap first reminder on list
        reminders.cells.links.firstMatch.tap()
    }

    // To open universal links using mocks
    public func openUniversalLinkFromSafariApp(link: String) {

        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()

        // Go to Wiremock's HTML file with universal links
        safari.textFields["TabBarItemTitle"].tap()
        safari.typeText("http://localhost:8282/links.html")
        safari.buttons["Go"].tap()

        // Tap on the universal link
        if safari.staticTexts["TESTING LINKS"].exists { safari.links[link].tap() }
    }
}
