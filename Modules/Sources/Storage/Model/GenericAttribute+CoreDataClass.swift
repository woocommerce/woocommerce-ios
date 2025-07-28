import Foundation
import CoreData

/// A generic Attribute class with 3 core properties: `id`, `key`, and `value`.
///
/// This is currently only used as the corresponding storage for `ProductVariationAttribute` but
/// we might be able to use it for others later.
///
/// ## Naming
///
/// This would have been named as just “Attribute” but Xcode 12 build issues prevents us from
/// doing so because there's an existing unrelated Attribute class in Aztec. ¯\_(ツ)_/¯
///
@objc(GenericAttribute)
public class GenericAttribute: NSManagedObject {

}
