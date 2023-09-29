typealias ProductShippingClassMapper = SiteIDMapper<ProductShippingClass>

struct Envelope<Resource>: Decodable where Resource: Decodable {

    let data: Resource
}
