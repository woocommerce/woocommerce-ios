import Foundation
import Yosemite

extension Site {
    func adminURL(path: String) -> URL? {
        guard let baseURL = URL(string: url) else {
            return nil
        }
        return URL(string: path, relativeTo: baseURL)
    }
}
