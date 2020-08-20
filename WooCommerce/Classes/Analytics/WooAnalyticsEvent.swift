import Foundation

/// This struct represents an analytics event. It is a combination of `WooAnalyticsStat` and
/// its properties.
///
/// This was mostly created to promote static-typing via constructors.
///
/// ## Adding New Events
///
/// 1. Add the event name (`String`) to `WooAnalyticsStat`.
/// 2. Create an `extension` of `WooAnalyticsStat` if necessary for grouping.
/// 3. Add a `static func` constructor.
///
/// Here is an example:
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
/// Analytics.track(event: .login(step: .start))
/// Analytics.track(event: .loginStart)
/// ~~~
///
public struct WooAnalyticsEvent {
    let statName: WooAnalyticsStat
    let properties: [String: String]

    public init(name: String, properties: [String: String]) {
        self.name = name
        self.properties = properties
    }
}
