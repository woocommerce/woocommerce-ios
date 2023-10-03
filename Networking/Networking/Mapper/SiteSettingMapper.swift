/// Mapper for a single SiteSetting
///
struct SiteSettingMapper: Mapper {

    /// Site Identifier associated to the settings that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't really return the SiteID in any of the
    /// settings endpoints.
    ///
    let siteID: Int64

    /// Group name associated to the settings that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the group in any of the setting endpoints.
    ///
    let settingsGroup: SiteSettingGroup

    /// (Attempts) to convert a dictionary into SiteSetting.
    ///
    func map(response: Data) throws -> SiteSetting {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID,
            .settingGroupKey: settingsGroup.rawValue
        ]

        return try extract(from: response, using: decoder)
    }
}
