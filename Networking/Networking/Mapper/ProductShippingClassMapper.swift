typealias ProductShippingClassMapper = GenericMapper<ProductShippingClass>

struct Envelope<Resource>: Decodable where Resource: Decodable {

    let data: Resource
}
