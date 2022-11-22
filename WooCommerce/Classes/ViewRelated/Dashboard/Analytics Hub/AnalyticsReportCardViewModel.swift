import Foundation
import class UIKit.UIColor

/// Analytics Hub Report Card ViewModel.
/// Used to transmit analytics report data.
///
struct ReportCardViewModel {
    /// Report Card Title.
    ///
    let title: String

    /// First Column Title
    ///
    let leadingTitle: String

    /// First Column Value
    ///
    let leadingValue: String

    /// First Column Delta Value
    ///
    let leadingDelta: String

    /// First Column delta background color.
    ///
    let leadingDeltaColor: UIColor

    /// Second Column Titlke
    ///
    let trailingTitle: String

    /// Second Column Value
    ///
    let trailingValue: String

    /// Second Column Delta Value
    ///
    let trailingDelta: String

    /// Second Column Delta Background Color
    ///
    let trailingDeltaColor: UIColor
}
