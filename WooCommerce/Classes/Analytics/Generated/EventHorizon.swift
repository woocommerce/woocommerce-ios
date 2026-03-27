public class EventHorizon {

  private let eventSink: (any Trackable) -> Void

  public init(eventSink: @escaping (any Trackable) -> Void) {
    self.eventSink = eventSink
  }

  public func track(_ event: any Trackable) {
    eventSink(event)
  }

}

public protocol Trackable : Hashable, CustomStringConvertible {

  var analyticsName: String { get }
  var analyticsProperties: [String : CustomStringConvertible] { get }

}

public struct EhBookingsTabViewedEvent : Trackable {

  public static let eventName: String = "eh_bookings_tab_viewed"
  public let totalBookingsCount: Int
  public var analyticsName: String {
    return EhBookingsTabViewedEvent.eventName
  }
  public let analyticsProperties: [String : CustomStringConvertible]
  public var description: String {
    var parts: [String] = []
    parts.append("totalBookingsCount: \(totalBookingsCount)")
    return "EhBookingsTabViewedEvent(\(parts.joined(separator: ", ")))"
  }

  public init(totalBookingsCount: Int) {
    self.totalBookingsCount = totalBookingsCount
    var _props: [String : CustomStringConvertible] = [:]
    _props["total_bookings_count"] = totalBookingsCount
    self.analyticsProperties = _props
  }

  public static func ==(lhs: EhBookingsTabViewedEvent, rhs: EhBookingsTabViewedEvent) -> Bool {
    return
      lhs.totalBookingsCount == rhs.totalBookingsCount
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(totalBookingsCount)
  }

}

public struct EhBookingDetailOpenedEvent : Trackable {

  public static let eventName: String = "eh_booking_detail_opened"
  public let bookingId: Int
  public let source: BookingSource
  public let isUpcoming: Bool
  public var analyticsName: String {
    return EhBookingDetailOpenedEvent.eventName
  }
  public let analyticsProperties: [String : CustomStringConvertible]
  public var description: String {
    var parts: [String] = []
    parts.append("bookingId: \(bookingId)")
    parts.append("source: \(source)")
    parts.append("isUpcoming: \(isUpcoming)")
    return "EhBookingDetailOpenedEvent(\(parts.joined(separator: ", ")))"
  }

  public init(
    bookingId: Int,
    source: BookingSource,
    isUpcoming: Bool
  ) {
    self.bookingId = bookingId
    self.source = source
    self.isUpcoming = isUpcoming
    var _props: [String : CustomStringConvertible] = [:]
    _props["booking_id"] = bookingId
    _props["source"] = source.analyticsValue
    _props["is_upcoming"] = isUpcoming
    self.analyticsProperties = _props
  }

  public static func ==(lhs: EhBookingDetailOpenedEvent, rhs: EhBookingDetailOpenedEvent) -> Bool {
    return
      lhs.bookingId == rhs.bookingId &&
      lhs.source == rhs.source &&
      lhs.isUpcoming == rhs.isUpcoming
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(bookingId)
    hasher.combine(source)
    hasher.combine(isUpcoming)
  }

}

public enum BookingSource : String {

  case pushNotification = "push_notification"
  case bookingList = "booking_list"
  case search = "search"

  public var analyticsValue: String {
    return rawValue
  }

}
