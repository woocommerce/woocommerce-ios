/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data object that holds a single image and its metadata.
*/
import Combine
import Foundation
import os

private let logger = Logger(subsystem: "com.apple.sample.CaptureSample",
                            category: "CaptureInfo")

/// This is a lightweight data object that holds a single capture sample, a reference to its capture directory,
/// and any metadata saved with the image.
struct CaptureInfo: Identifiable {
    /// This helper data object tracks whether associated files exist in the file system.
    struct FileExistence {
        var image: Bool = false
        var depth: Bool = false
        var gravity: Bool = false
    }

    enum Error: Swift.Error {
        case invalidPhotoString
        case noSuchDirectory(URL)
    }

    static let imageSuffix: String = ".HEIC"

    /// This is a unique identifier for the capture sample.
    let id: UInt32

    /// This is a URL pointing to the sample's parent directory.
    let captureDir: URL

    init(id: UInt32, captureDir: URL) {
        self.id = id
        self.captureDir = captureDir
    }

    var photoIdString: String {
        return CaptureInfo.photoIdString(for: id)
    }

    var imageUrl: URL {
        return CaptureInfo.imageUrl(in: captureDir, id: id)
    }

    var depthUrl: URL {
        return CaptureInfo.depthUrl(in: captureDir, id: id)
    }

    var gravityUrl: URL {
        return CaptureInfo.gravityUrl(in: captureDir, id: id)
    }

    /// This method checks for the existence of the image and metadata files associated with this capture.
    /// This method uses a `Promise` instance to return the data asynchronously once it has finished
    /// checking.
    func checkFilesExist() -> Future<FileExistence, CaptureInfo.Error> {
        let future = Future<FileExistence, CaptureInfo.Error> { promise in
            CaptureInfo.loaderQueue.async {
                guard CaptureInfo.doesDirectoryExist(url: captureDir) else {
                    logger.error("checkFilesExist: can't find dir \(captureDir)!")
                    promise(.failure(CaptureInfo.Error.noSuchDirectory(captureDir)))
                    return
                }
                do {
                    let existence = try CaptureInfo.checkFilesExist(inFolder: captureDir, id: id)
                    promise(.success(existence))
                } catch {
                    logger.error("checkFilesExist: error \(String(describing: error))!")
                    promise(.failure(CaptureInfo.Error.noSuchDirectory(captureDir)))
                }
            }
        }
        return future
    }

    /// This method deletes all associated metadata files synchronously. Don't call this method
    /// on the main thread.
    func deleteAllFiles() {
        dispatchPrecondition(condition: .notOnQueue(.main))
        deleteHelper(delete: imageUrl, fileType: "image")
        deleteHelper(delete: depthUrl, fileType: "depth")
        deleteHelper(delete: gravityUrl, fileType: "gravity")
    }

    private func deleteHelper(delete: URL, fileType: String) {
        do {
            logger.log("Deleting \(fileType) at \"\(delete.path)\"...")
            try FileManager.default.removeItem(atPath: delete.path)
            logger.log("... deleted \"\(delete.path)\".")
        } catch {
            logger.error("Can't delete \(fileType) \"\(delete.path)\" error=\(String(describing: error))")
        }
    }

    /// This method synchronously checks which data files already exist in a specified capture directory.
    static func checkFilesExist(inFolder captureDir: URL, id: UInt32) throws -> FileExistence {
        dispatchPrecondition(condition: .notOnQueue(DispatchQueue.main))

        guard CaptureInfo.doesDirectoryExist(url: captureDir) else {
            throw Error.noSuchDirectory(captureDir)
        }

        var result = FileExistence()
        result.image = FileManager.default.fileExists(atPath: imageUrl(in: captureDir, id: id).path)
        result.depth = FileManager.default.fileExists(atPath: depthUrl(in: captureDir, id: id).path)
        result.gravity = FileManager.default.fileExists(
            atPath: gravityUrl(in: captureDir, id: id).path)
        return result
    }

    static private func doesDirectoryExist(url: URL) -> Bool {
        guard url.isFileURL else { return false }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path,
                                             isDirectory: &isDirectory) else {
            return false
        }
        return isDirectory.boolValue
    }

    /// This method extracts the image `id` out of a previously created `photoIdString`.
    /// It throws an exception if `photoString` isn't valid or it can't extract an ID.
    static func extractId(from photoString: String) throws -> UInt32 {
        guard let endOfPrefix = photoString.lastIndex(of: "_") else {
            throw Error.invalidPhotoString
        }
        let imgPrefix = photoString[...endOfPrefix]
        guard imgPrefix == CaptureInfo.photoStringPrefix else {
            throw Error.invalidPhotoString
        }
        guard let id = UInt32(photoString[photoString.index(after: endOfPrefix)...]) else {
            throw Error.invalidPhotoString
        }
        return id
    }

    /// This method returns the base name for a capture. It's based on the capture's unique identifier.
    static func photoIdString(for id: UInt32) -> String {
        return String(format: "%@%04d", photoStringPrefix, id)
    }

    static func photoIdString(from imageUrl: URL) throws -> String {
        let basename = imageUrl.lastPathComponent
        guard basename.hasSuffix(imageSuffix), let suffixStartIndex = basename.lastIndex(of: ".") else {
            throw Error.invalidPhotoString
        }
        return String(basename[..<suffixStartIndex])
    }

    /// This method returns the file URL for the image data relative to a specified directory.
    static func imageUrl(in captureDir: URL, id: UInt32) -> URL {
        return captureDir.appendingPathComponent(photoIdString(for: id).appending(imageSuffix))
    }

    /// This method returns the file URL for the gravity data relative to a specified directory.
    static func gravityUrl(in captureDir: URL, id: UInt32) -> URL {
        return captureDir.appendingPathComponent(photoIdString(for: id).appending("_gravity.TXT"))
    }

    /// This method returns the file URL for the depth data relative to a specified directory.
    static func depthUrl(in captureDir: URL, id: UInt32) -> URL {
        return captureDir.appendingPathComponent(photoIdString(for: id).appending("_depth.TIF"))
    }

    /// `CaptureInfo` uses this serial queue for all file system access.
    private static let loaderQueue =
        DispatchQueue(label: "com.apple.example.CaptureSample.CaptureInfo.loaderQueue",
                      qos: .userInitiated)

    /// `CaptureInfo` uses this string prefix to create a file base name.
    private static let photoStringPrefix = "IMG_"
}
