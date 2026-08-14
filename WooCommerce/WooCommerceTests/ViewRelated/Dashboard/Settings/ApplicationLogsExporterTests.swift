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
        let firstLogData = Data(String(repeating: "current log contents\n", count: 100).utf8)
        let secondLogData = Data(String(repeating: "previous log contents\n", count: 100).utf8)
        try firstLogData.write(to: firstLog)
        try secondLogData.write(to: secondLog)

        // When
        let archiveURL = try ApplicationLogsExporter().export(logFileURLs: [firstLog, secondLog])
        defer { try? fileManager.removeItem(at: archiveURL.deletingLastPathComponent()) }

        // Then
        let archiveData = try Data(contentsOf: archiveURL)
        let archiveText = String(decoding: archiveData, as: UTF8.self)
        #expect(archiveURL.pathExtension == "zip")
        #expect(archiveText.contains("current.log"))
        #expect(archiveText.contains("previous.log"))
        #expect(archiveData.count < firstLogData.count + secondLogData.count)
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
