import Foundation
import CocoaLumberjack

/// Type of the local Media directory URL in implementation.
///
enum MediaDirectory {
    /// Default, system Documents directory, for persisting media files for upload.
    case uploads
    /// System Caches directory, for creating discardable media files, such as thumbnails.
    case cache
    /// System temporary directory, used for unit testing or temporary media files.
    case temporary

    /// Returns the directory URL for the directory type.
    ///
    /// - Parameter name: the name of the directory.
    ///
    func directoryURL(name: String) -> URL {
        let fileManager = FileManager.default
        // Gets a parent directory, based on the type.
        let parentDirectory: URL
        switch self {
        case .uploads:
            parentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        case .cache:
            parentDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        case .temporary:
            parentDirectory = fileManager.temporaryDirectory
        }
        return parentDirectory.appendingPathComponent(name, isDirectory: true)
    }
}

/// Encapsulates Media functions related to the local Media directory.
///
final class MediaFileManager {

    private let directory: MediaDirectory

    private let fileManager: FileManager

    /// Init with default directory of .uploads.
    ///
    /// - Note: This is particularly because the original Media directory was in the NSFileManager's documents directory.
    ///   We shouldn't change this default directory lightly as older versions of the app may rely on Media files being in
    ///   the documents directory for upload.
    ///
    init(directory: MediaDirectory = .uploads, fileManager: FileManager = FileManager.default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    /// Returns a unique filesystem URL for a Media filename and extension, within the local Media directory.
    ///
    /// - Note: if a file already exists with the same name, the file name is appended with a number
    ///   and incremented until a unique filename is found.
    ///
    func createLocalMediaURL(filename: String, fileExtension: String?) throws -> URL {
        let baseURL = try createDirectoryURL()
        let url: URL
        if let fileExtension = fileExtension {
            let basename = (filename as NSString).deletingPathExtension.lowercased()
            url = baseURL.appendingPathComponent(basename, isDirectory: false)
                .appendingPathExtension(fileExtension)
        } else {
            url = baseURL.appendingPathComponent(filename, isDirectory: false)
        }

        // Increments the filename as needed to ensure we're not providing a URL for an existing file of the same name.
        return fileManager.createIncrementalFilenameIfNeeded(url: url)
    }

    /// Removes a media file given the local file URL.
    ///
    func removeLocalMedia(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    /// Returns filesystem URL for the local Media directory.
    ///
    private func createDirectoryURL() throws -> URL {
        let mediaDirectory = directory.directoryURL(name: Defaults.mediaDirectoryName)

        // Checks whether or not the file path exists for the Media directory.
        // If the filepath does not exist, or if the filepath does exist but it is not a directory, try creating the directory.
        // Note: This way, if unexpectedly a file exists but it is not a dir, an error will throw when trying to create the dir.
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: mediaDirectory.path, isDirectory: &isDirectory) == false || isDirectory.boolValue == false {
            try fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return mediaDirectory
    }
}

private extension MediaFileManager {
    enum Defaults {
        static let mediaDirectoryName = "Media"
    }
}
