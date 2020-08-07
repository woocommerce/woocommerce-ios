import XCTest
@testable import WordPressAuthenticator

class AnalyticsTrackerTests: XCTestCase {
    
    // MARK: - Expectations: Building the properties dictionary
    
    private func expectedProperties(source: AnalyticsTracker.Source, flow: AnalyticsTracker.Flow, step: AnalyticsTracker.Step) -> [String: String] {
        
        return [
            AnalyticsTracker.Property.source.rawValue: source.rawValue,
            AnalyticsTracker.Property.flow.rawValue: flow.rawValue,
            AnalyticsTracker.Property.step.rawValue: step.rawValue
        ]
    }
    
    private func expectedProperties(source: AnalyticsTracker.Source, flow: AnalyticsTracker.Flow, step: AnalyticsTracker.Step, failure: String) -> [String: String] {
        
        var properties = expectedProperties(source: source, flow: flow, step: step)
        properties[AnalyticsTracker.Property.failure.rawValue] = failure
        
        return properties
    }
    
    private func expectedProperties(source: AnalyticsTracker.Source, flow: AnalyticsTracker.Flow, step: AnalyticsTracker.Step, click: AnalyticsTracker.ClickTarget) -> [String: String] {
        
        var properties = expectedProperties(source: source, flow: flow, step: step)
        properties[AnalyticsTracker.Property.click.rawValue] = click.rawValue
        
        return properties
    }
    
    /// Test that when tracking an event through the AnalyticsTracker, the backing analytics tracker
    /// receives a matching event.
    ///
    /// Ref: pbArwn-AP-p2
    ///
    func testEventTracking() {
        let source = AnalyticsTracker.Source.reauthentication
        let flow = AnalyticsTracker.Flow.googleLogin
        let step = AnalyticsTracker.Step.start
        
        let expectedEventName = AnalyticsTracker.EventType.step.rawValue
        let expectedEventProperties = self.expectedProperties(source: source, flow: flow, step: step)
        let trackingIsOk = expectation(description: "The parameters of the tracking call are as expected")
        
        let track = { (event: AnalyticsEvent) in
            if event.name == expectedEventName
                && event.properties == expectedEventProperties {
                
                trackingIsOk.fulfill()
            }
        }
        
        let tracker = AnalyticsTracker(track: track)
        
        tracker.set(source: source)
        tracker.set(flow: flow)
        tracker.track(step: step)
        
        waitForExpectations(timeout: 0.1)
    }
    
    /// Test that when tracking an event through the AnalyticsTracker, the backing analytics tracker
    /// receives a matching event.
    ///
    func testBackingTracker() {
        let source = AnalyticsTracker.Source.reauthentication
        let flow = AnalyticsTracker.Flow.googleLogin
        let step = AnalyticsTracker.Step.start
        
        let expectedEventName = AnalyticsTracker.EventType.step.rawValue
        let expectedEventProperties = self.expectedProperties(source: source, flow: flow, step: step)
        let trackingIsOk = expectation(description: "The parameters of the tracking call are as expected")
        
        let track = { (event: AnalyticsEvent) in
            if event.name == expectedEventName
                && event.properties == expectedEventProperties {
                
                trackingIsOk.fulfill()
            }
        }
        
        let tracker = AnalyticsTracker(track: track)
        
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
        let source = AnalyticsTracker.Source.default
        let flow = AnalyticsTracker.Flow.googleLogin
        let step = AnalyticsTracker.Step.start
        let failure = "some error"
        
        let expectedEventName = AnalyticsTracker.EventType.failure.rawValue
        let expectedEventProperties = self.expectedProperties(source: source, flow: flow, step: step, failure: failure)
        let trackingIsOk = expectation(description: "The parameters of the tracking call are as expected")
        
        let track = { (event: AnalyticsEvent) in
            // We'll ignore the first event and only check the properties from the failure.
            if event.name == expectedEventName
                && event.properties == expectedEventProperties {
                
                trackingIsOk.fulfill()
            }
        }
        
        let tracker = AnalyticsTracker(track: track)
        
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
        let source = AnalyticsTracker.Source.default
        let flow = AnalyticsTracker.Flow.googleLogin
        let step = AnalyticsTracker.Step.start
        let click = AnalyticsTracker.ClickTarget.dismiss
        
        let expectedEventName = AnalyticsTracker.EventType.interaction.rawValue
        let expectedEventProperties = self.expectedProperties(source: source, flow: flow, step: step, click: click)
        let trackingIsOk = expectation(description: "The parameters of the tracking call are as expected")
        
        let track = { (event: AnalyticsEvent) in
            // We'll ignore the first event and only check the properties from the failure.
            if event.name == expectedEventName
                && event.properties == expectedEventProperties {
                
                trackingIsOk.fulfill()
            }
        }
        
        let tracker = AnalyticsTracker(track: track)
        
        tracker.set(source: source)
        tracker.set(flow: flow)
        tracker.track(step: step)
        tracker.track(click: click)
        
        waitForExpectations(timeout: 0.1)
    }
}
