/*! @file EkoOIDAuthorizationService.m
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

#import "OIDAuthorizationService.h"

#import "OIDAuthorizationRequest.h"
#import "OIDAuthorizationResponse.h"
#import "OIDDefines.h"
#import "OIDEndSessionRequest.h"
#import "OIDEndSessionResponse.h"
#import "OIDErrorUtilities.h"
#import "OIDExternalUserAgent.h"
#import "OIDExternalUserAgentSession.h"
#import "OIDIDToken.h"
#import "OIDRegistrationRequest.h"
#import "OIDRegistrationResponse.h"
#import "OIDServiceConfiguration.h"
#import "OIDServiceDiscovery.h"
#import "OIDTokenRequest.h"
#import "OIDTokenResponse.h"
#import "OIDURLQueryComponent.h"
#import "OIDURLSessionProvider.h"

/*! @brief Path appended to an OpenID Connect issuer for discovery
    @see https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfig
 */
static NSString *const kOpenIDConfigurationWellKnownPath = @".well-known/openid-configuration";

/*! @brief Max allowable iat (Issued At) time skew
    @see https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation
 */
static int const kEkoOIDAuthorizationSessionIATMaxSkew = 600;

NS_ASSUME_NONNULL_BEGIN

@interface EkoOIDAuthorizationSession : NSObject<EkoOIDExternalUserAgentSession>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithRequest:(EkoOIDAuthorizationRequest *)request
    NS_DESIGNATED_INITIALIZER;

@end

@implementation EkoOIDAuthorizationSession {
  EkoOIDAuthorizationRequest *_request;
  id<EkoOIDExternalUserAgent> _externalUserAgent;
  EkoOIDAuthorizationCallback _pendingauthorizationFlowCallback;
}

- (instancetype)initWithRequest:(EkoOIDAuthorizationRequest *)request {
  self = [super init];
  if (self) {
    _request = [request copy];
  }
  return self;
}

- (void)presentAuthorizationWithExternalUserAgent:(id<EkoOIDExternalUserAgent>)externalUserAgent
                                         callback:(EkoOIDAuthorizationCallback)authorizationFlowCallback {
  _externalUserAgent = externalUserAgent;
  _pendingauthorizationFlowCallback = authorizationFlowCallback;
  BOOL authorizationFlowStarted =
      [_externalUserAgent presentExternalUserAgentRequest:_request session:self];
  if (!authorizationFlowStarted) {
    NSError *safariError = [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeSafariOpenError
                                            underlyingError:nil
                                                description:@"Unable to open Safari."];
    [self didFinishWithResponse:nil error:safariError];
  }
}

- (void)cancel {
  [self cancelWithCompletion:nil];
}

- (void)cancelWithCompletion:(nullable void (^)(void))completion {
  [_externalUserAgent dismissExternalUserAgentAnimated:YES completion:^{
      NSError *error = [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeUserCanceledAuthorizationFlow
                                        underlyingError:nil
                                            description:@"Authorization flow was cancelled."];
      [self didFinishWithResponse:nil error:error];
      if (completion) completion();
  }];
}

/*! @brief Does the redirection URL equal another URL down to the path component?
    @param URL The first redirect URI to compare.
    @param redirectionURL The second redirect URI to compare.
    @return YES if the URLs match down to the path level (query params are ignored).
 */
+ (BOOL)URL:(NSURL *)URL matchesRedirectionURL:(NSURL *)redirectionURL {
  NSURL *standardizedURL = [URL standardizedURL];
  NSURL *standardizedRedirectURL = [redirectionURL standardizedURL];

  return [standardizedURL.scheme caseInsensitiveCompare:standardizedRedirectURL.scheme] == NSOrderedSame
      && EkoOIDIsEqualIncludingNil(standardizedURL.user, standardizedRedirectURL.user)
      && EkoOIDIsEqualIncludingNil(standardizedURL.password, standardizedRedirectURL.password)
      && EkoOIDIsEqualIncludingNil(standardizedURL.host, standardizedRedirectURL.host)
      && EkoOIDIsEqualIncludingNil(standardizedURL.port, standardizedRedirectURL.port)
      && EkoOIDIsEqualIncludingNil(standardizedURL.path, standardizedRedirectURL.path);
}

