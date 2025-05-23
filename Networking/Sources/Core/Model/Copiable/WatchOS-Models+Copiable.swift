import Codegen

/// This piece of code is copied from Models+Copiable.generated
/// Ideally we should add full copiable support to NetworkingWatchOS but some updates to the swift template are needed.
///
extension NetworkingWatchOS.Address {
    public func copy(
        firstName: CopiableProp<String> = .copy,
        lastName: CopiableProp<String> = .copy,
        company: NullableCopiableProp<String> = .copy,
        address1: CopiableProp<String> = .copy,
        address2: NullableCopiableProp<String> = .copy,
        city: CopiableProp<String> = .copy,
        state: CopiableProp<String> = .copy,
        postcode: CopiableProp<String> = .copy,
        country: CopiableProp<String> = .copy,
        phone: NullableCopiableProp<String> = .copy,
        email: NullableCopiableProp<String> = .copy
    ) -> NetworkingWatchOS.Address {
        let firstName = firstName ?? self.firstName
        let lastName = lastName ?? self.lastName
        let company = company ?? self.company
        let address1 = address1 ?? self.address1
        let address2 = address2 ?? self.address2
        let city = city ?? self.city
        let state = state ?? self.state
        let postcode = postcode ?? self.postcode
        let country = country ?? self.country
        let phone = phone ?? self.phone
        let email = email ?? self.email

        return NetworkingWatchOS.Address(
            firstName: firstName,
            lastName: lastName,
            company: company,
            address1: address1,
            address2: address2,
            city: city,
            state: state,
            postcode: postcode,
            country: country,
            phone: phone,
            email: email
        )
    }
}
