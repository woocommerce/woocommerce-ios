import XCTest
@testable import WooCommerce

class AppRatingManagerTests: XCTestCase {
    fileprivate var defaults: UserDefaults?
    fileprivate var manager: AppRatingManager?

    private let suiteName = "appRatingManagerTests"


    override func setUp() {
        self.defaults = UserDefaults(suiteName: suiteName)
        self.manager = AppRatingManager(defaults: self.defaults!)
        self.manager?.setVersion("1.0")
        self.manager?.systemWideSignificantEventCountRequiredForPrompt = 1
        super.setUp()
    }

    override func tearDown() {
        self.defaults?.removePersistentDomain(forName: suiteName)
        self.defaults = nil
        self.manager = nil
        super.tearDown()
    }

    func testCheckForPromptReturnsFalseWithoutEnoughSignificantEvents() {
        self.manager?.systemWideSignificantEventCountRequiredForPrompt = 1
        XCTAssertFalse(manager!.shouldPromptForAppReview())
    }

    func testCheckForPromptReturnsTrueWithEnoughSignificantEvents() {
        self.manager?.systemWideSignificantEventCountRequiredForPrompt = 1
        self.manager?.incrementSignificantEvent()
        XCTAssertTrue(manager!.shouldPromptForAppReview())
    }

    func testCheckForPromptReturnsFalseIfUserHasRatedCurrentVersion() {
        self.createConditionsForPositiveAppReviewPrompt()
        XCTAssertTrue(self.manager!.shouldPromptForAppReview())
        self.manager?.ratedCurrentVersion()
        XCTAssertFalse(self.manager!.shouldPromptForAppReview())
    }

    func testCheckForPromptReturnsFalseIfUserHasGivenFeedbackForCurrentVersion() {
        self.createConditionsForPositiveAppReviewPrompt()
        XCTAssertTrue(self.manager!.shouldPromptForAppReview())
        self.manager?.gaveFeedbackForCurrentVersion()
        XCTAssertFalse(self.manager!.shouldPromptForAppReview())
    }

    func testCheckForPromptReturnsFalseIfUserHasDeclinedToRateCurrentVersion() {
        self.createConditionsForPositiveAppReviewPrompt()
        XCTAssertTrue(self.manager!.shouldPromptForAppReview())
        self.manager?.declinedToRateCurrentVersion()
        XCTAssertFalse(self.manager!.shouldPromptForAppReview())
    }

    func testCheckForPromptShouldResetForNewVersion() {
        self.createConditionsForPositiveAppReviewPrompt()
        XCTAssertTrue(self.manager!.shouldPromptForAppReview())
        self.manager?.setVersion("2.0")
        XCTAssertFalse(self.manager!.shouldPromptForAppReview())
    }

    func testCheckForPromptShouldTriggerWithNewVersion() {
        self.createConditionsForPositiveAppReviewPrompt()
        XCTAssertTrue(self.manager!.shouldPromptForAppReview())
        self.manager?.setVersion("2.0")
        XCTAssertFalse(self.manager!.shouldPromptForAppReview())
        self.createConditionsForPositiveAppReviewPrompt()
        XCTAssertTrue(self.manager!.shouldPromptForAppReview())
    }

    func testUserIsNotPromptedForAReviewForOneVersionIfTheyLikedTheApp() {
        self.manager?.setVersion("4.7")
        XCTAssertFalse(self.manager!.shouldPromptForAppReview())
        self.manager?.likedCurrentVersion()

        self.manager?.setVersion("4.8")
        self.manager?.incrementSignificantEvent()
        XCTAssertFalse(self.manager!.shouldPromptForAppReview(), "should not prompt for a review after liking last version")

        self.manager?.setVersion("4.9")
        self.manager?.incrementSignificantEvent()
        XCTAssertTrue(self.manager!.shouldPromptForAppReview(), "should prompt for a review after skipping a version")
    }

    func testUserIsNotPromptedForAReviewForTwoVersionsIfTheyDeclineToRate() {
        self.manager?.setVersion("4.7")
        XCTAssertFalse(self.manager!.shouldPromptForAppReview())
        self.manager?.dislikedCurrentVersion()

        self.manager?.setVersion("4.8")
        self.manager?.incrementSignificantEvent()
        XCTAssertFalse(self.manager!.shouldPromptForAppReview(), "should not prompt for a review after declining on this first upgrade")

        self.manager?.setVersion("4.9")
        self.manager?.incrementSignificantEvent()
        XCTAssertFalse(self.manager!.shouldPromptForAppReview(), "should not prompt for a review after declining on this second upgrade")

        self.manager?.setVersion("5.0")
        self.manager?.incrementSignificantEvent()
        XCTAssertTrue(self.manager!.shouldPromptForAppReview(), "should prompt for a review two versions later")
    }

    func testHasUserEverLikedApp() {
        self.manager?.setVersion("4.7")
        XCTAssertFalse(self.manager!.hasUserEverLikedApp())
        self.manager?.declinedToRateCurrentVersion()

        self.manager?.setVersion("4.8")
        XCTAssertFalse(self.manager!.hasUserEverLikedApp())
        self.manager?.likedCurrentVersion()
        XCTAssertTrue(self.manager!.hasUserEverLikedApp())

        self.manager?.setVersion("4.9")
        self.manager?.dislikedCurrentVersion()
        XCTAssertTrue(self.manager!.hasUserEverLikedApp())
    }

