// WordPressKit Objective-C tests have been "disabled" by brute force commenting them due to
// compilation issues as part of the WordPressAuthenticator and WordPressKit libraries fold into
// WooCommerce. See https://github.com/woocommerce/woocommerce-ios/issues/14329
//
//#import <OCMock/OCMock.h>
//#import <WordPressKit/WordPressKit-Swift.h>
//#import <WordPressKit/ServiceRemoteWordPressComREST.h>
//#import <XCTest/XCTest.h>
//
//@interface BlogSyncServiceTests: XCTestCase
//
//@end
//
//@implementation BlogSyncServiceTests
//
//- (void)testThatSyncSiteDetailsForBlogWorks
//{
//    RemoteBlog *blog = OCMStrictClassMock([RemoteBlog class]);
//    OCMStub([blog blogID]).andReturn(@10);
//
//    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
//    BlogSyncService *service = nil;
//
//    XCTAssertNoThrow(service = [[BlogSyncService alloc] initWithWordPressComRestApi:api siteID:blog.blogID]);
//
//    NSString *endpoint = [NSString stringWithFormat:@"sites/%@", blog.blogID];
//    NSString *url = [service pathForEndpoint:endpoint
//                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
//
//    OCMStub([api get:[OCMArg isEqual:url]
//          parameters:[OCMArg isNil]
//             success:[OCMArg isNotNil]
//             failure:[OCMArg isNotNil]]);
//
//    [service syncBlogWithSuccess:^(RemoteBlog *remoteBlog) {}
//                         failure:^(NSError *error) {}];
//}
//
//@end
