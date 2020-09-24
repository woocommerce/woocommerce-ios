import Foundation
import CoreData

/// A generic Attribute class with 3 core properties: `id`, `key`, and `value`.
///
/// This is currently only used as the corresponding storage for `ProductVariationAttribute` but
/// we might be able to use it for others later. 
///
@objc(Attribute)
public class Attribute: NSManagedObject {

}
