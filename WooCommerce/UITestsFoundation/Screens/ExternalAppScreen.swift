import XCTest

public final class ExternalAppScreen {

    public private(set) var app: XCUIApplication!

    public init() {
        app = XCUIApplication()
    }

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
        if !reminders.textFields["Title"].exists {
            remindersTable.tap()
        }

        reminders.textFields["Title"].typeText("\(link)")
        remindersTable.tap()

        // Mark reminder as done to remove from list on next visit
        reminders.buttons["CompleteOff"].tap()

        // Tap first reminder on list
        reminders.cells.links.firstMatch.tap()
    }
}
