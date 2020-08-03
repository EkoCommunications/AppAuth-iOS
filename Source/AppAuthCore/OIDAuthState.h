/*! @file EkoOIDAuthState.h
    @brief AppAuth iOS SDK
    @copyright
        Copyright 2015 Google Inc. All Rights Reserved.
    @copydetails
        Licensed under the Apache License, Version 2.0 (the "License");
        you may not use this file except in compliance with the License.
        You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        See the License for the specific language governing permissions and
        limitations under the License.
 */
#import <Foundation/Foundation.h>

@class EkoOIDAuthorizationRequest;
@class EkoOIDAuthorizationResponse;
@class EkoOIDAuthState;
@class EkoOIDRegistrationResponse;
@class EkoOIDTokenResponse;
@class EkoOIDTokenRequest;
@protocol EkoOIDAuthStateChangeDelegate;
@protocol EkoOIDAuthStateErrorDelegate;
@protocol EkoOIDExternalUserAgent;
@protocol EkoOIDExternalUserAgentSession;

NS_ASSUME_NONNULL_BEGIN

/*! @brief Represents a block used to call an action with a fresh access token.
    @param accessToken A valid access token if available.
    @param idToken A valid ID token if available.
    @param error The error if an error occurred.
 */
typedef void (^EkoOIDAuthStateAction)(NSString *_Nullable accessToken,
                                   NSString *_Nullable idToken,
                                   NSError *_Nullable error);

/*! @brief The method called when the @c
        EkoOIDAuthState.authStateByPresentingAuthorizationRequest:presentingViewController:callback:
        method has completed or failed.
    @param authState The auth state, if the authorization request succeeded.
    @param error The error if an error occurred.
 */
typedef void (^EkoOIDAuthStateAuthorizationCallback)(EkoOIDAuthState *_Nullable authState,
                                                  NSError *_Nullable error);

/*! @brief A convenience class that retains the auth state between @c EkoOIDAuthorizationResponse%s
        and @c EkoOIDTokenResponse%s.
 */
@interface EkoOIDAuthState : NSObject <NSSecureCoding>

/*! @brief The most recent refresh token received from the server.
    @discussion Rather than using this property directly, you should call
        @c EkoOIDAuthState.performActionWithFreshTokens:.
    @remarks refresh_token
    @see https://tools.ietf.org/html/rfc6749#section-5.1
 */
@property(nonatomic, readonly, nullable) NSString *refreshToken;

/*! @brief The scope of the current authorization grant.
    @discussion This represents the latest scope returned by the server and may be a subset of the
        scope that was initially granted.
    @remarks scope
 */
@property(nonatomic, readonly, nullable) NSString *scope;

/*! @brief The most recent authorization response used to update the authorization state. For the
        implicit flow, this will contain the latest access token.
 */
@property(nonatomic, readonly) EkoOIDAuthorizationResponse *lastAuthorizationResponse;

/*! @brief The most recent token response used to update this authorization state. This will
        contain the latest access token.
 */
@property(nonatomic, readonly, nullable) EkoOIDTokenResponse *lastTokenResponse;

/*! @brief The most recent registration response used to update this authorization state. This will
        contain the latest client credentials.
 */
@property(nonatomic, readonly, nullable) EkoOIDRegistrationResponse *lastRegistrationResponse;

/*! @brief The authorization error that invalidated this @c EkoOIDAuthState.
    @discussion The authorization error encountered by @c EkoOIDAuthState or set by the user via
        @c EkoOIDAuthState.updateWithAuthorizationError: that invalidated this @c EkoOIDAuthState.
        Authorization errors from @c EkoOIDAuthState will always have a domain of
        @c ::EkoOIDOAuthAuthorizationErrorDomain or @c ::EkoOIDOAuthTokenErrorDomain. Note: that after
        unarchiving the @c EkoOIDAuthState object, the \NSError_userInfo property of this error will
        be nil.
 */
@property(nonatomic, readonly, nullable) NSError *authorizationError;

/*! @brief Returns YES if the authorization state is not known to be invalid.
    @discussion Returns YES if no OAuth errors have been received, and the last call resulted in a
        successful access token or id token. This does not mean that the access is fresh - just
        that it was valid the last time it was used. Note that network and other transient errors
        do not invalidate the authorized state.  If NO, you should authenticate the user again,
        using a fresh authorization request. Invalid @c EkoOIDAuthState objects may still be useful in
        that case, to hint at the previously authorized user and streamline the re-authentication
        experience.
 */
