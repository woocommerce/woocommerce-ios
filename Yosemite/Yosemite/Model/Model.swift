import Foundation
import Networking
import Storage



// MARK: - Exported ReadOnly Symbols

public typealias Account = Networking.Account
public typealias AccountSettings = Networking.AccountSettings
public typealias Address = Networking.Address
public typealias APNSDevice = Networking.APNSDevice
public typealias CommentStatus = Networking.CommentStatus
public typealias Credentials = Networking.Credentials
public typealias DotcomDevice = Networking.DotcomDevice
public typealias Leaderboard = Networking.Leaderboard
public typealias LeaderboardRow = Networking.LeaderboardRow
public typealias LeaderboardRowContent = Networking.LeaderboardRowContent
public typealias Media = Networking.Media
public typealias MetaContainer = Networking.MetaContainer
public typealias Note = Networking.Note
public typealias NoteBlock = Networking.NoteBlock
public typealias NoteMedia = Networking.NoteMedia
public typealias NoteRange = Networking.NoteRange
public typealias Order = Networking.Order
public typealias OrderCount = Networking.OrderCount
public typealias OrderCountItem = Networking.OrderCountItem
public typealias OrderItem = Networking.OrderItem
public typealias OrderItemTax = Networking.OrderItemTax
public typealias OrderItemRefund = Networking.OrderItemRefund
public typealias OrderItemTaxRefund = Networking.OrderItemTaxRefund
public typealias OrderStatusEnum = Networking.OrderStatusEnum
public typealias OrderCouponLine = Networking.OrderCouponLine
public typealias OrderNote = Networking.OrderNote
public typealias OrderRefundCondensed = Networking.OrderRefundCondensed
public typealias OrderStatsV4 = Networking.OrderStatsV4
public typealias OrderStatsV4Interval = Networking.OrderStatsV4Interval
public typealias OrderStatsV4Totals = Networking.OrderStatsV4Totals
public typealias OrderStatus = Networking.OrderStatus
public typealias Product = Networking.Product
public typealias ProductBackordersSetting = Networking.ProductBackordersSetting
public typealias ProductReview = Networking.ProductReview
public typealias ProductReviewStatus = Networking.ProductReviewStatus
public typealias ProductShippingClass = Networking.ProductShippingClass
public typealias ProductStatus = Networking.ProductStatus
public typealias ProductCatalogVisibility = Networking.ProductCatalogVisibility
public typealias ProductStockStatus = Networking.ProductStockStatus
public typealias ProductType = Networking.ProductType
public typealias ProductCategory = Networking.ProductCategory
public typealias ProductTag = Networking.ProductTag
public typealias ProductTaxStatus = Networking.ProductTaxStatus
public typealias ProductImage = Networking.ProductImage
public typealias ProductAttribute = Networking.ProductAttribute
public typealias ProductDimensions = Networking.ProductDimensions
public typealias ProductDefaultAttribute = Networking.ProductDefaultAttribute
public typealias ProductDownload = Networking.ProductDownload
public typealias ProductDownloadDragAndDrop = Networking.ProductDownloadDragAndDrop
public typealias ProductVariation = Networking.ProductVariation
public typealias ProductVariationAttribute = Networking.ProductVariationAttribute
public typealias Refund = Networking.Refund
public typealias StatGranularity = Networking.StatGranularity
public typealias StatsGranularityV4 = Networking.StatsGranularityV4
public typealias ShipmentTracking = Networking.ShipmentTracking
public typealias ShipmentTrackingProvider = Networking.ShipmentTrackingProvider
public typealias ShipmentTrackingProviderGroup = Networking.ShipmentTrackingProviderGroup
public typealias ShippingLine = Networking.ShippingLine
public typealias ShippingLineTax = Networking.ShippingLineTax
public typealias Site = Networking.Site
public typealias SiteAPI = Networking.SiteAPI
public typealias Post = Networking.Post
public typealias SiteSetting = Networking.SiteSetting
public typealias SiteSettingGroup = Networking.SiteSettingGroup
public typealias SiteVisitStats = Networking.SiteVisitStats
public typealias SiteVisitStatsItem = Networking.SiteVisitStatsItem
public typealias TaxClass = Networking.TaxClass
public typealias TopEarnerStats = Networking.TopEarnerStats
public typealias TopEarnerStatsItem = Networking.TopEarnerStatsItem
public typealias WooAPIVersion = Networking.WooAPIVersion


// MARK: - Exported Storage Symbols

public typealias StorageAccount = Storage.Account
public typealias StorageAttribute = Storage.GenericAttribute
public typealias StorageNote = Storage.Note
public typealias StorageOrder = Storage.Order
public typealias StorageOrderItemRefund = Storage.OrderItemRefund
public typealias StorageOrderNote = Storage.OrderNote
public typealias StorageOrderRefund = Storage.OrderRefundCondensed
public typealias StorageOrderStatsV4 = Storage.OrderStatsV4
public typealias StorageOrderStatsV4Interval = Storage.OrderStatsV4Interval
public typealias StorageOrderStatsV4Totals = Storage.OrderStatsV4Totals
public typealias StorageOrderStatus = Storage.OrderStatus
public typealias StoragePreselectedProvider = Storage.PreselectedProvider
public typealias StorageProduct = Storage.Product
public typealias StorageProductDimensions = Storage.ProductDimensions
public typealias StorageProductAttribute = Storage.ProductAttribute
public typealias StorageProductImage = Storage.ProductImage
public typealias StorageProductCategory = Storage.ProductCategory
public typealias StorageProductDefaultAttribute = Storage.ProductDefaultAttribute
public typealias StorageProductDownload = Storage.ProductDownload
public typealias StorageProductReview = Storage.ProductReview
public typealias StorageProductShippingClass = Storage.ProductShippingClass
public typealias StorageProductTag = Storage.ProductTag
public typealias StorageRefund = Storage.Refund
public typealias StorageProductVariation = Storage.ProductVariation
public typealias StorageShipmentTracking = Storage.ShipmentTracking
public typealias StorageShipmentTrackingProvider = Storage.ShipmentTrackingProvider
public typealias StorageShipmentTrackingProviderGroup = Storage.ShipmentTrackingProviderGroup
public typealias StorageShippingLine = Storage.ShippingLine
public typealias StorageShippingLineTax = Storage.ShippingLineTax
public typealias StorageSite = Storage.Site
public typealias StorageSiteSetting = Storage.SiteSetting
public typealias StorageSiteVisitStats = Storage.SiteVisitStats
public typealias StorageSiteVisitStatsItem = Storage.SiteVisitStatsItem
public typealias StorageTopEarnerStats = Storage.TopEarnerStats
public typealias StorageTopEarnerStatsItem = Storage.TopEarnerStatsItem
public typealias StorageTaxClass = Storage.TaxClass

// MARK: - Internal ReadOnly Models

typealias UploadableMedia = Networking.UploadableMedia
