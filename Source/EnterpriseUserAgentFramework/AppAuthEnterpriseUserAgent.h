/*! @file AppAuthEnterpriseUserAgentEnterpriseUserAgent.h
   @brief AppAuthEnterpriseUserAgent iOS SDK
   @copyright
       Copyright 2020 Google Inc. All Rights Reserved.
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

//! Project version number for AppAuthEnterpriseUserAgentEnterpriseUserAgentFramework.
FOUNDATION_EXPORT double AppAuthEnterpriseUserAgentEnterpriseUserAgentVersionNumber;

//! Project version string for AppAuthEnterpriseUserAgentEnterpriseUserAgentFramework.
FOUNDATION_EXPORT const unsigned char AppAuthEnterpriseUserAgentEnterpriseUserAgentVersionString[];

#import <AppAuthEnterpriseUserAgent/EkoOIDAuthState.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDAuthStateChangeDelegate.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDAuthStateErrorDelegate.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDAuthorizationRequest.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDAuthorizationResponse.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDAuthorizationService.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDError.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDErrorUtilities.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDExternalUserAgent.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDExternalUserAgentRequest.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDExternalUserAgentSession.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDGrantTypes.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDIDToken.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDRegistrationRequest.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDRegistrationResponse.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDResponseTypes.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDScopes.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDScopeUtilities.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDServiceConfiguration.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDServiceDiscovery.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDTokenRequest.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDTokenResponse.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDTokenUtilities.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDURLSessionProvider.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDEndSessionRequest.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDEndSessionResponse.h>

#import <AppAuthEnterpriseUserAgent/EkoOIDAuthState+IOS.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDAuthorizationService+IOS.h>
#import <AppAuthEnterpriseUserAgent/EkoOIDExternalUserAgentIOS.h>
#import "AppAuthEnterpriseUserAgent/EkoOIDExternalUserAgentCatalyst.h"

#import <AppAuthEnterpriseUserAgent/EkoOIDExternalUserAgentIOSCustomBrowser.h>
