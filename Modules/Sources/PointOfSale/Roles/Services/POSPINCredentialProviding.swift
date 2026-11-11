/// A PIN that unlocks POS as `staff`.
struct POSPINCredential: Equatable, Sendable {
    let staff: POSStaff
    let pinHash: POSPINHash
}

/// The data source for PIN and permission checks. M1 reads the local Admin and Cashier PINs; M2 can
/// supply synced staff records without changing the lock screen or approval flow.
protocol POSPINCredentialProviding: Sendable {
    /// An empty list means PIN protection is off. Throws when the stored credentials can't be read,
    /// so callers can keep POS locked instead of treating unreadable data as "no PINs".
    func credentials() throws(POSPINStoreError) -> [POSPINCredential]
}

protocol POSPINManaging: POSPINCredentialProviding {
    func setPIN(_ pin: String, for role: POSRole) throws(POSPINStoreError)
    func removePIN(for role: POSRole) throws(POSPINStoreError)
}
