enum POSSecuritySettingsViewHelper {
    static func canManage(isProtected: Bool, isLocked: Bool, role: POSRole?) -> Bool {
        !isLocked && (!isProtected || role == .admin)
    }
}
