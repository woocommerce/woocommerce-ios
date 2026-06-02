import CommonCrypto
import Foundation
import struct Networking.POSStaffMember

struct DefaultPOSPINAuthenticator: POSPINAuthenticating {
    private let cache: POSStaffCache
    private let fetcher: POSStaffFetching
    private let siteID: Int64

    init(cache: POSStaffCache, fetcher: POSStaffFetching, siteID: Int64) {
        self.cache = cache
        self.fetcher = fetcher
        self.siteID = siteID
    }

    func authenticate(withPIN pin: String) async throws(POSAuthError) -> POSStaff {
        if let match = findMatch(in: cache.load(siteID: siteID) ?? [], pin: pin) {
            return staff(from: match)
        }
        let refreshed = try await refetch()
        guard let match = findMatch(in: refreshed, pin: pin) else {
            throw .invalidPIN
        }
        return staff(from: match)
    }

    func verify(managerPIN pin: String, authorizes capability: POSCapability)
        async throws(POSAuthError) -> POSStaff {
        if let match = findMatch(in: cache.load(siteID: siteID) ?? [], pin: pin),
           holdsCapability(match, capability) {
            return staff(from: match)
        }
        let refreshed = try await refetch()
        guard let match = findMatch(in: refreshed, pin: pin),
              holdsCapability(match, capability) else {
            throw .invalidPIN
        }
        return staff(from: match)
    }

    // MARK: - Lookup helpers

    private func findMatch(in members: [POSStaffMember], pin: String) -> POSStaffMember? {
        for member in members {
            guard let details = member.pin, details.algo == "pbkdf2-sha256" else { continue }
            if verifyPIN(pin, against: details) {
                return member
            }
        }
        return nil
    }

    private func holdsCapability(_ member: POSStaffMember, _ capability: POSCapability) -> Bool {
        member.capabilities[capability.rawValue] == true
    }

    // MARK: - Refetch

    private func refetch() async throws(POSAuthError) -> [POSStaffMember] {
        let capturedGeneration = cache.generation
        do {
            let fresh = try await fetcher.fetchStaff(siteID: siteID)
            guard cache.save(fresh, siteID: siteID, ifGenerationStill: capturedGeneration) else {
                return []
            }
            return fresh
        } catch {
            throw .staffFetchFailed(error)
        }
    }

    // MARK: - PBKDF2

    private func verifyPIN(_ pin: String, against details: POSStaffMember.PINDetails) -> Bool {
        guard let saltData = Data(base64Encoded: details.salt),
              let expectedHash = Data(base64Encoded: details.hash),
              let pinData = pin.data(using: .utf8),
              let iterations = UInt32(exactly: details.iterations) else {
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

    private func constantTimeEqual(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        var result: UInt8 = 0
        for i in 0..<a.count {
            result |= a[i] ^ b[i]
        }
        return result == 0
    }

    // MARK: - POSStaff construction

    private func staff(from member: POSStaffMember) -> POSStaff {
        let posCaps = Set(member.capabilities.compactMap { key, granted -> String? in
            guard granted, POSCapability(rawValue: key) != nil else { return nil }
            return key
        })
        return POSStaff(
            userID: member.userID,
            displayName: member.displayName,
            role: member.role,
            capabilities: posCaps
        )
    }
}
