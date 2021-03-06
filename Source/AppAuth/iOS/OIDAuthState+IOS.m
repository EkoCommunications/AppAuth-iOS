/*! @file EkoOIDAuthState+IOS.m
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

#import "OIDAuthState+IOS.h"
#import "OIDExternalUserAgentIOS.h"
#import "OIDExternalUserAgentCatalyst.h"

@implementation EkoOIDAuthState (IOS)

+ (id<EkoOIDExternalUserAgentSession>)
    authStateByPresentingAuthorizationRequest:(EkoOIDAuthorizationRequest *)authorizationRequest
                     presentingViewController:(UIViewController *)presentingViewController
                                     callback:(EkoOIDAuthStateAuthorizationCallback)callback {
  id<EkoOIDExternalUserAgent> externalUserAgent;
#if TARGET_OS_MACCATALYST
  externalUserAgent = [[EkoOIDExternalUserAgentCatalyst alloc]
      initWithPresentingViewController:presentingViewController];
#else // TARGET_OS_MACCATALYST
  externalUserAgent = [[EkoOIDExternalUserAgentIOS alloc] initWithPresentingViewController:presentingViewController];
#endif // TARGET_OS_MACCATALYST
  return [self authStateByPresentingAuthorizationRequest:authorizationRequest
                                       externalUserAgent:externalUserAgent
                                                callback:callback];
}

#if !TARGET_OS_MACCATALYST
+ (id<EkoOIDExternalUserAgentSession>)
    authStateByPresentingAuthorizationRequest:(EkoOIDAuthorizationRequest *)authorizationRequest
                                  callback:(EkoOIDAuthStateAuthorizationCallback)callback {
  EkoOIDExternalUserAgentIOS *externalUserAgent = [[EkoOIDExternalUserAgentIOS alloc] init];
  return [self authStateByPresentingAuthorizationRequest:authorizationRequest
                                       externalUserAgent:externalUserAgent
                                                callback:callback];
}
#endif // !TARGET_OS_MACCATALYST

@end

#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
