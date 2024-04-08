#import "ServiceRemoteWordPressComREST.h"
#import "WPKit-Swift.h"

@implementation ServiceRemoteWordPressComREST

- (instancetype)initWithWordPressComRestApi:(WordPressComRestApi *)wordPressComRestApi {

    NSParameterAssert([wordPressComRestApi isKindOfClass:[WordPressComRestApi class]]);

    self = [super init];
    if (self) {
        _wordPressComRestApi = wordPressComRestApi;
        _wordPressComRESTAPI = wordPressComRestApi;
    }
    return self;
}

#pragma mark - Request URL construction

- (NSString *)pathForEndpoint:(NSString *)resourceUrl
                  withVersion:(WordPressComRESTAPIVersion)apiVersion
{
    NSParameterAssert([resourceUrl isKindOfClass:[NSString class]]);

    return [WordPressComRESTVersionedPathBuilder pathForEndpoint:resourceUrl
                                                     withVersion:apiVersion];
}

@end

static NSString* const ServiceRemoteWordPressComRESTApiVersionStringInvalid = @"invalid_api_version";
static NSString* const ServiceRemoteWordPressComRESTApiVersionString_1_0 = @"rest/v1";
static NSString* const ServiceRemoteWordPressComRESTApiVersionString_1_1 = @"rest/v1.1";
static NSString* const ServiceRemoteWordPressComRESTApiVersionString_1_2 = @"rest/v1.2";
static NSString* const ServiceRemoteWordPressComRESTApiVersionString_1_3 = @"rest/v1.3";
static NSString* const ServiceRemoteWordPressComRESTApiVersionString_2_0 = @"wpcom/v2";

@implementation WordPressComRESTVersionedPathBuilder

+ (NSString *)pathForEndpoint:(NSString *)endpoint withVersion:(WordPressComRESTAPIVersion)apiVersion
{
    NSString *apiVersionString = [self apiVersionStringWithEnumValue:apiVersion];

    return [NSString stringWithFormat:@"%@/%@", apiVersionString, endpoint];
}

+ (NSString *)apiVersionStringWithEnumValue:(WordPressComRESTAPIVersion)apiVersion
{
    NSString *result = nil;

    switch (apiVersion) {
        case WordPressComRESTAPIVersion_1_0:
            result = ServiceRemoteWordPressComRESTApiVersionString_1_0;
            break;

        case WordPressComRESTAPIVersion_1_1:
            result = ServiceRemoteWordPressComRESTApiVersionString_1_1;
            break;

        case WordPressComRESTAPIVersion_1_2:
            result = ServiceRemoteWordPressComRESTApiVersionString_1_2;
            break;

        case WordPressComRESTAPIVersion_1_3:
            result = ServiceRemoteWordPressComRESTApiVersionString_1_3;
            break;

        case WordPressComRESTAPIVersion_2_0:
            result = ServiceRemoteWordPressComRESTApiVersionString_2_0;
            break;

        default:
            NSAssert(NO, @"This should never by executed");
            result = ServiceRemoteWordPressComRESTApiVersionStringInvalid;
            break;
    }

    return result;
}
@end
