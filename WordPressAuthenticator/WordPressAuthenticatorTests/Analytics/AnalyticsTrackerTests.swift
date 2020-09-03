import XCTest
@testable import WordPressAuthenticator

class AnalyticsTrackerTests: XCTestCase {
    
    // MARK: - Expectations: Building the properties dictionary
    
    private func expectedProperties(source: AuthenticatorAnalyticsTracker.Source, flow: AuthenticatorAnalyticsTracker.Flow, step: AuthenticatorAnalyticsTracker.Step) -> [String: String] {
        
        return [
            AuthenticatorAnalyticsTracker.Property.source.rawValue: source.rawValue,
            AuthenticatorAnalyticsTracker.Property.flow.rawValue: flow.rawValue,
            AuthenticatorAnalyticsTracker.Property.step.rawValue: step.rawValue
        ]
    }
    
    private func expectedProperties(source: AuthenticatorAnalyticsTracker.Source, flow: AuthenticatorAnalyticsTracker.Flow, step: AuthenticatorAnalyticsTracker.Step, failure: String) -> [String: String] {
        
        var properties = expectedProperties(source: source, flow: flow, step: step)
        properties[AuthenticatorAnalyticsTracker.Property.failure.rawValue] = failure
        
        return properties
    }
    
    private func expectedProperties(source: AuthenticatorAnalyticsTracker.Source, flow: AuthenticatorAnalyticsTracker.Flow, step: AuthenticatorAnalyticsTracker.Step, click: AuthenticatorAnalyticsTracker.ClickTarget) -> [String: String] {
        
        var properties = expectedProperties(source: source, flow: flow, step: step)
        properties[AuthenticatorAnalyticsTracker.Property.click.rawValue] = click.rawValue
        
        return properties
    }
    
    /// Test that when tracking an event through the AnalyticsTracker, the backing analytics tracker
    /// receives a matching event.
    ///
    /// Ref: pbArwn-AP-p2
    ///
    func testEventTracking() {
        let source = AuthenticatorAnalyticsTracker.Source.reauthentication
        let flow = AuthenticatorAnalyticsTracker.Flow.loginWithGoogle
        let step = AuthenticatorAnalyticsTracker.Step.start
        
        let expectedEventName = AuthenticatorAnalyticsTracker.EventType.step.rawValue
        let expectedEventProperties = self.expectedProperties(source: source, flow: flow, step: step)
        let trackingIsOk = expectation(description: "The parameters of the tracking call are as expected")
        
        let track = { (event: AnalyticsEvent) in
            if event.name == expectedEventName
                && event.properties == expectedEventProperties {
                
                trackingIsOk.fulfill()
            }
        }
        
        let configuration = AuthenticatorAnalyticsTracker.Configuration(appleEnabled: false, googleEnabled: true, iCloudKeychainEnabled: false, prologueEnabled: false, siteAddressEnabled: false, wpComEnabled: false)
        let tracker = AuthenticatorAnalyticsTracker(configuration: configuration, track: track)
        
        tracker.set(source: source)
        tracker.set(flow: flow)
        tracker.track(step: step)
        
        waitForExpectations(timeout: 0.1)
    }
    
    /// Test that when tracking an event through the AnalyticsTracker, the backing analytics tracker
    /// receives a matching event.
    ///
    func testBackingTracker() {
        let source = AuthenticatorAnalyticsTracker.Source.reauthentication
        let flow = AuthenticatorAnalyticsTracker.Flow.loginWithGoogle
        let step = AuthenticatorAnalyticsTracker.Step.start
        
        let expectedEventName = AuthenticatorAnalyticsTracker.EventType.step.rawValue
        let expectedEventProperties = self.expectedProperties(source: source, flow: flow, step: step)
        let trackingIsOk = expectation(description: "The parameters of the tracking call are as expected")
        
        let track = { (event: AnalyticsEvent) in
            if event.name == expectedEventName
                && event.properties == expectedEventProperties {
                
                trackingIsOk.fulfill()
            }
        }
        
        let configuration = AuthenticatorAnalyticsTracker.Configuration(appleEnabled: false, googleEnabled: true, iCloudKeychainEnabled: false, prologueEnabled: false, siteAddressEnabled: false, wpComEnabled: false)
        let tracker = AuthenticatorAnalyticsTracker(configuration: configuration, track: track)
        
        tracker.set(source: source)
        tracker.set(flow: flow)
        tracker.track(step: step)
        
        waitForExpectations(timeout: 0.1)
    }
    
