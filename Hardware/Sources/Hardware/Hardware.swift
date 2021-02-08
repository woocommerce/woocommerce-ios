/// We want to bootsrap this package as soon as possible, so that we can
/// start working on it in parallel.
/// It also helps check that the package's test have been added to the proper testing plan.
/// This struct will be removed as soon as we start working on either
/// https://github.com/woocommerce/woocommerce-ios/issues/3587 or
/// https://github.com/woocommerce/woocommerce-ios/issues/3589
/// Leaving it here for now will also help test the PR that adds the package to the project
public struct Hardware {
    public init() {

    }

    public var text = "Hello, World!"
}