@property(nonatomic, readonly) BOOL isAuthorized;

/*! @brief The @c EkoOIDAuthStateChangeDelegate delegate.
    @discussion Use the delegate to observe state changes (and update storage) as well as error
        states.
 */
@property(nonatomic, weak, nullable) id<EkoOIDAuthStateChangeDelegate> stateChangeDelegate;

/*! @brief The @c EkoOIDAuthStateErrorDelegate delegate.
    @discussion Use the delegate to observe state changes (and update storage) as well as error
        states.
 */
@property(nonatomic, weak, nullable) id<EkoOIDAuthStateErrorDelegate> errorDelegate;

/*! @brief Convenience method to create a @c EkoOIDAuthState by presenting an authorization request
        and performing the authorization code exchange in the case of code flow requests. For
        the hybrid flow, the caller should validate the id_token and c_hash, then perform the token
        request (@c EkoOIDAuthorizationService.performTokenRequest:callback:)
        and update the EkoOIDAuthState with the results (@c
        EkoOIDAuthState.updateWithTokenResponse:error:).
    @param authorizationRequest The authorization request to present.
    @param externalUserAgent A external user agent that can present an external user-agent request.
    @param callback The method called when the request has completed or failed.
    @return A @c EkoOIDExternalUserAgentSession instance which will terminate when it
        receives a @c EkoOIDExternalUserAgentSession.cancel message, or after processing a
        @c EkoOIDExternalUserAgentSession.resumeExternalUserAgentFlowWithURL: message.
 */
+ (id<EkoOIDExternalUserAgentSession>)
    authStateByPresentingAuthorizationRequest:(EkoOIDAuthorizationRequest *)authorizationRequest
                            externalUserAgent:(id<EkoOIDExternalUserAgent>)externalUserAgent
                                     callback:(EkoOIDAuthStateAuthorizationCallback)callback;

/*! @internal
    @brief Unavailable. Please use @c initWithAuthorizationResponse:.
 */
- (instancetype)init NS_UNAVAILABLE;

/*! @brief Creates an auth state from an authorization response.
    @param authorizationResponse The authorization response.
 */
- (instancetype)initWithAuthorizationResponse:(EkoOIDAuthorizationResponse *)authorizationResponse;

/*! @brief Creates an auth state from an authorization and token response.
    @param authorizationResponse The authorization response.
    @param tokenResponse The token response.
 */
- (instancetype)initWithAuthorizationResponse:(EkoOIDAuthorizationResponse *)authorizationResponse
                                tokenResponse:(nullable EkoOIDTokenResponse *)tokenResponse;

/*! @brief Creates an auth state from an registration response.
    @param registrationResponse The registration response.
 */
- (instancetype)initWithRegistrationResponse:(EkoOIDRegistrationResponse *)registrationResponse;

/*! @brief Creates an auth state from an authorization, token and registration response.
    @param authorizationResponse The authorization response.
    @param tokenResponse The token response.
    @param registrationResponse The registration response.
 */
- (instancetype)initWithAuthorizationResponse:
    (nullable EkoOIDAuthorizationResponse *)authorizationResponse
           tokenResponse:(nullable EkoOIDTokenResponse *)tokenResponse
    registrationResponse:(nullable EkoOIDRegistrationResponse *)registrationResponse
    NS_DESIGNATED_INITIALIZER;

/*! @brief Updates the authorization state based on a new authorization response.
    @param authorizationResponse The new authorization response to update the state with.
    @param error Any error encountered when performing the authorization request. Errors in the
        domain @c ::EkoOIDOAuthAuthorizationErrorDomain are reflected in the auth state, other errors
        are assumed to be transient, and ignored.
    @discussion Typically called with the response from an incremental authorization request,
        or if using the implicit flow. Will clear the @c #lastTokenResponse property.
 */
- (void)updateWithAuthorizationResponse:(nullable EkoOIDAuthorizationResponse *)authorizationResponse
                                  error:(nullable NSError *)error;

/*! @brief Updates the authorization state based on a new token response.
    @param tokenResponse The new token response to update the state from.
    @param error Any error encountered when performing the authorization request. Errors in the
        domain @c ::EkoOIDOAuthTokenErrorDomain are reflected in the auth state, other errors
        are assumed to be transient, and ignored.
    @discussion Typically called with the response from an authorization code exchange, or a token
        refresh.
 */
