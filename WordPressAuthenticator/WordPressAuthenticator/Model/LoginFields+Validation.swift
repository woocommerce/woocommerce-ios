extension String {
    func isValidURL() -> Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}

// MARK: - LoginFields Validation Methods
//
extension LoginFields {

    /// Returns *true* if the fields required for SignIn have been populated.
    /// Note: that loginFields.emailAddress is not checked. Use loginFields.username instead.
    ///
    func validateFieldsPopulatedForSignin() -> Bool {
        return !username.isEmpty &&
            !password.isEmpty &&
            (meta.userIsDotCom || !siteAddress.isEmpty)
    }

    /// Returns *true* if the siteURL contains a valid URL. False otherwise.
    ///
    func validateSiteForSignin() -> Bool {
        return siteAddress.isValidURL()
    }

    /// Returns *true* if the credentials required for account creation have been provided.
    ///
    func validateFieldsPopulatedForCreateAccount() -> Bool {
        return !emailAddress.isEmpty &&
            !username.isEmpty &&
            !password.isEmpty &&
            !siteAddress.isEmpty
    }

    /// Returns *true* if no spaces have been used in [email, username, address]
    ///
    func validateFieldsForSigninContainNoSpaces() -> Bool {
        let space = " "
        return !emailAddress.contains(space) &&
            !username.contains(space) &&
            !siteAddress.contains(space)
    }

    /// Returns *true* if the username is 50 characters or less.
    ///
    func validateUsernameMaxLength() -> Bool {
        return username.count <= 50
    }
}
