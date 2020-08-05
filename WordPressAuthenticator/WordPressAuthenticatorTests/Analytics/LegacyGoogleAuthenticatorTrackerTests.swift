import XCTest
@testable import WordPressAuthenticator

class LegacyGoogleAuthenticatorTrackerTests: XCTestCase {
    func testTrackLoginSocialButtonTapped() {
        let expectedEventsTracked = expectation(description: "The expected events were tracked")
        let expectedEvent: WPAnalyticsStat = .loginSocialButtonClick
        let expectedProperties = [
            "source": "google"
        ]
        
        let trackingMethod: LegacyGoogleAuthenticatorTracker.BackingTrackerMethod = { (event, properties) in
            guard event == expectedEvent && properties == expectedProperties else {
                XCTFail()
                return
            }
            
            expectedEventsTracked.fulfill()
        }
        let tracker = LegacyGoogleAuthenticatorTracker(track: trackingMethod)
        
        tracker.trackLoginButtonTapped()
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testTrackCreateAccountInitiated() {
        let expectedEventsTracked = expectation(description: "The expected events were tracked")
        let expectedEvent: WPAnalyticsStat = .createAccountInitiated
        let expectedProperties = [
            "source": "google"
        ]
        
        let trackingMethod: LegacyGoogleAuthenticatorTracker.BackingTrackerMethod = { (event, properties) in
            guard event == expectedEvent && properties == expectedProperties else {
                XCTFail()
                return
            }
            
            expectedEventsTracked.fulfill()
        }
        let tracker = LegacyGoogleAuthenticatorTracker(track: trackingMethod)
        
        tracker.trackCreateAccountInitiated()
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testTrackSigninSuccess() {
        let expectedEventsTracked = [
            expectation(description: "signedIn tracked"),
            expectation(description: "loginSocialSuccess tracked"),
        ]
        let expectedEvents: [WPAnalyticsStat: XCTestExpectation] = [
            .signedIn: expectedEventsTracked[0],
            .loginSocialSuccess: expectedEventsTracked[1],
        ]
        let expectedProperties = [
            "source": "google"
        ]
        
        let trackingMethod: LegacyGoogleAuthenticatorTracker.BackingTrackerMethod = { (event, properties) in
            guard properties == expectedProperties else {
                XCTFail()
                return
            }
            
            if expectedEvents.keys.contains(event) {
                expectedEvents[event]?.fulfill()
            }
        }
        let tracker = LegacyGoogleAuthenticatorTracker(track: trackingMethod)
        
        tracker.trackSigninSuccess()
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testTrackLoginSocialButtonFailure() {
        let expectedEventTracked = expectation(description: "The expected event was tracked")
        let expectedEvent: WPAnalyticsStat = .loginSocialButtonFailure
        let expectedErrorDescription = "test description"
        let expectedError = NSError(
            domain: "test domain",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey : expectedErrorDescription])
        let expectedProperties = [
            "source": "google",
            "error": expectedErrorDescription,
        ]
        
        let trackingMethod: LegacyGoogleAuthenticatorTracker.BackingTrackerMethod = { (event, properties) in
            guard event == expectedEvent && properties == expectedProperties else {
                XCTFail()
                return
            }
            
            expectedEventTracked.fulfill()
        }
        let tracker = LegacyGoogleAuthenticatorTracker(track: trackingMethod)
        
        tracker.trackLoginButtonFailure(error: expectedError)
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testTrackSignupSocialButtonFailure() {
        let expectedEventTracked = expectation(description: "The expected event was tracked")
        let expectedEvent: WPAnalyticsStat = .signupSocialButtonFailure
        let expectedErrorDescription = "test description"
        let expectedError = NSError(
            domain: "test domain",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey : expectedErrorDescription])
        let expectedProperties = [
            "source": "google",
            "error": expectedErrorDescription,
        ]
        
        let trackingMethod: LegacyGoogleAuthenticatorTracker.BackingTrackerMethod = { (event, properties) in
            guard event == expectedEvent && properties == expectedProperties else {
                XCTFail()
                return
            }
            
            expectedEventTracked.fulfill()
        }
        let tracker = LegacyGoogleAuthenticatorTracker(track: trackingMethod)
        
        tracker.trackSignupButtonFailure(error: expectedError)
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testTrackSignupFailure() {
        let expectedEventTracked = expectation(description: "The expected event was tracked")
        let expectedEvent: WPAnalyticsStat = .signupSocialFailure
        let expectedErrorDescription = "test description"
        let expectedError = NSError(
            domain: "test domain",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey : expectedErrorDescription])
        let expectedProperties = [
            "source": "google",
            "error": expectedErrorDescription,
        ]
        
        let trackingMethod: LegacyGoogleAuthenticatorTracker.BackingTrackerMethod = { (event, properties) in
            guard event == expectedEvent && properties == expectedProperties else {
                XCTFail()
                return
            }
            
            expectedEventTracked.fulfill()
        }
        let tracker = LegacyGoogleAuthenticatorTracker(track: trackingMethod)
        
        tracker.trackSignupFailure(error: expectedError)
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testTrackLoginInstead() {
        let expectedEventsTracked = [
            expectation(description: "signedIn tracked"),
            expectation(description: "signupSocialToLogin tracked"),
            expectation(description: "loginSocialSuccess tracked"),
        ]
        let expectedEvents: [WPAnalyticsStat: XCTestExpectation] = [
            .signedIn: expectedEventsTracked[0],
            .signupSocialToLogin: expectedEventsTracked[1],
            .loginSocialSuccess: expectedEventsTracked[2]
        ]
        let expectedProperties = [
            "source": "google"
        ]
        
        let trackingMethod: LegacyGoogleAuthenticatorTracker.BackingTrackerMethod = { (event, properties) in
            guard properties == expectedProperties else {
                XCTFail()
                return
            }
            
            if expectedEvents.keys.contains(event) {
                expectedEvents[event]?.fulfill()
            }
        }
        let tracker = LegacyGoogleAuthenticatorTracker(track: trackingMethod)
        
        tracker.trackLoginInstead()
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testTrackTwoFactorAuhenticationRequested() {
        let expectedEventTracked = expectation(description: "The expected event was tracked")
        let expectedEvent: WPAnalyticsStat = .loginSocial2faNeeded
        let expectedProperties = [
            "source": "google",
        ]
        
        let trackingMethod: LegacyGoogleAuthenticatorTracker.BackingTrackerMethod = { (event, properties) in
            guard event == expectedEvent && properties == expectedProperties else {
                XCTFail()
                return
            }
            
            expectedEventTracked.fulfill()
        }
        let tracker = LegacyGoogleAuthenticatorTracker(track: trackingMethod)
        
        tracker.trackTwoFactorAuhenticationRequested()
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testTrackWPPasswordNeeded() {
        let expectedEventTracked = expectation(description: "The expected event was tracked")
        let expectedEvent: WPAnalyticsStat = .loginSocialAccountsNeedConnecting
        let expectedProperties = [
            "source": "google",
        ]
        
        let trackingMethod: LegacyGoogleAuthenticatorTracker.BackingTrackerMethod = { (event, properties) in
            guard event == expectedEvent && properties == expectedProperties else {
                XCTFail()
                return
            }
            
            expectedEventTracked.fulfill()
        }
        let tracker = LegacyGoogleAuthenticatorTracker(track: trackingMethod)
        
        tracker.trackWPPasswordNeeded()
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testTrackSocialErrorUnknownUser() {
        let expectedEventTracked = expectation(description: "The expected event was tracked")
        let expectedEvent: WPAnalyticsStat = .loginSocialErrorUnknownUser
        let expectedProperties = [
            "source": "google",
        ]
        
        let trackingMethod: LegacyGoogleAuthenticatorTracker.BackingTrackerMethod = { (event, properties) in
            guard event == expectedEvent && properties == expectedProperties else {
                XCTFail()
                return
            }
            
            expectedEventTracked.fulfill()
        }
        let tracker = LegacyGoogleAuthenticatorTracker(track: trackingMethod)
        
        tracker.trackSocialErrorUnknownUser()
        
        waitForExpectations(timeout: 0.1)
    }

    func testTrackAccountCreated() {
        let expectedEventsTracked = [
            expectation(description: "createdAccount tracked"),
            expectation(description: "signedIn tracked"),
            expectation(description: "signupSocialSuccess tracked"),
        ]
        let expectedEvents: [WPAnalyticsStat: XCTestExpectation] = [
            .createdAccount: expectedEventsTracked[0],
            .signedIn: expectedEventsTracked[1],
            .signupSocialSuccess: expectedEventsTracked[2]
        ]
        let expectedProperties = [
            "source": "google"
        ]
        
        let trackingMethod: LegacyGoogleAuthenticatorTracker.BackingTrackerMethod = { (event, properties) in
            guard properties == expectedProperties else {
                XCTFail()
                return
            }
            
            if expectedEvents.keys.contains(event) {
                expectedEvents[event]?.fulfill()
            }
        }
        let tracker = LegacyGoogleAuthenticatorTracker(track: trackingMethod)
        
        tracker.trackAccountCreated()
        
        waitForExpectations(timeout: 0.1)
    }
}
