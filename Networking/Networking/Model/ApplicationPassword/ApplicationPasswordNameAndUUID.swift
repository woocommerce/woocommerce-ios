#if os(iOS)

import Foundation

struct ApplicationPasswordNameAndUUID: Decodable {
    let uuid: String
    let name: String
}

#endif
