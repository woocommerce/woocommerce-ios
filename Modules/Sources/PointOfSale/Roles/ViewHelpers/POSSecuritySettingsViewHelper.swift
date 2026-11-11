enum POSSecuritySettingsViewHelper {
    static func canManage(isProtected: Bool, isLocked: Bool, canManageSettings: Bool) -> Bool {
        !isLocked && (!isProtected || canManageSettings)
    }
}