    func testHasUserEverDislikedTheApp() {
        self.manager?.setVersion("4.7")
        XCTAssertFalse(self.manager!.hasUserEverDislikedApp())
        self.manager?.declinedToRateCurrentVersion()

        self.manager?.setVersion("4.8")
        XCTAssertFalse(self.manager!.hasUserEverDislikedApp())
        self.manager?.dislikedCurrentVersion()
        XCTAssertTrue(self.manager!.hasUserEverDislikedApp())

        self.manager?.setVersion("4.9")
        self.manager?.likedCurrentVersion()
        XCTAssertTrue(self.manager!.hasUserEverDislikedApp())
    }

    func testShouldPromptForAppReviewForSection() {
        self.manager?.register(section: "notifications", significantEventCount: 2)
        self.manager?.setVersion("4.7")
        XCTAssertFalse(self.manager!.shouldPromptForAppReview(section: "notifications"))
        self.manager?.incrementSignificantEvent(section: "notifications")
        XCTAssertFalse(self.manager!.shouldPromptForAppReview(section: "notifications"))
        self.manager?.incrementSignificantEvent(section: "notifications")
        XCTAssertTrue(self.manager!.shouldPromptForAppReview(section: "notifications"))
    }

    func testShouldPromptAppReviewSystemWideWithEnoughSmallerSignficantEvents() {
        self.manager?.register(section: "notifications", significantEventCount: 2)
        self.manager?.register(section: "editor", significantEventCount: 2)
        self.manager?.systemWideSignificantEventCountRequiredForPrompt = 3
        self.manager?.setVersion("4.7")

        XCTAssertFalse(self.manager!.shouldPromptForAppReview(section: "notifications"))
        XCTAssertFalse(self.manager!.shouldPromptForAppReview(section: "editor"))
        XCTAssertFalse(self.manager!.shouldPromptForAppReview())

        self.manager?.incrementSignificantEvent(section: "notifications")
        self.manager?.incrementSignificantEvent(section: "editor")
        XCTAssertFalse(self.manager!.shouldPromptForAppReview())

        self.manager?.incrementSignificantEvent(section: "editor")
        XCTAssertTrue(self.manager!.shouldPromptForAppReview())
    }

    func testShouldPromptForAppReviewSystemWideWithEnoughSmallerSignificantEventsIncludingNonSectionedEvents() {
        self.manager?.register(section: "notifications", significantEventCount: 2)
        self.manager?.register(section: "editor", significantEventCount: 2)
        self.manager?.systemWideSignificantEventCountRequiredForPrompt = 3
        self.manager?.setVersion("4.7")

        XCTAssertFalse(self.manager!.shouldPromptForAppReview(section: "notifications"))
        XCTAssertFalse(self.manager!.shouldPromptForAppReview(section: "editor"))
        XCTAssertFalse(self.manager!.shouldPromptForAppReview())

        self.manager?.incrementSignificantEvent(section: "notifications")
        self.manager?.incrementSignificantEvent(section: "editor")
        XCTAssertFalse(self.manager!.shouldPromptForAppReview())

        self.manager?.incrementSignificantEvent()
        XCTAssertTrue(self.manager!.shouldPromptForAppReview())
    }

    func testAppReviewNotPromptedSystemWideWhenDisabledLocally() {
        self.manager?._overridePromptingDisabledLocal(true)
        self.manager?.systemWideSignificantEventCountRequiredForPrompt = 1
        self.manager?.incrementSignificantEvent()
        XCTAssertFalse(self.manager!.shouldPromptForAppReview())
    }

    func testAppReviewNotPromptedForSectionWhenDisabledLocally() {
        self.manager?._overridePromptingDisabledLocal(true)
        self.manager?.register(section: "notifications", significantEventCount: 1)
        self.manager?.incrementSignificantEvent(section: "notifications")
        XCTAssertFalse(self.manager!.shouldPromptForAppReview(section: "notifications"))
    }

    func testAppReviewPromptedAfterEnoughTime() {
        let magicValue = -(Int(ceil(365 / 2)) + 1)
        let fourMonthsAgo = Calendar.current.date(byAdding: .day, value: magicValue, to: Date())
        self.manager?._overrideLastPromptToRateDate(fourMonthsAgo!)
        self.manager?.systemWideSignificantEventCountRequiredForPrompt = 1
        self.manager?.incrementSignificantEvent()
        XCTAssertTrue(self.manager!.shouldPromptForAppReview())
    }

    func testAppReviewNotPromptedBeforeEnoughTime() {
        let twoMonthsAgo = Calendar.current.date(byAdding: .day, value: -61, to: Date())
        self.manager?._overrideLastPromptToRateDate(twoMonthsAgo!)
        self.manager?.systemWideSignificantEventCountRequiredForPrompt = 1
        self.manager?.incrementSignificantEvent()
        XCTAssertFalse(self.manager!.shouldPromptForAppReview())
    }

    fileprivate func createConditionsForPositiveAppReviewPrompt() {
        self.manager?.systemWideSignificantEventCountRequiredForPrompt = 1
        self.manager?.incrementSignificantEvent()
    }
}
