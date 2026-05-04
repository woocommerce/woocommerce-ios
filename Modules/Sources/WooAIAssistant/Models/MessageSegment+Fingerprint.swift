import Foundation

extension MessageSegment {
    /// Stable hash of the segment's mutable content. The scroll view watches
    /// this to detect streaming text deltas without re-comparing the struct.
    var fingerprint: String {
        switch self {
        case .text(let id, let content):
            return "t:\(id):\(content.count):\(content.hashValue)"
        case .toolCall(let id, _, _, _, let status):
            return "c:\(id):\(status)"
        case .toolResult(let id, _, _, _):
            return "r:\(id)"
        case .cardRender(let id, _, _, _):
            return "d:\(id)"
        case .confirmation(let id, _, _, _, let status):
            return "f:\(id):\(status)"
        }
    }
}
