import WordPressAuthenticator

extension WordPressSupportSourceTag {
    /// Help & Support opened from an age-verification wall. Same origin as Android's `HelpOrigin.AGE_RESTRICTION`.
    static var ageRestriction: WordPressSupportSourceTag {
        WordPressSupportSourceTag(name: "ageRestriction", origin: "origin:age-restriction")
    }
}
