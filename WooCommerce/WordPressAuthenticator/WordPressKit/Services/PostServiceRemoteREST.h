#import <Foundation/Foundation.h>
#import <WordPressAuthenticator/PostServiceRemote.h>
#import <WordPressAuthenticator/SiteServiceRemoteWordPressComREST.h>

@class RemoteUser;
@class RemoteLikeUser;

@interface PostServiceRemoteREST : SiteServiceRemoteWordPressComREST <PostServiceRemote>

/**
 *  @brief      Saves a post.
 *
 *
 *  @discussion Drafts and auto-drafts are just overwritten by autosave for the same
 *              user if the post is not locked.
 *              Non drafts or other users drafts are not overwritten.
 *  @param      post        The post to save.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)autoSave:(RemotePost * _Nonnull)post
         success:(void (^ _Nullable)(RemotePost * _Nullable post, NSString * _Nullable previewURL))success
         failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

/**
 *  @brief      Get autosave revision of a post.
 *
 *
 *  @discussion retrieve the latest autosave revision of a post
 
 *  @param      post        The post to save.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)getAutoSaveForPost:(RemotePost * _Nonnull)post
                   success:(void (^ _Nullable)(RemotePost * _Nullable))success
                   failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

/// Returns a remote post with the given data.
+ (nonnull RemotePost *)remotePostFromJSONDictionary:(nonnull NSDictionary *)jsonPost;

@end