- (BOOL)shouldHandleURL:(NSURL *)URL {
  return [[self class] URL:URL matchesRedirectionURL:_request.redirectURL];
}

- (BOOL)resumeExternalUserAgentFlowWithURL:(NSURL *)URL {
  // rejects URLs that don't match redirect (these may be completely unrelated to the authorization)
  if (![self shouldHandleURL:URL]) {
    return NO;
  }
  
  AppAuthRequestTrace(@"Authorization Response: %@", URL);
  
  // checks for an invalid state
  if (!_pendingauthorizationFlowCallback) {
    [NSException raise:EkoOIDOAuthExceptionInvalidAuthorizationFlow
                format:@"%@", EkoOIDOAuthExceptionInvalidAuthorizationFlow, nil];
  }

  EkoOIDURLQueryComponent *query = [[EkoOIDURLQueryComponent alloc] initWithURL:URL];

  NSError *error;
  EkoOIDAuthorizationResponse *response = nil;

  // checks for an OAuth error response as per RFC6749 Section 4.1.2.1
  if (query.dictionaryValue[EkoOIDOAuthErrorFieldError]) {
    error = [EkoOIDErrorUtilities OAuthErrorWithDomain:EkoOIDOAuthAuthorizationErrorDomain
                                      OAuthResponse:query.dictionaryValue
                                    underlyingError:nil];
  }

  // no error, should be a valid OAuth 2.0 response
  if (!error) {
    response = [[EkoOIDAuthorizationResponse alloc] initWithRequest:_request
                                                      parameters:query.dictionaryValue];
      
    // verifies that the state in the response matches the state in the request, or both are nil
    if (!EkoOIDIsEqualIncludingNil(_request.state, response.state)) {
      NSMutableDictionary *userInfo = [query.dictionaryValue mutableCopy];
      userInfo[NSLocalizedDescriptionKey] =
        [NSString stringWithFormat:@"State mismatch, expecting %@ but got %@ in authorization "
                                   "response %@",
                                   _request.state,
                                   response.state,
                                   response];
      response = nil;
      error = [NSError errorWithDomain:EkoOIDOAuthAuthorizationErrorDomain
                                  code:EkoOIDErrorCodeOAuthAuthorizationClientError
                              userInfo:userInfo];
      }
  }

  [_externalUserAgent dismissExternalUserAgentAnimated:YES completion:^{
      [self didFinishWithResponse:response error:error];
  }];

  return YES;
}

- (void)failExternalUserAgentFlowWithError:(NSError *)error {
  [self didFinishWithResponse:nil error:error];
}

/*! @brief Invokes the pending callback and performs cleanup.
    @param response The authorization response, if any to return to the callback.
    @param error The error, if any, to return to the callback.
 */
- (void)didFinishWithResponse:(nullable EkoOIDAuthorizationResponse *)response
                        error:(nullable NSError *)error {
  EkoOIDAuthorizationCallback callback = _pendingauthorizationFlowCallback;
  _pendingauthorizationFlowCallback = nil;
  _externalUserAgent = nil;
  if (callback) {
    callback(response, error);
  }
}

@end

@interface EkoOIDEndSessionImplementation : NSObject<EkoOIDExternalUserAgentSession> {
  // private variables
  EkoOIDEndSessionRequest *_request;
  id<EkoOIDExternalUserAgent> _externalUserAgent;
  EkoOIDEndSessionCallback _pendingEndSessionCallback;
}
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithRequest:(EkoOIDEndSessionRequest *)request
    NS_DESIGNATED_INITIALIZER;
@end


@implementation EkoOIDEndSessionImplementation

- (instancetype)initWithRequest:(EkoOIDEndSessionRequest *)request {
  self = [super init];
  if (self) {
    _request = [request copy];
  }
  return self;
}

- (void)presentAuthorizationWithExternalUserAgent:(id<EkoOIDExternalUserAgent>)externalUserAgent
                                         callback:(EkoOIDEndSessionCallback)authorizationFlowCallback {
  _externalUserAgent = externalUserAgent;
  _pendingEndSessionCallback = authorizationFlowCallback;
  BOOL authorizationFlowStarted =
      [_externalUserAgent presentExternalUserAgentRequest:_request session:self];
  if (!authorizationFlowStarted) {
    NSError *safariError = [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeSafariOpenError
                                            underlyingError:nil
                                                description:@"Unable to open Safari."];
    [self didFinishWithResponse:nil error:safariError];
  }
}

