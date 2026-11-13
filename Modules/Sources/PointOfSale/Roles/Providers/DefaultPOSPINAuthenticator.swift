/// Matches a PIN against the credentials of the injected data source.
///
/// The storage read and PBKDF2 work run on a detached task: PBKDF2 is intentionally CPU-heavy and the
/// callers are `@MainActor`, so doing it inline would block the UI thread during PIN entry.
struct DefaultPOSPINAuthenticator: POSPINAuthenticating {
    private let credentialProvider: POSPINCredentialProviding

    init(credentialProvider: POSPINCredentialProviding) {
        self.credentialProvider = credentialProvider
    }

    func authenticate(withPIN pin: String) async throws(POSAuthError) -> POSStaff {
        try await findMatch(pin: pin).staff
    }

    func verify(managerPIN pin: String, authorizes capability: POSCapability) async throws(POSAuthError) {
        guard try await findMatch(pin: pin).staff.hasCapability(capability) else {
            throw .invalidPIN
        }
    }
}

private extension DefaultPOSPINAuthenticator {
    func findMatch(pin: String) async throws(POSAuthError) -> POSPINCredential {
        let result = await Task.detached(priority: .userInitiated) { [credentialProvider] () -> Result<POSPINCredential?, POSPINStoreError> in
            Result { () throws(POSPINStoreError) in
                try credentialProvider.credentials().first { $0.pinHash.matches(pin) }
            }
        }.value

        switch result {
        case .success(let credential?):
            return credential
        case .success(nil):
            throw .invalidPIN
        case .failure:
            // Unreadable credentials match no PIN, but they aren't a wrong guess either.
            throw .unknown
        }
    }
}
