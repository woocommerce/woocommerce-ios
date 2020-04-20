
import Foundation

extension Calendar {
    init(identifier: Identifier, timeZone: TimeZone) {
        self.init(identifier: identifier)
        self.timeZone = timeZone
    }
}
