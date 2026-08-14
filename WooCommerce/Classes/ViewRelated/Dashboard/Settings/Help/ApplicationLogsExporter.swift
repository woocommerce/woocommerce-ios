import Foundation

/// Creates a ZIP archive containing the application log files retained on device.
///
struct ApplicationLogsExporter {
    private let fileManager: FileManager
    private let temporaryDirectory: URL

    init(fileManager: FileManager = .default, temporaryDirectory: URL? = nil) {
        self.fileManager = fileManager
        self.temporaryDirectory = temporaryDirectory ?? fileManager.temporaryDirectory
    }

    func export(logFileURLs: [URL]) throws -> URL {
        let exportDirectory = temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let logsDirectory = exportDirectory.appendingPathComponent("logs", isDirectory: true)
        try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

        do {
            for logFileURL in logFileURLs {
                let destinationURL = logsDirectory.appendingPathComponent(logFileURL.lastPathComponent)
                try fileManager.copyItem(at: logFileURL, to: destinationURL)
            }

            let archiveURL = exportDirectory.appendingPathComponent("woocommerce-logs.zip")
            try createArchive(of: logsDirectory, at: archiveURL)
            try fileManager.removeItem(at: logsDirectory)
            return archiveURL
        } catch {
            try? fileManager.removeItem(at: exportDirectory)
            throw error
        }
    }

    /// Foundation creates a compressed ZIP snapshot when coordinating a directory for uploading.
    /// The snapshot is temporary, so it must be copied inside the accessor block.
    ///
    private func createArchive(of directory: URL, at archiveURL: URL) throws {
        var coordinationError: NSError?
        var archiveError: Error?

        NSFileCoordinator().coordinate(
            readingItemAt: directory,
            options: .forUploading,
            error: &coordinationError
        ) { temporaryArchiveURL in
            do {
                try fileManager.copyItem(at: temporaryArchiveURL, to: archiveURL)
            } catch {
                archiveError = error
            }
        }

        if let coordinationError {
            throw coordinationError
        }
        if let archiveError {
            throw archiveError
        }
    }
}