- (void)cancel {
  [self cancelWithCompletion:nil];
}

- (void)cancelWithCompletion:(nullable void (^)(void))completion {
  [_externalUserAgent dismissExternalUserAgentAnimated:YES completion:^{
    NSError *error = [EkoOIDErrorUtilities
                      errorWithCode:EkoOIDErrorCodeUserCanceledAuthorizationFlow
                      underlyingError:nil
                      description:nil];
    [self didFinishWithResponse:nil error:error];
    if (completion) completion();
  }];
}

- (BOOL)shouldHandleURL:(NSURL *)URL {
  // The logic of when to handle the URL is the same as for authorization requests: should match
  // down to the path component.
  return [[EkoOIDAuthorizationSession class] URL:URL
                        matchesRedirectionURL:_request.postLogoutRedirectURL];
}

- (BOOL)resumeExternalUserAgentFlowWithURL:(NSURL *)URL {
  // rejects URLs that don't match redirect (these may be completely unrelated to the authorization)
  if (![self shouldHandleURL:URL]) {
    return NO;
  }
  // checks for an invalid state
  if (!_pendingEndSessionCallback) {
    [NSException raise:EkoOIDOAuthExceptionInvalidAuthorizationFlow
                format:@"%@", EkoOIDOAuthExceptionInvalidAuthorizationFlow, nil];
  }
  
  
  NSError *error;
  EkoOIDEndSessionResponse *response = nil;

  EkoOIDURLQueryComponent *query = [[EkoOIDURLQueryComponent alloc] initWithURL:URL];
  response = [[EkoOIDEndSessionResponse alloc] initWithRequest:_request
                                                 parameters:query.dictionaryValue];
  
  // verifies that the state in the response matches the state in the request, or both are nil
  if (!EkoOIDIsEqualIncludingNil(_request.state, response.state)) {
    NSMutableDictionary *userInfo = [query.dictionaryValue mutableCopy];
    userInfo[NSLocalizedDescriptionKey] =
    [NSString stringWithFormat:@"State mismatch, expecting %@ but got %@ in authorization "
     "response %@",
     _request.state,
     response.state,
     response];
    response = nil;
    error = [NSError errorWithDomain:EkoOIDOAuthAuthorizationErrorDomain
                                code:EkoOIDErrorCodeOAuthAuthorizationClientError
                            userInfo:userInfo];
  }
  
  [_externalUserAgent dismissExternalUserAgentAnimated:YES completion:^{
    [self didFinishWithResponse:response error:error];
  }];
  
  return YES;
}

- (void)failExternalUserAgentFlowWithError:(NSError *)error {
  [self didFinishWithResponse:nil error:error];
}

/*! @brief Invokes the pending callback and performs cleanup.
 @param response The authorization response, if any to return to the callback.
 @param error The error, if any, to return to the callback.
 */
- (void)didFinishWithResponse:(nullable EkoOIDEndSessionResponse *)response
                        error:(nullable NSError *)error {
  EkoOIDEndSessionCallback callback = _pendingEndSessionCallback;
  _pendingEndSessionCallback = nil;
  _externalUserAgent = nil;
  if (callback) {
    callback(response, error);
  }
}

@end

@implementation EkoOIDAuthorizationService

+ (void)discoverServiceConfigurationForIssuer:(NSURL *)issuerURL
                                   completion:(EkoOIDDiscoveryCallback)completion {
  NSURL *fullDiscoveryURL =
      [issuerURL URLByAppendingPathComponent:kOpenIDConfigurationWellKnownPath];

  [[self class] discoverServiceConfigurationForDiscoveryURL:fullDiscoveryURL
                                                 completion:completion];
}

