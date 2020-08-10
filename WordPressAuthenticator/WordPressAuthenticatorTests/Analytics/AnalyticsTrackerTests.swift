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
        let flow = AuthenticatorAnalyticsTracker.Flow.googleLogin
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
        
        let tracker = AuthenticatorAnalyticsTracker(track: track)
        
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
        let flow = AuthenticatorAnalyticsTracker.Flow.googleLogin
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
        
        let tracker = AuthenticatorAnalyticsTracker(track: track)
        
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
        let flow = AuthenticatorAnalyticsTracker.Flow.googleLogin
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
        
        let tracker = AuthenticatorAnalyticsTracker(track: track)
        
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
        let flow = AuthenticatorAnalyticsTracker.Flow.googleLogin
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
        
        let tracker = AuthenticatorAnalyticsTracker(track: track)
        
        tracker.set(source: source)
        tracker.set(flow: flow)
        tracker.track(step: step)
        tracker.track(click: click)
        
        waitForExpectations(timeout: 0.1)
    }
}
