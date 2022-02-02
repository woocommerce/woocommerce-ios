import Foundation
import Codegen

public enum WCPayAccountType: String, Codable, GeneratedCopiable, GeneratedFakeable, Equatable {
    case credit
    case debit
    case prepaid
    case unknown
}