+ (void)discoverServiceConfigurationForDiscoveryURL:(NSURL *)discoveryURL
    completion:(EkoOIDDiscoveryCallback)completion {

  NSURLSession *session = [EkoOIDURLSessionProvider session];
  NSURLSessionDataTask *task =
      [session dataTaskWithURL:discoveryURL
             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    // If we got any sort of error, just report it.
    if (error || !data) {
      NSString *errorDescription =
          [NSString stringWithFormat:@"Connection error fetching discovery document '%@': %@.",
                                     discoveryURL,
                                     error.localizedDescription];
      error = [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeNetworkError
                               underlyingError:error
                                   description:errorDescription];
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, error);
      });
      return;
    }

    NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;

    // Check for non-200 status codes.
    // https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfigurationResponse
    if (urlResponse.statusCode != 200) {
      NSError *URLResponseError = [EkoOIDErrorUtilities HTTPErrorWithHTTPResponse:urlResponse
                                                                          data:data];
      NSString *errorDescription =
          [NSString stringWithFormat:@"Non-200 HTTP response (%d) fetching discovery document "
                                     "'%@'.",
                                     (int)urlResponse.statusCode,
                                     discoveryURL];
      error = [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeNetworkError
                               underlyingError:URLResponseError
                                   description:errorDescription];
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, error);
      });
      return;
    }

    // Construct an EkoOIDServiceDiscovery with the received JSON.
    EkoOIDServiceDiscovery *discovery =
        [[EkoOIDServiceDiscovery alloc] initWithJSONData:data error:&error];
    if (error || !discovery) {
      NSString *errorDescription =
          [NSString stringWithFormat:@"JSON error parsing document at '%@': %@",
                                     discoveryURL,
                                     error.localizedDescription];
      error = [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeNetworkError
                               underlyingError:error
                                   description:errorDescription];
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, error);
      });
      return;
    }

    // Create our service configuration with the discovery document and return it.
    EkoOIDServiceConfiguration *configuration =
        [[EkoOIDServiceConfiguration alloc] initWithDiscoveryDocument:discovery];
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(configuration, nil);
    });
  }];
  [task resume];
}

#pragma mark - Authorization Endpoint

+ (id<EkoOIDExternalUserAgentSession>) presentAuthorizationRequest:(EkoOIDAuthorizationRequest *)request
    externalUserAgent:(id<EkoOIDExternalUserAgent>)externalUserAgent
             callback:(EkoOIDAuthorizationCallback)callback {
  
  AppAuthRequestTrace(@"Authorization Request: %@", request);
  
  EkoOIDAuthorizationSession *flowSession = [[EkoOIDAuthorizationSession alloc] initWithRequest:request];
  [flowSession presentAuthorizationWithExternalUserAgent:externalUserAgent callback:callback];
  return flowSession;
}

+ (id<EkoOIDExternalUserAgentSession>)
    presentEndSessionRequest:(EkoOIDEndSessionRequest *)request
           externalUserAgent:(id<EkoOIDExternalUserAgent>)externalUserAgent
                    callback:(EkoOIDEndSessionCallback)callback {
  EkoOIDEndSessionImplementation *flowSession =
      [[EkoOIDEndSessionImplementation alloc] initWithRequest:request];
  [flowSession presentAuthorizationWithExternalUserAgent:externalUserAgent callback:callback];
  return flowSession;
}

#pragma mark - Token Endpoint

+ (void)performTokenRequest:(EkoOIDTokenRequest *)request callback:(EkoOIDTokenCallback)callback {
  [[self class] performTokenRequest:request
      originalAuthorizationResponse:nil
                           callback:callback];
}

