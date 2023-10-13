import Foundation

extension OperatingSystemVersion {

    /// Provides a localized string for the Operating System version
    /// e.g. 16.0.0 -> 16
    /// 16.1.0 -> 16.1
    /// 16.0.1 -> 16.0.1
    /// Note that ProcessInfo.operatingSystemName may be more appropriate for the running OS version
    /// This function is intended for use with other OS versions we need to reference, e.g. to communicate system requirements.
    var localizedFormattedString: String {
        let formatString: String

        switch self {
        case let version where version.patchVersion > 0:
            formatString = Localization.patchVersionFormat
        case let version where version.minorVersion > 0:
            formatString = Localization.minorVersionFormat
        default:
            formatString = Localization.majorVersionFormat
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.locale = Locale.current

        let major = formatter.string(from: NSNumber(value: majorVersion)) ?? "\(majorVersion)"
        let minor = formatter.string(from: NSNumber(value: minorVersion)) ?? "\(minorVersion)"
        let patch = formatter.string(from: NSNumber(value: patchVersion)) ?? "\(patchVersion)"


        return String(format: formatString, major, minor, patch)
    }

    private enum Localization {
        static let patchVersionFormat = NSLocalizedString(
            "os.version.format.major.minor.patch",
            value: "%1$@.%2$@.%3$@",
            comment: "A format string for a software version with major, minor, and patch components. " +
            "%1$@ will be replaced with the major, %2$@ with the minor, and %3$@ with the patch.")

        static let minorVersionFormat = NSLocalizedString(
            "os.version.format.major.minor",
            value: "%1$@.%2$@",
            comment: "A format string for a software version with major and minor components. " +
            "%1$@ will be replaced with the major, %2$@ with the minor.")

        static let majorVersionFormat = NSLocalizedString(
            "os.version.format.major.only",
            value: "%1$@",
            comment: "A format string for a software version with only a major component. " +
            "%1$@ will be replaced with the major version number.")
    }
}
