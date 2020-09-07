protocol OnePasswordResultsFetcher {
    func findLogin(for url: String,
                   viewController: UIViewController,
                   sender: Any,
                   success: @escaping (_ username: String, _ password: String, _ otp: String?) -> Void,
                   failure: @escaping (OnePasswordError) -> Void)
}

