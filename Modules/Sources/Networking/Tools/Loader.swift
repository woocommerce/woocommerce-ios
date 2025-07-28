import CocoaLumberjackSwift
import Foundation

/// File-Loading Tools: Only for Unit Testing purposes.
///
class Loader {

    /// Default JSON Extension
    ///
    static let jsonExtension = "json"

    /// Loads the contents of the specified file (in the current bundle), and returns it's contents as `Data`.
    ///
    static func contentsOf(_ filename: String, extension: String = jsonExtension) -> Data? {
        guard let url = url(for: filename, extension: `extension`) else {
            return nil
        }

        return try? Data(contentsOf: url)
    }

    /// Finds the specified resource in *all* of the available bundles, recursively.
    ///
    private static func url(for filename: String, extension: String = jsonExtension) -> URL? {
        let targetLastComponent = filename + "." + `extension`

        for bundle in Bundle.allBundles {
            guard let targetURL = url(with: targetLastComponent, in: bundle) else {
                continue
            }

            return targetURL
        }

        return nil
    }

    /// Finds the specified resource within a given Bundle, *recursively*.
    ///
    private static func url(with lastPathComponent: String, in bundle: Bundle) -> URL? {
        let resourcePaths = FileManager.default.subpaths(atPath: bundle.bundlePath) ?? []

        for resourcePath in resourcePaths {
            let url = bundle.bundleURL.appendingPathComponent(resourcePath)
            guard url.lastPathComponent == lastPathComponent else {
                continue
            }

            return url
        }

        return nil
    }
}
