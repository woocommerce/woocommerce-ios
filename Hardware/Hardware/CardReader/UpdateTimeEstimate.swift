/// The estimated amount of time for an update.
/// Note that these times are estimates; actual times may vary depending on your network connection.
public enum UpdateTimeEstimate {
    /// The update should take less than 1 minute to complete.
    case lessThanOneMinute

    /// The update should take 1-2 minutes to complete.
    case betweenOneAndTwoMinutes

    /// The update should take 2-5 minutes to complete.
    case betweenTwoAndFiveMinutes

    /// The update should take 5-15 minutes to complete.
    case betweenFiveAndFifteenMinutes

    /// Call 911. We don't know how long this will take.
    case indeterminate
}
