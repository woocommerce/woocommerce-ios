import Foundation
import Testing
@testable import WooCommerce

struct ApplicationLogsExporterTests {
    private let fileManager = FileManager.default

    @Test func export_when_multiple_logs_exist_then_zip_contains_all_logs() throws {
        // Given
        let sourceDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: sourceDirectory) }
        let firstLog = sourceDirectory.appendingPathComponent("current.log")
        let secondLog = sourceDirectory.appendingPathComponent("previous.log")
        try Data("current log contents".utf8).write(to: firstLog)
        try Data("previous log contents".utf8).write(to: secondLog)

        // When
        let archiveURL = try ApplicationLogsExporter().export(logFileURLs: [firstLog, secondLog])
        defer { try? fileManager.removeItem(at: archiveURL.deletingLastPathComponent()) }

        // Then
        let entries = try StoredZipArchive(data: Data(contentsOf: archiveURL)).entries
        #expect(entries["current.log"] == Data("current log contents".utf8))
        #expect(entries["previous.log"] == Data("previous log contents".utf8))
    }

    @Test func export_when_a_log_cannot_be_read_then_removes_temporary_export_directory() throws {
        // Given
        let exportParentDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: exportParentDirectory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: exportParentDirectory) }
        let missingLog = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("log")

        // When
        #expect(throws: Error.self) {
            try ApplicationLogsExporter(temporaryDirectory: exportParentDirectory).export(logFileURLs: [missingLog])
        }

        // Then
        let remainingItems = try fileManager.contentsOfDirectory(atPath: exportParentDirectory.path)
        #expect(remainingItems.isEmpty)
    }
}

private struct StoredZipArchive {
    let entries: [String: Data]

    init(data: Data) throws {
        var entries: [String: Data] = [:]
        var offset = 0

        while data.uint32(at: offset) == 0x04034b50 {
            let size = Int(data.uint32(at: offset + 18))
            let nameLength = Int(data.uint16(at: offset + 26))
            let extraLength = Int(data.uint16(at: offset + 28))
            let nameStart = offset + 30
            let nameEnd = nameStart + nameLength
            let contentsStart = nameEnd + extraLength
            let contentsEnd = contentsStart + size
            let name = String(decoding: data[nameStart..<nameEnd], as: UTF8.self)
            entries[name] = Data(data[contentsStart..<contentsEnd])
            offset = contentsEnd
        }

        self.entries = entries
    }
}

private extension Data {
    func uint16(at offset: Int) -> UInt16 {
        UInt16(self[offset]) | UInt16(self[offset + 1]) << 8
    }

    func uint32(at offset: Int) -> UInt32 {
        UInt32(self[offset]) |
        UInt32(self[offset + 1]) << 8 |
        UInt32(self[offset + 2]) << 16 |
        UInt32(self[offset + 3]) << 24
    }
}
