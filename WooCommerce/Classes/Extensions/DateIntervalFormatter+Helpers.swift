import Foundation

/// DateIntervalFormatter Extensions
///
extension DateIntervalFormatter {

    /// Date interval formatter used for creating a medium-length **localized** date string to be displayed anywhere.
    ///
    /// Example output: "Jan 2 - 3, 2020"
    /// Example output: "Jan 2 2020 - Feb 10 2022"
    ///
    public static let mediumLengthLocalizedDateIntervalFormatter: DateIntervalFormatter = {
        let dateIntervalFormatter = DateIntervalFormatter()
        dateIntervalFormatter.dateTemplate = "MMMdyyyy"

        return dateIntervalFormatter
    }()
}
