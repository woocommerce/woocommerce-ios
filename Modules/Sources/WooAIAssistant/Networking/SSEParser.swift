import Foundation

struct SSEParser {
    struct Event: Equatable, Sendable {
        let data: String
    }

    private var buffer = ""
    private var pendingData = ""

    init() {}

    mutating func feed(_ chunk: String) -> [Event] {
        buffer.append(chunk)
        var events: [Event] = []
        while let newlineRange = firstLineBreak(in: buffer) {
            let line = String(buffer[buffer.startIndex..<newlineRange.lowerBound])
            buffer.removeSubrange(buffer.startIndex..<newlineRange.upperBound)
            if let event = processed(line: line) {
                events.append(event)
            }
        }
        return events
    }

    mutating func finish() -> [Event] {
        if !pendingData.isEmpty {
            let event = Event(data: pendingData)
            pendingData = ""
            return [event]
        }
        return []
    }

    private mutating func processed(line: String) -> Event? {
        if line.isEmpty {
            guard !pendingData.isEmpty else { return nil }
            let event = Event(data: pendingData)
            pendingData = ""
            return event
        }
        if line.hasPrefix(":") {
            return nil
        }
        guard let colonIndex = line.firstIndex(of: ":") else {
            return nil
        }
        let field = String(line[line.startIndex..<colonIndex])
        var valueStart = line.index(after: colonIndex)
        if valueStart < line.endIndex, line[valueStart] == " " {
            valueStart = line.index(after: valueStart)
        }
        let value = String(line[valueStart..<line.endIndex])
        if field == "data" {
            if !pendingData.isEmpty {
                pendingData.append("\n")
            }
            pendingData.append(value)
        }
        return nil
    }

    private func firstLineBreak(in string: String) -> Range<String.Index>? {
        // Swift normalizes "\r\n" into one grapheme; check it before the bare \r case.
        // A trailing \r at the very end of the buffer waits for the next chunk so a
        // CRLF split across feeds doesn't produce two events.
        for index in string.indices {
            let ch = string[index]
            if ch == "\r\n" || ch == "\n" {
                return index..<string.index(after: index)
            }
            if ch == "\r" {
                let next = string.index(after: index)
                if next == string.endIndex { return nil }
                return index..<next
            }
        }
        return nil
    }
}
