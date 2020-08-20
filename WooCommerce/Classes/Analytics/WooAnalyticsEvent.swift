import Foundation

/// This struct represents an analytics event.
///
/// Declaring this class as final is a design choice to promote a simpler usage and implement events
/// through parametrization of the `name` and `properties` properties.
///
/// An example of a static event definition (in the client App or Pod):
///
/// ~~~
/// extension WooAnalyticsEvent {
///     static let loginStart = WooAnalyticsEvent(name: "login", properties: ["step": "start"])
/// }
/// ~~~
///
/// An example of a dynamic / parametrized event definition (in the client App or Pod):
///
/// ~~~
/// extension WooAnalyticsEvent {
///     enum LoginStep: String {
///         case start
///         case success
///     }
///
///     static func login(step: LoginStep) -> WooAnalyticsEvent {
///         let properties = [
///             "step": step.rawValue
///         ]
///
///         return WooAnalyticsEvent(name: "login", properties: properties)
///     }
/// }
/// ~~~
///
/// Examples of tracking calls (in the client App or Pod):
///
/// ~~~
/// WPAnalytics.track(.login(step: .start))
/// WPAnalytics.track(.loginStart)
/// ~~~
///
    let name: String
public struct WooAnalyticsEvent {
    let properties: [String: String]

    public init(name: String, properties: [String: String]) {
        self.name = name
        self.properties = properties
    }
}