- (void)updateWithTokenResponse:(nullable EkoOIDTokenResponse *)tokenResponse
                          error:(nullable NSError *)error;

/*! @brief Updates the authorization state based on a new registration response.
    @param registrationResponse The new registration response to update the state with.
    @discussion Typically called with the response from a successful client registration
        request. Will reset the auth state.
 */
- (void)updateWithRegistrationResponse:(nullable EkoOIDRegistrationResponse *)registrationResponse;

/*! @brief Updates the authorization state based on an authorization error.
    @param authorizationError The authorization error.
    @discussion Call this method if you receive an authorization error during an API call to
        invalidate the authentication state of this @c EkoOIDAuthState. Don't call with errors
        unrelated to authorization, such as transient network errors.
        The EkoOIDAuthStateErrorDelegate.authState:didEncounterAuthorizationError: method of
        @c #errorDelegate will be called with the error.
        You may optionally use the convenience method
        EkoOIDErrorUtilities.resourceServerAuthorizationErrorWithCode:errorResponse:underlyingError:
        to create \NSError objects for use here.
        The latest error received is stored in @c #authorizationError. Note: that after unarchiving
        this object, the \NSError_userInfo property of this error will be nil.
 */
- (void)updateWithAuthorizationError:(NSError *)authorizationError;

/*! @brief Calls the block with a valid access token (refreshing it first, if needed), or if a
        refresh was needed and failed, with the error that caused it to fail.
    @param action The block to execute with a fresh token. This block will be executed on the main
        thread.
 */
- (void)performActionWithFreshTokens:(EkoOIDAuthStateAction)action;

/*! @brief Calls the block with a valid access token (refreshing it first, if needed), or if a
        refresh was needed and failed, with the error that caused it to fail.
    @param action The block to execute with a fresh token. This block will be executed on the main
        thread.
    @param additionalParameters Additional parameters for the token request if token is
        refreshed.
 */
- (void)performActionWithFreshTokens:(EkoOIDAuthStateAction)action
         additionalRefreshParameters:
    (nullable NSDictionary<NSString *, NSString *> *)additionalParameters;

/*! @brief Calls the block with a valid access token (refreshing it first, if needed), or if a
        refresh was needed and failed, with the error that caused it to fail.
    @param action The block to execute with a fresh token. This block will be executed on the main
        thread.
    @param additionalParameters Additional parameters for the token request if token is
        refreshed.
    @param dispatchQueue The dispatchQueue on which to dispatch the action block.
 */
- (void)performActionWithFreshTokens:(EkoOIDAuthStateAction)action
         additionalRefreshParameters:
    (nullable NSDictionary<NSString *, NSString *> *)additionalParameters
                       dispatchQueue:(dispatch_queue_t)dispatchQueue;

/*! @brief Forces a token refresh the next time @c EkoOIDAuthState.performActionWithFreshTokens: is
        called, even if the current tokens are considered valid.
 */
- (void)setNeedsTokenRefresh;

/*! @brief Creates a token request suitable for refreshing an access token.
    @return A @c EkoOIDTokenRequest suitable for using a refresh token to obtain a new access token.
    @discussion After performing the refresh, call @c EkoOIDAuthState.updateWithTokenResponse:error:
        to update the authorization state based on the response. Rather than doing the token refresh
        yourself, you should use @c EkoOIDAuthState.performActionWithFreshTokens:.
    @see https://tools.ietf.org/html/rfc6749#section-1.5
 */
- (nullable EkoOIDTokenRequest *)tokenRefreshRequest;

/*! @brief Creates a token request suitable for refreshing an access token.
    @param additionalParameters Additional parameters for the token request.
    @return A @c EkoOIDTokenRequest suitable for using a refresh token to obtain a new access token.
    @discussion After performing the refresh, call @c EkoOIDAuthState.updateWithTokenResponse:error:
        to update the authorization state based on the response. Rather than doing the token refresh
        yourself, you should use @c EkoOIDAuthState.performActionWithFreshTokens:.
    @see https://tools.ietf.org/html/rfc6749#section-1.5
 */
- (nullable EkoOIDTokenRequest *)tokenRefreshRequestWithAdditionalParameters:
    (nullable NSDictionary<NSString *, NSString *> *)additionalParameters;

@end

NS_ASSUME_NONNULL_END
