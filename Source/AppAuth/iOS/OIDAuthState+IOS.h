/*! @file EkoOIDAuthState+IOS.h
    @brief AppAuth iOS SDK
    @copyright
        Copyright 2016 Google Inc. All Rights Reserved.
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

#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST

#import <UIKit/UIKit.h>

#import "OIDAuthState.h"

NS_ASSUME_NONNULL_BEGIN

/*! @brief iOS specific convenience methods for @c EkoOIDAuthState.
 */
@interface EkoOIDAuthState (IOS)

/*! @brief Convenience method to create a @c EkoOIDAuthState by presenting an authorization request
        and performing the authorization code exchange in the case of code flow requests. For
        the hybrid flow, the caller should validate the id_token and c_hash, then perform the token
        request (@c EkoOIDAuthorizationService.performTokenRequest:callback:)
        and update the EkoOIDAuthState with the results (@c
        EkoOIDAuthState.updateWithTokenResponse:error:).
    @param authorizationRequest The authorization request to present.
    @param presentingViewController The view controller from which to present the
        @c SFSafariViewController. On iOS 13, the window of this UIViewController
        is used as the ASPresentationAnchor.
    @param callback The method called when the request has completed or failed.
    @return A @c EkoOIDExternalUserAgentSession instance which will terminate when it
        receives a @c EkoOIDExternalUserAgentSession.cancel message, or after processing a
        @c EkoOIDExternalUserAgentSession.resumeExternalUserAgentFlowWithURL: message.
 */
+ (id<EkoOIDExternalUserAgentSession>)
    authStateByPresentingAuthorizationRequest:(EkoOIDAuthorizationRequest *)authorizationRequest
                     presentingViewController:(UIViewController *)presentingViewController
                                     callback:(EkoOIDAuthStateAuthorizationCallback)callback;

+ (id<EkoOIDExternalUserAgentSession>)
    authStateByPresentingAuthorizationRequest:(EkoOIDAuthorizationRequest *)authorizationRequest
                     callback:(EkoOIDAuthStateAuthorizationCallback)callback API_AVAILABLE(ios(11)) API_UNAVAILABLE(macCatalyst)
    __deprecated_msg("This method will not work on iOS 13. Use "
        "authStateByPresentingAuthorizationRequest:presentingViewController:callback:");

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