+ (void)performTokenRequest:(EkoOIDTokenRequest *)request
    originalAuthorizationResponse:(EkoOIDAuthorizationResponse *_Nullable)authorizationResponse
                         callback:(EkoOIDTokenCallback)callback {

  NSURLRequest *URLRequest = [request URLRequest];
  
  AppAuthRequestTrace(@"Token Request: %@\nHeaders:%@\nHTTPBody: %@",
                      URLRequest.URL,
                      URLRequest.allHTTPHeaderFields,
                      [[NSString alloc] initWithData:URLRequest.HTTPBody
                                            encoding:NSUTF8StringEncoding]);

  NSURLSession *session = [EkoOIDURLSessionProvider session];
  [[session dataTaskWithRequest:URLRequest
              completionHandler:^(NSData *_Nullable data,
                                  NSURLResponse *_Nullable response,
                                  NSError *_Nullable error) {
    if (error) {
      // A network error or server error occurred.
      NSString *errorDescription =
          [NSString stringWithFormat:@"Connection error making token request to '%@': %@.",
                                     URLRequest.URL,
                                     error.localizedDescription];
      NSError *returnedError =
          [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeNetworkError
                           underlyingError:error
                               description:errorDescription];
      dispatch_async(dispatch_get_main_queue(), ^{
        callback(nil, returnedError);
      });
      return;
    }

    NSHTTPURLResponse *HTTPURLResponse = (NSHTTPURLResponse *)response;
    NSInteger statusCode = HTTPURLResponse.statusCode;
    AppAuthRequestTrace(@"Token Response: HTTP Status %d\nHTTPBody: %@",
                        (int)statusCode,
                        [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    if (statusCode != 200) {
      // A server error occurred.
      NSError *serverError =
          [EkoOIDErrorUtilities HTTPErrorWithHTTPResponse:HTTPURLResponse data:data];

      // HTTP 4xx may indicate an RFC6749 Section 5.2 error response, attempts to parse as such.
      if (statusCode >= 400 && statusCode < 500) {
        NSError *jsonDeserializationError;
        NSDictionary<NSString *, NSObject<NSCopying> *> *json =
            [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonDeserializationError];

        // If the HTTP 4xx response parses as JSON and has an 'error' key, it's an OAuth error.
        // These errors are special as they indicate a problem with the authorization grant.
        if (json[EkoOIDOAuthErrorFieldError]) {
          NSError *oauthError =
            [EkoOIDErrorUtilities OAuthErrorWithDomain:EkoOIDOAuthTokenErrorDomain
                                      OAuthResponse:json
                                    underlyingError:serverError];
          dispatch_async(dispatch_get_main_queue(), ^{
            callback(nil, oauthError);
          });
          return;
        }
      }

      // Status code indicates this is an error, but not an RFC6749 Section 5.2 error.
      NSString *errorDescription =
          [NSString stringWithFormat:@"Non-200 HTTP response (%d) making token request to '%@'.",
                                     (int)statusCode,
                                      URLRequest.URL];
      NSError *returnedError =
          [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeServerError
                           underlyingError:serverError
                               description:errorDescription];
      dispatch_async(dispatch_get_main_queue(), ^{
        callback(nil, returnedError);
      });
      return;
    }

    NSError *jsonDeserializationError;
    NSDictionary<NSString *, NSObject<NSCopying> *> *json =
        [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonDeserializationError];
    if (jsonDeserializationError) {
      // A problem occurred deserializing the response/JSON.
      NSString *errorDescription =
          [NSString stringWithFormat:@"JSON error parsing token response: %@",
                                     jsonDeserializationError.localizedDescription];
      NSError *returnedError =
          [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeJSONDeserializationError
                           underlyingError:jsonDeserializationError
                               description:errorDescription];
      dispatch_async(dispatch_get_main_queue(), ^{
        callback(nil, returnedError);
      });
      return;
    }

    EkoOIDTokenResponse *tokenResponse =
        [[EkoOIDTokenResponse alloc] initWithRequest:request parameters:json];
    if (!tokenResponse) {
      // A problem occurred constructing the token response from the JSON.
      NSError *returnedError =
          [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeTokenResponseConstructionError
                           underlyingError:jsonDeserializationError
                               description:@"Token response invalid."];
      dispatch_async(dispatch_get_main_queue(), ^{
        callback(nil, returnedError);
      });
      return;
    }

    // If an ID Token is included in the response, validates the ID Token following the rules
    // in OpenID Connect Core Section 3.1.3.7 for features that AppAuth directly supports
    // (which excludes rules #1, #4, #5, #7, #8, #12, and #13). Regarding rule #6, ID Tokens
    // received by this class are received via direct communication between the Client and the Token
    // Endpoint, thus we are exercising the option to rely only on the TLS validation. AppAuth
    // has a zero dependencies policy, and verifying the JWT signature would add a dependency.
    // Users of the library are welcome to perform the JWT signature verification themselves should
    // they wish.
    if (tokenResponse.idToken) {
      EkoOIDIDToken *idToken = [[EkoOIDIDToken alloc] initWithIDTokenString:tokenResponse.idToken];
      if (!idToken) {
        NSError *invalidIDToken =
          [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeIDTokenParsingError
                           underlyingError:nil
                               description:@"ID Token parsing failed"];
        dispatch_async(dispatch_get_main_queue(), ^{
          callback(nil, invalidIDToken);
        });
        return;
      }
      
      // OpenID Connect Core Section 3.1.3.7. rule #1
      // Not supported: AppAuth does not support JWT encryption.

      // OpenID Connect Core Section 3.1.3.7. rule #2
      // Validates that the issuer in the ID Token matches that of the discovery document.
      NSURL *issuer = tokenResponse.request.configuration.issuer;
      if (issuer && ![idToken.issuer isEqual:issuer]) {
        NSError *invalidIDToken =
          [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeIDTokenFailedValidationError
                           underlyingError:nil
                               description:@"Issuer mismatch"];
        dispatch_async(dispatch_get_main_queue(), ^{
          callback(nil, invalidIDToken);
        });
        return;
      }

      // OpenID Connect Core Section 3.1.3.7. rule #3 & Section 2 azp Claim
      // Validates that the aud (audience) Claim contains the client ID, or that the azp
      // (authorized party) Claim matches the client ID.
      NSString *clientID = tokenResponse.request.clientID;
      if (![idToken.audience containsObject:clientID] &&
          ![idToken.claims[@"azp"] isEqualToString:clientID]) {
        NSError *invalidIDToken =
          [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeIDTokenFailedValidationError
                           underlyingError:nil
                               description:@"Audience mismatch"];
        dispatch_async(dispatch_get_main_queue(), ^{
          callback(nil, invalidIDToken);
        });
        return;
      }
      
      // OpenID Connect Core Section 3.1.3.7. rules #4 & #5
      // Not supported.

      // OpenID Connect Core Section 3.1.3.7. rule #6
      // As noted above, AppAuth only supports the code flow which results in direct communication
      // of the ID Token from the Token Endpoint to the Client, and we are exercising the option to
      // use TSL server validation instead of checking the token signature. Users may additionally
      // check the token signature should they wish.

      // OpenID Connect Core Section 3.1.3.7. rules #7 & #8
      // Not applicable. See rule #6.

      // OpenID Connect Core Section 3.1.3.7. rule #9
      // Validates that the current time is before the expiry time.
      NSTimeInterval expiresAtDifference = [idToken.expiresAt timeIntervalSinceNow];
      if (expiresAtDifference < 0) {
        NSError *invalidIDToken =
            [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeIDTokenFailedValidationError
                             underlyingError:nil
                                 description:@"ID Token expired"];
        dispatch_async(dispatch_get_main_queue(), ^{
          callback(nil, invalidIDToken);
        });
        return;
      }
      
      // OpenID Connect Core Section 3.1.3.7. rule #10
      // Validates that the issued at time is not more than +/- 10 minutes on the current time.
      NSTimeInterval issuedAtDifference = [idToken.issuedAt timeIntervalSinceNow];
      if (fabs(issuedAtDifference) > kEkoOIDAuthorizationSessionIATMaxSkew) {
        NSString *message =
            [NSString stringWithFormat:@"Issued at time is more than %d seconds before or after "
                                        "the current time",
                                       kEkoOIDAuthorizationSessionIATMaxSkew];
        NSError *invalidIDToken =
          [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeIDTokenFailedValidationError
                           underlyingError:nil
                               description:message];
        dispatch_async(dispatch_get_main_queue(), ^{
          callback(nil, invalidIDToken);
        });
        return;
      }

      // Only relevant for the authorization_code response type
      if ([tokenResponse.request.grantType isEqual:EkoOIDGrantTypeAuthorizationCode]) {
        // OpenID Connect Core Section 3.1.3.7. rule #11
        // Validates the nonce.
        NSString *nonce = authorizationResponse.request.nonce;
        if (nonce && ![idToken.nonce isEqual:nonce]) {
          NSError *invalidIDToken =
          [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeIDTokenFailedValidationError
                           underlyingError:nil
                               description:@"Nonce mismatch"];
          dispatch_async(dispatch_get_main_queue(), ^{
            callback(nil, invalidIDToken);
          });
          return;
        }
      }
      
      // OpenID Connect Core Section 3.1.3.7. rules #12
      // ACR is not directly supported by AppAuth.

      // OpenID Connect Core Section 3.1.3.7. rules #12
      // max_age is not directly supported by AppAuth.
    }

    // Success
    dispatch_async(dispatch_get_main_queue(), ^{
      callback(tokenResponse, nil);
    });
  }] resume];
}


#pragma mark - Registration Endpoint

+ (void)performRegistrationRequest:(EkoOIDRegistrationRequest *)request
                          completion:(EkoOIDRegistrationCompletion)completion {
  NSURLRequest *URLRequest = [request URLRequest];
  if (!URLRequest) {
    // A problem occurred deserializing the response/JSON.
    NSError *returnedError = [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeJSONSerializationError
                                              underlyingError:nil
                                                  description:@"The registration request could not "
                                                               "be serialized as JSON."];
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(nil, returnedError);
    });
    return;
  }

  NSURLSession *session = [EkoOIDURLSessionProvider session];
  [[session dataTaskWithRequest:URLRequest
              completionHandler:^(NSData *_Nullable data,
                                  NSURLResponse *_Nullable response,
                                  NSError *_Nullable error) {
    if (error) {
      // A network error or server error occurred.
      NSString *errorDescription =
          [NSString stringWithFormat:@"Connection error making registration request to '%@': %@.",
                                     URLRequest.URL,
                                     error.localizedDescription];
      NSError *returnedError = [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeNetworkError
                                                underlyingError:error
                                                    description:errorDescription];
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, returnedError);
      });
      return;
    }

    NSHTTPURLResponse *HTTPURLResponse = (NSHTTPURLResponse *) response;

    if (HTTPURLResponse.statusCode != 201 && HTTPURLResponse.statusCode != 200) {
      // A server error occurred.
      NSError *serverError = [EkoOIDErrorUtilities HTTPErrorWithHTTPResponse:HTTPURLResponse
                                                                     data:data];

      // HTTP 400 may indicate an OpenID Connect Dynamic Client Registration 1.0 Section 3.3 error
      // response, checks for that
      if (HTTPURLResponse.statusCode == 400) {
        NSError *jsonDeserializationError;
        NSDictionary<NSString *, NSObject <NSCopying> *> *json =
            [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonDeserializationError];

        // if the HTTP 400 response parses as JSON and has an 'error' key, it's an OAuth error
        // these errors are special as they indicate a problem with the authorization grant
        if (json[EkoOIDOAuthErrorFieldError]) {
          NSError *oauthError =
              [EkoOIDErrorUtilities OAuthErrorWithDomain:EkoOIDOAuthRegistrationErrorDomain
                                        OAuthResponse:json
                                      underlyingError:serverError];
          dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, oauthError);
          });
          return;
        }
      }

      // not an OAuth error, just a generic server error
      NSString *errorDescription =
          [NSString stringWithFormat:@"Non-200/201 HTTP response (%d) making registration request "
                                     "to '%@'.",
                                     (int)HTTPURLResponse.statusCode,
                                     URLRequest.URL];
      NSError *returnedError = [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeServerError
                                                underlyingError:serverError
                                                    description:errorDescription];
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, returnedError);
      });
      return;
    }

    NSError *jsonDeserializationError;
    NSDictionary<NSString *, NSObject <NSCopying> *> *json =
        [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonDeserializationError];
    if (jsonDeserializationError) {
      // A problem occurred deserializing the response/JSON.
      NSString *errorDescription =
          [NSString stringWithFormat:@"JSON error parsing registration response: %@",
                                     jsonDeserializationError.localizedDescription];
      NSError *returnedError = [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeJSONDeserializationError
                                                underlyingError:jsonDeserializationError
                                                    description:errorDescription];
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, returnedError);
      });
      return;
    }

    EkoOIDRegistrationResponse *registrationResponse =
        [[EkoOIDRegistrationResponse alloc] initWithRequest:request
                                              parameters:json];
    if (!registrationResponse) {
      // A problem occurred constructing the registration response from the JSON.
      NSError *returnedError =
          [EkoOIDErrorUtilities errorWithCode:EkoOIDErrorCodeRegistrationResponseConstructionError
                           underlyingError:nil
                               description:@"Registration response invalid."];
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, returnedError);
      });
      return;
    }

    // Success
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(registrationResponse, nil);
    });
  }] resume];
}

@end

NS_ASSUME_NONNULL_END
