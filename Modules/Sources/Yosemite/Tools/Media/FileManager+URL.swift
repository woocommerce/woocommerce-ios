import Foundation

extension FileManager {
    /// Returns a URL with an incremental file name, if a file already exists at the given URL.
    ///
    func createIncrementalFilenameIfNeeded(url originalURL: URL) -> URL {
        var url = originalURL
        let pathExtension = url.pathExtension
        let filename = url.deletingPathExtension().lastPathComponent
        var index = 1
        while fileExists(atPath: url.path) {
            let incrementedName = "\(filename)-\(index)"
            url.deleteLastPathComponent()
            url.appendPathComponent(incrementedName, isDirectory: false)
            url.appendPathExtension(pathExtension)
            index += 1
        }
        return url
    }
}
