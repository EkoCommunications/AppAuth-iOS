/*! @file EkoOIDTokenResponse.m
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

#import "OIDTokenResponse.h"

#import "OIDDefines.h"
#import "OIDFieldMapping.h"
#import "OIDTokenRequest.h"
#import "OIDTokenUtilities.h"

/*! @brief Key used to encode the @c request property for @c NSSecureCoding
 */
static NSString *const kRequestKey = @"request";

/*! @brief The key for the @c accessToken property in the incoming parameters and for
        @c NSSecureCoding.
 */
static NSString *const kAccessTokenKey = @"access_token";

/*! @brief The key for the @c accessTokenExpirationDate property in the incoming parameters and for
        @c NSSecureCoding.
 */
static NSString *const kExpiresInKey = @"expires_in";

/*! @brief The key for the @c tokenType property in the incoming parameters and for
        @c NSSecureCoding.
 */
static NSString *const kTokenTypeKey = @"token_type";

/*! @brief The key for the @c idToken property in the incoming parameters and for @c NSSecureCoding.
 */
static NSString *const kIDTokenKey = @"id_token";

/*! @brief The key for the @c refreshToken property in the incoming parameters and for
        @c NSSecureCoding.
 */
static NSString *const kRefreshTokenKey = @"refresh_token";

/*! @brief The key for the @c scope property in the incoming parameters and for @c NSSecureCoding.
 */
static NSString *const kScopeKey = @"scope";

/*! @brief Key used to encode the @c additionalParameters property for @c NSSecureCoding
 */
static NSString *const kAdditionalParametersKey = @"additionalParameters";

@implementation EkoOIDTokenResponse

/*! @brief Returns a mapping of incoming parameters to instance variables.
    @return A mapping of incoming parameters to instance variables.
 */
+ (NSDictionary<NSString *, EkoOIDFieldMapping *> *)fieldMap {
  static NSMutableDictionary<NSString *, EkoOIDFieldMapping *> *fieldMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    fieldMap = [NSMutableDictionary dictionary];
    fieldMap[kAccessTokenKey] =
        [[EkoOIDFieldMapping alloc] initWithName:@"_accessToken" type:[NSString class]];
    fieldMap[kExpiresInKey] =
        [[EkoOIDFieldMapping alloc] initWithName:@"_accessTokenExpirationDate"
                                         type:[NSDate class]
                                   conversion:[EkoOIDFieldMapping dateSinceNowConversion]];
    fieldMap[kTokenTypeKey] =
        [[EkoOIDFieldMapping alloc] initWithName:@"_tokenType" type:[NSString class]];
    fieldMap[kIDTokenKey] =
        [[EkoOIDFieldMapping alloc] initWithName:@"_idToken" type:[NSString class]];
    fieldMap[kRefreshTokenKey] =
        [[EkoOIDFieldMapping alloc] initWithName:@"_refreshToken" type:[NSString class]];
    fieldMap[kScopeKey] =
        [[EkoOIDFieldMapping alloc] initWithName:@"_scope" type:[NSString class]];
  });
  return fieldMap;
}

#pragma mark - Initializers

- (instancetype)init
    EkoOID_UNAVAILABLE_USE_INITIALIZER(@selector(initWithRequest:parameters:))

- (instancetype)initWithRequest:(EkoOIDTokenRequest *)request
    parameters:(NSDictionary<NSString *, NSObject<NSCopying> *> *)parameters {
  self = [super init];
  if (self) {
    _request = [request copy];
    NSDictionary<NSString *, NSObject<NSCopying> *> *additionalParameters =
        [EkoOIDFieldMapping remainingParametersWithMap:[[self class] fieldMap]
                                         parameters:parameters
                                           instance:self];
    _additionalParameters = additionalParameters;
  }
  return self;
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(nullable NSZone *)zone {
  // The documentation for NSCopying specifically advises us to return a reference to the original
  // instance in the case where instances are immutable (as ours is):
  // "Implement NSCopying by retaining the original instead of creating a new copy when the class
  // and its contents are immutable."
  return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  EkoOIDTokenRequest *request =
      [aDecoder decodeObjectOfClass:[EkoOIDTokenRequest class] forKey:kRequestKey];
  self = [self initWithRequest:request parameters:@{ }];
  if (self) {
    [EkoOIDFieldMapping decodeWithCoder:aDecoder map:[[self class] fieldMap] instance:self];
    _additionalParameters = [aDecoder decodeObjectOfClasses:[EkoOIDFieldMapping JSONTypes]
                                                     forKey:kAdditionalParametersKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [EkoOIDFieldMapping encodeWithCoder:aCoder map:[[self class] fieldMap] instance:self];
  [aCoder encodeObject:_request forKey:kRequestKey];
  [aCoder encodeObject:_additionalParameters forKey:kAdditionalParametersKey];
}

#pragma mark - NSObject overrides

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, accessToken: \"%@\", accessTokenExpirationDate: %@, "
                                     "tokenType: %@, idToken: \"%@\", refreshToken: \"%@\", "
                                     "scope: \"%@\", additionalParameters: %@, request: %@>",
                                    NSStringFromClass([self class]),
                                    (void *)self,
                                    [EkoOIDTokenUtilities redact:_accessToken],
                                    _accessTokenExpirationDate,
                                    _tokenType,
                                    [EkoOIDTokenUtilities redact:_idToken],
                                    [EkoOIDTokenUtilities redact:_refreshToken],
                                    _scope,
                                    _additionalParameters,
                                    _request];
}

#pragma mark -

@end
