import Foundation

/// A valid type that is accepted by Tracks to be used for custom properties.
///
/// Looking at Tracks' UI, the accepted properties are:
///
/// - string
/// - integer
/// - float
/// - boolean
///
protocol WooAnalyticsEventPropertyType {

}

extension String: WooAnalyticsEventPropertyType {

}

extension Int64: WooAnalyticsEventPropertyType {

}

extension Float64: WooAnalyticsEventPropertyType {

}

extension Bool: WooAnalyticsEventPropertyType {

}
