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
        let exportDirectory = temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: exportDirectory, withIntermediateDirectories: true)

        let archiveURL = exportDirectory.appendingPathComponent("woocommerce-logs.zip")

        do {
            let entries = try logFileURLs.map { url in
                ZipEntry(
                    name: url.lastPathComponent,
                    data: try Data(contentsOf: url),
                    modificationDate: modificationDate(for: url)
                )
            }
            try ZipArchive(entries: entries).data.write(to: archiveURL, options: .atomic)
            return archiveURL
        } catch {
            try? fileManager.removeItem(at: exportDirectory)
            throw error
        }
    }

    private func modificationDate(for url: URL) -> Date {
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        return attributes?[.modificationDate] as? Date ?? Date()
    }
}

private struct ZipEntry {
    let name: String
    let data: Data
    let modificationDate: Date
}

/// Minimal ZIP writer using uncompressed entries. Application logs are already plain text and small,
/// so storing them directly avoids adding another dependency solely for archive creation.
///
private struct ZipArchive {
    let entries: [ZipEntry]

    var data: Data {
        get throws {
            var archive = Data()
            var centralDirectory = Data()

            for entry in entries {
                let localHeaderOffset = try UInt32(exactly: archive.count).unwrapOrThrowZipTooLarge()
                let name = Data(entry.name.utf8)
                let nameLength = try UInt16(exactly: name.count).unwrapOrThrowZipTooLarge()
                let size = try UInt32(exactly: entry.data.count).unwrapOrThrowZipTooLarge()
                let checksum = entry.data.crc32
                let timestamp = entry.modificationDate.dosTimestamp

                archive.appendLittleEndian(UInt32(0x04034b50))
                archive.appendLittleEndian(UInt16(20))
                archive.appendLittleEndian(UInt16(0x0800))
                archive.appendLittleEndian(UInt16(0))
                archive.appendLittleEndian(timestamp.time)
                archive.appendLittleEndian(timestamp.date)
                archive.appendLittleEndian(checksum)
                archive.appendLittleEndian(size)
                archive.appendLittleEndian(size)
                archive.appendLittleEndian(nameLength)
                archive.appendLittleEndian(UInt16(0))
                archive.append(name)
                archive.append(entry.data)

                centralDirectory.appendLittleEndian(UInt32(0x02014b50))
                centralDirectory.appendLittleEndian(UInt16(20))
                centralDirectory.appendLittleEndian(UInt16(20))
                centralDirectory.appendLittleEndian(UInt16(0x0800))
                centralDirectory.appendLittleEndian(UInt16(0))
                centralDirectory.appendLittleEndian(timestamp.time)
                centralDirectory.appendLittleEndian(timestamp.date)
                centralDirectory.appendLittleEndian(checksum)
                centralDirectory.appendLittleEndian(size)
                centralDirectory.appendLittleEndian(size)
                centralDirectory.appendLittleEndian(nameLength)
                centralDirectory.appendLittleEndian(UInt16(0))
                centralDirectory.appendLittleEndian(UInt16(0))
                centralDirectory.appendLittleEndian(UInt16(0))
                centralDirectory.appendLittleEndian(UInt16(0))
                centralDirectory.appendLittleEndian(UInt32(0))
                centralDirectory.appendLittleEndian(localHeaderOffset)
                centralDirectory.append(name)
            }

            let entryCount = try UInt16(exactly: entries.count).unwrapOrThrowZipTooLarge()
            let centralDirectoryOffset = try UInt32(exactly: archive.count).unwrapOrThrowZipTooLarge()
            let centralDirectorySize = try UInt32(exactly: centralDirectory.count).unwrapOrThrowZipTooLarge()
            archive.append(centralDirectory)
            archive.appendLittleEndian(UInt32(0x06054b50))
            archive.appendLittleEndian(UInt16(0))
            archive.appendLittleEndian(UInt16(0))
            archive.appendLittleEndian(entryCount)
            archive.appendLittleEndian(entryCount)
            archive.appendLittleEndian(centralDirectorySize)
            archive.appendLittleEndian(centralDirectoryOffset)
            archive.appendLittleEndian(UInt16(0))
            return archive
        }
    }
}

private enum ZipArchiveError: Error {
    case archiveTooLarge
}

private extension Optional where Wrapped: FixedWidthInteger {
    func unwrapOrThrowZipTooLarge() throws -> Wrapped {
        guard let self else {
            throw ZipArchiveError.archiveTooLarge
        }
        return self
    }
}

private extension Data {
    mutating func appendLittleEndian<Integer: FixedWidthInteger>(_ value: Integer) {
        var value = value.littleEndian
        Swift.withUnsafeBytes(of: &value) { bytes in
            append(contentsOf: bytes)
        }
    }

    var crc32: UInt32 {
        var checksum = UInt32.max
        for byte in self {
            checksum ^= UInt32(byte)
            for _ in 0..<8 {
                let mask = 0 &- (checksum & 1)
                checksum = (checksum >> 1) ^ (0xedb88320 & mask)
            }
        }
        return ~checksum
    }
}

private extension Date {
    var dosTimestamp: (time: UInt16, date: UInt16) {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: .current, from: self)
        let year = max(1980, min(2107, components.year ?? 1980))
        let month = components.month ?? 1
        let day = components.day ?? 1
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0
        let time = UInt16(hour << 11 | minute << 5 | second / 2)
        let date = UInt16((year - 1980) << 9 | month << 5 | day)
        return (time, date)
    }
}
