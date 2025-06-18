
import Foundation

/// Mapper to parse the JWToken
///
struct JWTokenMapper: Mapper {
    func map(response: Data) throws -> JWToken {
        let decoder = JSONDecoder()
        let jwt = try decoder.decode(JWTokenResponse.self, from: response).token

        let payload: [String: Any]? = {
            let parts = jwt.components(separatedBy: ".")
            guard parts.count == 3 else {
                return nil
            }

            let midPart = parts[1]

            guard let bodyData = Data(base64URLEncoded: midPart) else {
                return nil
            }

            return try? JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
        }()

        let expiryDate = try {
            guard let payload,
                  let expiry = payload[PayloadKey.expiryDate] as? Double else {
                throw JWTokenMapperError.expiryDateNotFound
            }

            return Date(timeIntervalSince1970: expiry)
        }()

        let siteID =  try {
            guard let payload,
                  let siteID = payload[PayloadKey.blogID] as? Int64 else {
                throw JWTokenMapperError.blogIDNotFound
            }

            return siteID
        }()

        return JWToken(token: jwt, expiryDate: expiryDate, siteID: siteID)
    }

    struct JWTokenResponse: Decodable {
        let token: String
    }
}

private extension JWTokenMapper {
    enum PayloadKey {
        static let expiryDate = "exp"
        static let blogID = "blog_id"
    }
}

enum JWTokenMapperError: Error {
    case expiryDateNotFound
    case blogIDNotFound
}

private extension Data {
    /// "base64url" is an encoding that is safe to use with URLs.
    /// It is defined in RFC 4648, section 5.
    ///
    /// See:
    /// - https://tools.ietf.org/html/rfc4648#section-5
    /// - https://tools.ietf.org/html/rfc7515#appendix-C
    init?(base64URLEncoded: String) {
        let base64 = base64URLEncoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            self.init(base64Encoded: base64 + padding, options: .ignoreUnknownCharacters)
        } else {
            self.init(base64Encoded: base64, options: .ignoreUnknownCharacters)
        }
    }
}