    /// Test that tracking a failure maintains the source, flow and step from the previously recorded step.
    ///
    /// Ref: pbArwn-I6-p2
    ///
    func testFailure() {
        let source = AuthenticatorAnalyticsTracker.Source.default
        let flow = AuthenticatorAnalyticsTracker.Flow.loginWithGoogle
        let step = AuthenticatorAnalyticsTracker.Step.start
        let failure = "some error"
        
        let expectedEventName = AuthenticatorAnalyticsTracker.EventType.failure.rawValue
        let expectedEventProperties = self.expectedProperties(source: source, flow: flow, step: step, failure: failure)
        let trackingIsOk = expectation(description: "The parameters of the tracking call are as expected")
        
        let track = { (event: AnalyticsEvent) in
            // We'll ignore the first event and only check the properties from the failure.
            if event.name == expectedEventName
                && event.properties == expectedEventProperties {
                
                trackingIsOk.fulfill()
            }
        }

        let configuration = AuthenticatorAnalyticsTracker.Configuration(appleEnabled: false, googleEnabled: true, iCloudKeychainEnabled: false, prologueEnabled: false, siteAddressEnabled: false, wpComEnabled: false)
        let tracker = AuthenticatorAnalyticsTracker(configuration: configuration, track: track)
        
        tracker.set(source: source)
        tracker.set(flow: flow)
        tracker.track(step: step)
        tracker.track(failure: failure)
        
        waitForExpectations(timeout: 0.1)
    }
    
    /// Test that tracking a click maintains the source, flow and step from the previously recorded step.
    ///
    /// Ref: pbArwn-I6-p2
    ///
    func testClick() {
        let source = AuthenticatorAnalyticsTracker.Source.default
        let flow = AuthenticatorAnalyticsTracker.Flow.loginWithGoogle
        let step = AuthenticatorAnalyticsTracker.Step.start
        let click = AuthenticatorAnalyticsTracker.ClickTarget.dismiss
        
        let expectedEventName = AuthenticatorAnalyticsTracker.EventType.interaction.rawValue
        let expectedEventProperties = self.expectedProperties(source: source, flow: flow, step: step, click: click)
        let trackingIsOk = expectation(description: "The parameters of the tracking call are as expected")
        
        let track = { (event: AnalyticsEvent) in
            // We'll ignore the first event and only check the properties from the failure.
            if event.name == expectedEventName
                && event.properties == expectedEventProperties {
                
                trackingIsOk.fulfill()
            }
        }
        
        let configuration = AuthenticatorAnalyticsTracker.Configuration(appleEnabled: false, googleEnabled: true, iCloudKeychainEnabled: false, prologueEnabled: false, siteAddressEnabled: false, wpComEnabled: false)
        let tracker = AuthenticatorAnalyticsTracker(configuration: configuration, track: track)
        
        tracker.set(source: source)
        tracker.set(flow: flow)
        tracker.track(step: step)
        tracker.track(click: click)
        
        waitForExpectations(timeout: 0.1)
    }
    
    // MARK: - Legacy Tracking Support Tests
    
