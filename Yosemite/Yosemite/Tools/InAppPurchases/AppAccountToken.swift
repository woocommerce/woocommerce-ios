import Foundation

struct AppAccountToken {
    static func tokenWithSiteId(_ siteID: Int64) -> UUID? {
        let uuidString = String(
            format: "%08x-%04x-%04x-%04x-%012x",
            // 32 bits for "time_low".
            // Backend encodes order_id here, but we don't have an order yet
            0,
            // 16 bits for "time_mid"
            Int.random(in: 0...Int.max) & 0xfff,
            // 16 bits for "time_hi_and_version",
            // four most significant bits holds version number 4
            Int.random(in: 0...Int.max) & 0x0fff | 0x4000,
            // 16 bits, 8 bits for "clk_seq_hi_res",
            // 8 bits for "clk_seq_low",
            // two most significant bits holds zero and one for variant DCE1.1
            Int.random(in: 0...Int.max) & 0x3fff | 0x8000,
            // 48 bits for "node"
            siteID
        )
        let uuid = UUID(uuidString: uuidString)
        return uuid
    }

    static func siteIDFromToken(_ token: UUID) -> Int64? {
        let components = token.uuidString.components(separatedBy: "-")
        guard components.count == 5,
              let siteIdString = components.last else {
            return nil
        }
        let siteId = Int64(siteIdString, radix: 16)
        return siteId
    }
}
