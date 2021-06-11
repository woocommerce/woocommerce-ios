import Foundation
import Combine
import UIKit

struct ApplicationLogLine: Identifiable {
    let id = UUID()

    let date: Date?
    let text: String

    private static let parsingFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss:SSS"
        return dateFormatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    private let datePrefixPattern = try! NSRegularExpression(
        pattern: """
    ^                                       # Match start of the string only
        (                                   # First capture group for the timestamp
            \\d{4}/\\d{2}/\\d{2}            # Date component (YYYY-MM-dd)
            \\s                             # A single whitespace
            \\d{2}:\\d{2}:\\d{2}\\:\\d{3}   # Time component (HH:mm:ss:SSS)
        )                                   # End of first capture group
        \\s+                                # At least one whitespace character, discard this
        (.*)                                # Second capture group: rest of text
""",
        options: [.allowCommentsAndWhitespace]
    )

    init(text: String) {
        guard let result = datePrefixPattern.firstMatch(in: text, options: [], range: NSMakeRange(0, text.utf16.count)),
              let dateRange = Range(result.range(at: 1), in: text),
              let logRange = Range(result.range(at: 2), in: text),
              let date = ApplicationLogLine.parsingFormatter.date(from: String(text[dateRange])) else {
            self.date = nil
            self.text = text
            return
        }

        self.date = date
        self.text = String(text[logRange])
    }

    var dateText: String? {
        date.map(ApplicationLogLine.displayFormatter.string(from:))
    }
}

final class ApplicationLogViewModel: ObservableObject {
    private let logText: String

    let logDate: String

    let lines: [ApplicationLogLine]

    let lastLineID: UUID

    @Published var lastCellIsVisible = false

    @Published var buttonVisible = true

    @Published var shareSheetVisible = false

    private var cancellableSet: Set<AnyCancellable> = []

    init(logText: String, logDate: String) {
        self.logText = logText
        self.logDate = logDate
        lines = logText
            .split(separator: "\n")
            .map(String.init)
            .map(ApplicationLogLine.init(text:))

        // The `ScrollViewProxy.scrollTo` method doesn't seem to handle an optional line well
        // Instead of `nil`, we can represent a missing value with a random UUID
        lastLineID = lines.last?.id ?? UUID()

        guard lines.isNotEmpty else {
            // If the file is empty, there will be no last cell,
            // and so the last cell won't be visible, but it still doesn't make
            // sense to show a button to scroll down
            buttonVisible = false
            return
        }

        $lastCellIsVisible
            .map(!)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .assign(to: \.buttonVisible, on: self)
            .store(in: &cancellableSet)
    }

    func isLastLine(_ line: ApplicationLogLine) -> Bool {
        line.id == lastLineID
    }

    var activityItems: [Any] {
        [logText]
    }

    /// Specifies the activity types that should be excluded.
    /// - returns: all unsupported types
    /// Preserves support for `.copyToPasteboard`, `.mail`, and `.airDrop`
    ///
    var excludedActivityTypes: Set<UIActivity.ActivityType> {
        let activityTypes = Set(SharingHelper.allActivityTypes())
        let supportedTypes: Set<UIActivity.ActivityType> = [
            .copyToPasteboard,
            .mail,
            .airDrop
        ]
        return activityTypes.subtracting(supportedTypes)
    }

    var title: String {
        logDate
    }
}

#if DEBUG
extension ApplicationLogViewModel {
    static var sampleLog: ApplicationLogViewModel {
        return .init(
            logText: """
            2021/06/07 11:59:42:636  📱 Registering for Remote Notifications...
            2021/06/07 11:59:42:661  Zendesk Enabled: true
            2021/06/07 11:59:46:454  🔵 Tracked application_opened
            2021/06/07 11:59:46:455  checkAppleIDCredentialState: No Apple ID found.
            2021/06/07 11:59:46:475  ♻️ Refreshing tracks metadata...
            2021/06/07 11:59:46:477  ♻️ Refreshing tracks metadata...
            2021/06/07 11:59:46:477  🔵 Tracking started.
            2021/06/07 11:59:46:487  ⚠️ Could not successfully decode SiteSetting value for woocommerce_all_except_countries
            2021/06/07 11:59:46:487  ⚠️ Could not successfully decode SiteSetting value for woocommerce_specific_allowed_countries
            2021/06/07 11:59:46:487  ⚠️ Could not successfully decode SiteSetting value for woocommerce_specific_ship_to_countries
            2021/06/07 11:59:46:487  ⚠️ Could not successfully decode SiteSetting value for woocommerce_specific_ship_to_countries
            2021/06/07 11:59:46:487  ⚠️ Could not successfully decode SiteSetting value for woocommerce_specific_ship_to_countries
            2021/06/07 11:59:46:487  ⚠️ Could not successfully decode SiteSetting value for woocommerce_specific_ship_to_countries
            2021/06/07 11:59:46:487  ⚠️ Could not successfully decode SiteSetting value for woocommerce_specific_ship_to_countries
            2021/06/07 11:59:46:487  ⚠️ Could not successfully decode SiteSetting value for woocommerce_specific_ship_to_countries
            """,
            logDate: "Today")
    }
}
#endif
