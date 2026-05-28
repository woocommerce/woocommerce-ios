/// Tri-state replacement for the old `hasAnyPINs: Bool` so the session can distinguish
/// "we have proof there are no PINs" from "we have no idea yet". Conflating the two opens
/// a hole where a cold cache plus a transient `/staff` fetch failure would auto-unlock POS
/// despite never confirming the security boundary.
///
/// - `unknown`: no successful fetch on record (cold start, or a fetch failed and the cache
///   was empty). Treated as locked-by-default for presentation.
/// - `absent`: confirmed zero PINs. Either the server returned an empty staff list, or the
///   server-side feature flag is off so the endpoint isn't there to consult.
/// - `present`: confirmed at least one PIN. The lock screen presents the numpad.
///
enum POSPINStatus: Equatable {
    case unknown
    case absent
    case present
}
