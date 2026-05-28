/// Tri-state so `.unknown` (no fetch yet) stays distinct from `.absent` (confirmed no PINs).
/// A Bool conflated the two and let cold-cache fetch failures auto-unlock POS.
enum POSPINStatus: Equatable {
    case unknown
    case absent
    case present
}
