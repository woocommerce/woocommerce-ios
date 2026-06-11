import CocoaLumberjackSwift
import CommonCrypto
import Foundation
import struct Yosemite.POSStaffMember

/// Verifies a PIN against the locally cached staff list using PBKDF2-HMAC-SHA256.
///
/// It is a pure reader of `POSStaffCache`: keeping the cache fresh (fetching staff from the server)
/// is the access session's responsibility, not the authenticator's. On a cache miss it simply
/// reports `.invalidPIN`; the session decides whether to refresh and retry.
///
/// The keychain read + PBKDF2 work runs on a detached task: PBKDF2 is intentionally CPU-heavy and the
/// callers are `@MainActor`, so doing it inline would block the UI thread during PIN entry.
struct DefaultPOSPINAuthenticator: POSPINAuthenticating {
    private let cache: POSStaffCache
    private let siteID: Int64

    init(cache: POSStaffCache, siteID: Int64) {
        self.cache = cache
        self.siteID = siteID
    }

    func authenticate(withPIN pin: String) async throws(POSAuthError) -> POSStaff {
        guard let match = await findMatch(pin: pin) else {
            throw .invalidPIN
        }
        return staff(from: match)
    }

    func verify(managerPIN pin: String, authorizes capability: POSCapability) async throws(POSAuthError) {
        guard let match = await findMatch(pin: pin), holdsCapability(match, capability) else {
            throw .invalidPIN
        }
    }

    func hasAnyPINs() async throws(POSAuthError) -> Bool {
        // Keychain read + JSON decode — kept off the calling (main) actor. The capture list pulls in
        // just `cache` and `siteID` so the `@Sendable` closure doesn't capture the whole `self`.
        return await Task.detached(priority: .userInitiated) { [cache, siteID] in
            cache.hasAnyPINs(siteID: siteID)
        }.value
    }
}

// MARK: - Lookup helpers

private extension DefaultPOSPINAuthenticator {
    /// Returns the cached staff member whose PIN matches `pin`, or `nil` if none do. The keychain
    /// read and PBKDF2 verification run on a detached task so PIN entry never stalls the UI thread.
    func findMatch(pin: String) async -> POSStaffMember? {
        // The capture list pulls in just `cache` and `siteID` so the `@Sendable` closure doesn't
        // capture the whole `self`.
        return await Task.detached(priority: .userInitiated) { [cache, siteID] in
            for member in cache.load(siteID: siteID) ?? [] {
                guard let details = member.pin else { continue }
                guard details.algorithm == Constants.supportedAlgorithm else {
                    DDLogError("POS PIN: unsupported hash algorithm '\(details.algorithm)' for staff \(member.userID); skipping")
                    continue
                }
                if Self.verifyPIN(pin, against: details) {
                    return member
                }
            }
            return nil
        }.value
    }

    func holdsCapability(_ member: POSStaffMember, _ capability: POSCapability) -> Bool {
        member.capabilities[capability.rawValue] == true
    }
}

// MARK: - PBKDF2

private extension DefaultPOSPINAuthenticator {
    static func verifyPIN(_ pin: String, against details: POSStaffMember.PINDetails) -> Bool {
        guard let saltData = Data(base64Encoded: details.salt),
              let expectedHash = Data(base64Encoded: details.hash),
              !expectedHash.isEmpty,
              let pinData = pin.data(using: .utf8),
              let iterations = UInt32(exactly: details.iterations),
              iterations > 0 else {
            // Reject empty hashes and non-positive iteration counts outright: an empty `expectedHash`
            // would otherwise make `constantTimeEqual` return true for any PIN if PBKDF2 ever
            // succeeded with a zero-length derivation.
            return false
        }
        var derived = [UInt8](repeating: 0, count: expectedHash.count)
        let status = saltData.withUnsafeBytes { saltBytes -> Int32 in
            pinData.withUnsafeBytes { pinBytes -> Int32 in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    pinBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                    pinData.count,
                    saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    saltData.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    iterations,
                    &derived,
                    derived.count
                )
            }
        }
        guard status == kCCSuccess else { return false }
        return constantTimeEqual(Data(derived), expectedHash)
    }

    static func constantTimeEqual(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        var result: UInt8 = 0
        for i in 0..<a.count {
            result |= a[i] ^ b[i]
        }
        return result == 0
    }
}

// MARK: - POSStaff construction

private extension DefaultPOSPINAuthenticator {
    /// Builds the `POSStaff` for a verified member, keeping only the capabilities the client
    /// recognizes — i.e. those that map to a known `POSCapability` — so unknown server-side keys
    /// are dropped rather than carried into the app's permission checks.
    func staff(from member: POSStaffMember) -> POSStaff {
        let posCaps = Set(member.capabilities.compactMap { key, granted -> String? in
            guard granted, POSCapability(rawValue: key) != nil else { return nil }
            return key
        })
        return POSStaff(
            userID: member.userID,
            displayName: member.displayName,
            preset: member.preset,
            capabilities: posCaps
        )
    }
}

private enum Constants {
    /// The only PIN hashing scheme the client knows how to verify. PINs tagged with anything else
    /// are skipped (and logged) rather than silently treated as a match/mismatch.
    static let supportedAlgorithm = "pbkdf2-sha256"
}