    /// Tests legacy tracking for a step
    ///
    func testStepLegacyTracking() {
        let source = AuthenticatorAnalyticsTracker.Source.default
        let flows: [AuthenticatorAnalyticsTracker.Flow] = [.loginWithApple, .signupWithApple, .loginWithGoogle, .signupWithGoogle, .loginWithSiteAddress]
        let step = AuthenticatorAnalyticsTracker.Step.start
        
        let legacyTrackingExecuted = expectation(description: "The legacy tracking block was executed.")
        legacyTrackingExecuted.expectedFulfillmentCount = flows.count
        
        let track = { (event: AnalyticsEvent) in
            XCTFail()
        }
        
        let configuration = AuthenticatorAnalyticsTracker.Configuration(appleEnabled: false, googleEnabled: false, iCloudKeychainEnabled: false, prologueEnabled: false, siteAddressEnabled: false, wpComEnabled: false)
        let tracker = AuthenticatorAnalyticsTracker(configuration: configuration, track: track)
        
        tracker.set(source: source)
        
        for flow in flows {
            tracker.set(flow: flow)
            tracker.track(step: step, ifTrackingNotEnabled: {
                legacyTrackingExecuted.fulfill()
            })
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    /// Tests the new  tracking for a step
    ///
    func testStepNewTracking() {
        let source = AuthenticatorAnalyticsTracker.Source.default
        let flows: [AuthenticatorAnalyticsTracker.Flow] = [.loginWithApple, .signupWithApple, .loginWithGoogle, .signupWithGoogle, .loginWithSiteAddress]
        let step = AuthenticatorAnalyticsTracker.Step.start
        
        let legacyTrackingExecuted = expectation(description: "The legacy tracking block was executed.")
        legacyTrackingExecuted.expectedFulfillmentCount = flows.count
        
        let track = { (event: AnalyticsEvent) in
            legacyTrackingExecuted.fulfill()
        }
        
        let configuration = AuthenticatorAnalyticsTracker.Configuration(appleEnabled: true, googleEnabled: true, iCloudKeychainEnabled: false, prologueEnabled: false, siteAddressEnabled: true, wpComEnabled: false)
        let tracker = AuthenticatorAnalyticsTracker(configuration: configuration, track: track)
        
        tracker.set(source: source)
        
        for flow in flows {
            tracker.set(flow: flow)
            tracker.track(step: step, ifTrackingNotEnabled: {
                XCTFail()
            })
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    /// Tests legacy tracking for a click interaction
    ///
    func testClickLegacyTracking() {
        let source = AuthenticatorAnalyticsTracker.Source.default
        let flows: [AuthenticatorAnalyticsTracker.Flow] = [.loginWithApple, .signupWithApple, .loginWithGoogle, .signupWithGoogle, .loginWithSiteAddress]
        let click = AuthenticatorAnalyticsTracker.ClickTarget.connectSite
        
        let legacyTrackingExecuted = expectation(description: "The legacy tracking block was executed.")
        legacyTrackingExecuted.expectedFulfillmentCount = flows.count
        
        let track = { (event: AnalyticsEvent) in
            XCTFail()
        }
        
        let configuration = AuthenticatorAnalyticsTracker.Configuration(appleEnabled: false, googleEnabled: false, iCloudKeychainEnabled: false, prologueEnabled: false, siteAddressEnabled: false, wpComEnabled: false)
        let tracker = AuthenticatorAnalyticsTracker(configuration: configuration, track: track)
        
        tracker.set(source: source)
        
        for flow in flows {
            tracker.set(flow: flow)
            tracker.track(click: click, ifTrackingNotEnabled: {
                legacyTrackingExecuted.fulfill()
            })
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    /// Tests the new  tracking for a click interaction
    ///
    func testClickNewTracking() {
        let source = AuthenticatorAnalyticsTracker.Source.default
        let flows: [AuthenticatorAnalyticsTracker.Flow] = [.loginWithApple, .signupWithApple, .loginWithGoogle, .signupWithGoogle, .loginWithSiteAddress]
        let click = AuthenticatorAnalyticsTracker.ClickTarget.connectSite
        
        let legacyTrackingExecuted = expectation(description: "The legacy tracking block was executed.")
        legacyTrackingExecuted.expectedFulfillmentCount = flows.count
        
        let track = { (event: AnalyticsEvent) in
            legacyTrackingExecuted.fulfill()
        }
        
        let configuration = AuthenticatorAnalyticsTracker.Configuration(appleEnabled: true, googleEnabled: true, iCloudKeychainEnabled: false, prologueEnabled: false, siteAddressEnabled: true, wpComEnabled: false)
        let tracker = AuthenticatorAnalyticsTracker(configuration: configuration, track: track)
        
        tracker.set(source: source)
        
        for flow in flows {
            tracker.set(flow: flow)
            tracker.track(click: click, ifTrackingNotEnabled: {
                XCTFail()
            })
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    /// Tests legacy tracking for a failure
    ///
    func testFailureLegacyTracking() {
        let source = AuthenticatorAnalyticsTracker.Source.default
        let flows: [AuthenticatorAnalyticsTracker.Flow] = [.loginWithApple, .signupWithApple, .loginWithGoogle, .signupWithGoogle, .loginWithSiteAddress]
        
        let legacyTrackingExecuted = expectation(description: "The legacy tracking block was executed.")
        legacyTrackingExecuted.expectedFulfillmentCount = flows.count
        
        let track = { (event: AnalyticsEvent) in
            XCTFail()
        }
        
        let configuration = AuthenticatorAnalyticsTracker.Configuration(appleEnabled: false, googleEnabled: false, iCloudKeychainEnabled: false, prologueEnabled: false, siteAddressEnabled: false, wpComEnabled: false)
        let tracker = AuthenticatorAnalyticsTracker(configuration: configuration, track: track)
        
        tracker.set(source: source)
        
        for flow in flows {
            tracker.set(flow: flow)
            tracker.track(failure: "error", ifTrackingNotEnabled: {
                legacyTrackingExecuted.fulfill()
            })
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    /// Tests the new  tracking for a failure
    ///
    func testFailureNewTracking() {
        let source = AuthenticatorAnalyticsTracker.Source.default
        let flows: [AuthenticatorAnalyticsTracker.Flow] = [.loginWithApple, .signupWithApple, .loginWithGoogle, .signupWithGoogle, .loginWithSiteAddress]
        
        let legacyTrackingExecuted = expectation(description: "The legacy tracking block was executed.")
        legacyTrackingExecuted.expectedFulfillmentCount = flows.count
        
        let track = { (event: AnalyticsEvent) in
            legacyTrackingExecuted.fulfill()
        }
        
        let configuration = AuthenticatorAnalyticsTracker.Configuration(appleEnabled: true, googleEnabled: true, iCloudKeychainEnabled: false, prologueEnabled: false, siteAddressEnabled: true, wpComEnabled: false)
        let tracker = AuthenticatorAnalyticsTracker(configuration: configuration, track: track)
        
        tracker.set(source: source)
        
        for flow in flows {
            tracker.set(flow: flow)
            tracker.track(failure: "error", ifTrackingNotEnabled: {
                XCTFail()
            })
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    /// Tests that we're using legacy tracking for all unsupported flows.
    ///
    func testStepLegacyTrackingForAllUnsupportedFlows() {
        let flows: [AuthenticatorAnalyticsTracker.Flow] = [.loginWithiCloudKeychain, .loginWithPassword, .loginWithMagicLink, .signup, .wpCom]
        
        let legacyTrackingUsed = expectation(description: "All unsupported flows should use legacy tracking")
        legacyTrackingUsed.expectedFulfillmentCount = flows.count
        
        let track = { (event: AnalyticsEvent) in
            XCTFail()
        }
        
        let configuration = AuthenticatorAnalyticsTracker.Configuration(appleEnabled: true, googleEnabled: true, iCloudKeychainEnabled: false, prologueEnabled: false, siteAddressEnabled: true, wpComEnabled: false)
        let tracker = AuthenticatorAnalyticsTracker(configuration: configuration, track: track)
        
        for flow in flows {
            tracker.set(flow: flow)
            tracker.track(step: .start, ifTrackingNotEnabled: {
                legacyTrackingUsed.fulfill()
            })
        }
        
        waitForExpectations(timeout: 0.1)
    }
}
