/*! @file AppAuth.h
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

//! Project version number for AppAuthFramework-iOS.
FOUNDATION_EXPORT double AppAuthVersionNumber;

//! Project version string for AppAuthFramework-iOS.
FOUNDATION_EXPORT const unsigned char AppAuthVersionString[];

#import <AppAuth/EkoOIDAuthState.h>
#import <AppAuth/EkoOIDAuthStateChangeDelegate.h>
#import <AppAuth/EkoOIDAuthStateErrorDelegate.h>
#import <AppAuth/EkoOIDAuthorizationRequest.h>
#import <AppAuth/EkoOIDAuthorizationResponse.h>
#import <AppAuth/EkoOIDAuthorizationService.h>
#import <AppAuth/EkoOIDError.h>
#import <AppAuth/EkoOIDErrorUtilities.h>
#import <AppAuth/EkoOIDExternalUserAgent.h>
#import <AppAuth/EkoOIDExternalUserAgentRequest.h>
#import <AppAuth/EkoOIDExternalUserAgentSession.h>
#import <AppAuth/EkoOIDGrantTypes.h>
#import <AppAuth/EkoOIDIDToken.h>
#import <AppAuth/EkoOIDRegistrationRequest.h>
#import <AppAuth/EkoOIDRegistrationResponse.h>
#import <AppAuth/EkoOIDResponseTypes.h>
#import <AppAuth/EkoOIDScopes.h>
#import <AppAuth/EkoOIDScopeUtilities.h>
#import <AppAuth/EkoOIDServiceConfiguration.h>
#import <AppAuth/EkoOIDServiceDiscovery.h>
#import <AppAuth/EkoOIDTokenRequest.h>
#import <AppAuth/EkoOIDTokenResponse.h>
#import <AppAuth/EkoOIDTokenUtilities.h>
#import <AppAuth/EkoOIDURLSessionProvider.h>
#import <AppAuth/EkoOIDEndSessionRequest.h>
#import <AppAuth/EkoOIDEndSessionResponse.h>

#if TARGET_OS_TV
#elif TARGET_OS_WATCH
#elif TARGET_OS_IOS || TARGET_OS_MACCATALYST
#import <AppAuth/EkoOIDAuthState+IOS.h>
#import <AppAuth/EkoOIDAuthorizationService+IOS.h>
#import <AppAuth/EkoOIDExternalUserAgentIOS.h>
#import "AppAuth/EkoOIDExternalUserAgentCatalyst.h"
#elif TARGET_OS_MAC
#import <AppAuth/EkoOIDAuthState+Mac.h>
#import <AppAuth/EkoOIDAuthorizationService+Mac.h>
#import <AppAuth/EkoOIDExternalUserAgentMac.h>
#import <AppAuth/EkoOIDRedirectHTTPHandler.h>
#else
#error "Platform Undefined"
#endif

