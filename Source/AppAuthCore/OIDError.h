/*! @file EkoOIDError.h
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

NS_ASSUME_NONNULL_BEGIN

/*! @brief The error domain for all NSErrors returned from the AppAuth library.
 */
extern NSString *const EkoOIDGeneralErrorDomain;

/*! @brief The error domain for OAuth specific errors on the authorization endpoint.
    @discussion This error domain is used when the server responds to an authorization request
        with an explicit OAuth error, as defined by RFC6749 Section 4.1.2.1. If the authorization
        response is invalid and not explicitly an error response, another error domain will be used.
        The error response parameter dictionary is available in the
        \NSError_userInfo dictionary using the @c ::EkoOIDOAuthErrorResponseErrorKey key.
        The \NSError_code will be one of the @c ::EkoOIDErrorCodeOAuthAuthorization enum values.
    @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
 */
extern NSString *const EkoOIDOAuthAuthorizationErrorDomain;

/*! @brief The error domain for OAuth specific errors on the token endpoint.
    @discussion This error domain is used when the server responds with HTTP 400 and an OAuth error,
        as defined RFC6749 Section 5.2. If an HTTP 400 response does not parse as an OAuth error
        (i.e. no 'error' field is present or the JSON is invalid), another error domain will be
        used. The entire OAuth error response dictionary is available in the \NSError_userInfo
        dictionary using the @c ::EkoOIDOAuthErrorResponseErrorKey key. Unlike transient network
        errors, errors in this domain invalidate the authentication state, and either indicate a
        client error or require user interaction (i.e. reauthentication) to resolve.
        The \NSError_code will be one of the @c ::EkoOIDErrorCodeOAuthToken enum values.
    @see https://tools.ietf.org/html/rfc6749#section-5.2
 */
extern NSString *const EkoOIDOAuthTokenErrorDomain;

/*! @brief The error domain for dynamic client registration errors.
    @discussion This error domain is used when the server responds with HTTP 400 and an OAuth error,
         as defined in OpenID Connect Dynamic Client Registration 1.0 Section 3.3. If an HTTP 400
         response does not parse as an OAuth error (i.e. no 'error' field is present or the JSON is
         invalid), another error domain will be  used. The entire OAuth error response dictionary is
         available in the \NSError_userInfo dictionary using the @c ::EkoOIDOAuthErrorResponseErrorKey
         key. Unlike transient network errors, errors in this domain invalidate the authentication
         state, and indicates a client error.
         The \NSError_code will be one of the @c ::EkoOIDErrorCodeOAuthToken enum values.
     @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationError
 */
extern NSString *const EkoOIDOAuthRegistrationErrorDomain;

/*! @brief The error domain for authorization errors encountered out of band on the resource server.
 */
extern NSString *const EkoOIDResourceServerAuthorizationErrorDomain;

/*! @brief An error domain representing received HTTP errors.
 */
extern NSString *const EkoOIDHTTPErrorDomain;

/*! @brief An error key for the original OAuth error response (if any).
 */
extern NSString *const EkoOIDOAuthErrorResponseErrorKey;

/*! @brief The key of the 'error' response field in a RFC6749 Section 5.2 response.
    @remark error
    @see https://tools.ietf.org/html/rfc6749#section-5.2
 */
extern NSString *const EkoOIDOAuthErrorFieldError;

/*! @brief The key of the 'error_description' response field in a RFC6749 Section 5.2 response.
    @remark error_description
    @see https://tools.ietf.org/html/rfc6749#section-5.2
 */
extern NSString *const EkoOIDOAuthErrorFieldErrorDescription;

/*! @brief The key of the 'error_uri' response field in a RFC6749 Section 5.2 response.
    @remark error_uri
    @see https://tools.ietf.org/html/rfc6749#section-5.2
 */
extern NSString *const EkoOIDOAuthErrorFieldErrorURI;

/*! @brief The various error codes returned from the AppAuth library.
 */
typedef NS_ENUM(NSInteger, EkoOIDErrorCode) {
  /*! @brief Indicates a problem parsing an OpenID Connect Service Discovery document.
   */
  EkoOIDErrorCodeInvalidDiscoveryDocument = -2,

  /*! @brief Indicates the user manually canceled the OAuth authorization code flow.
   */
  EkoOIDErrorCodeUserCanceledAuthorizationFlow = -3,

  /*! @brief Indicates an OAuth authorization flow was programmatically cancelled.
   */
  EkoOIDErrorCodeProgramCanceledAuthorizationFlow = -4,

  /*! @brief Indicates a network error or server error occurred.
   */
  EkoOIDErrorCodeNetworkError = -5,

  /*! @brief Indicates a server error occurred.
   */
  EkoOIDErrorCodeServerError = -6,

  /*! @brief Indicates a problem occurred deserializing the response/JSON.
   */
  EkoOIDErrorCodeJSONDeserializationError = -7,

  /*! @brief Indicates a problem occurred constructing the token response from the JSON.
   */
  EkoOIDErrorCodeTokenResponseConstructionError = -8,

  /*! @brief @c UIApplication.openURL: returned NO when attempting to open the authorization
          request in mobile Safari.
   */
  EkoOIDErrorCodeSafariOpenError = -9,

  /*! @brief @c NSWorkspace.openURL returned NO when attempting to open the authorization
          request in the default browser.
   */
  EkoOIDErrorCodeBrowserOpenError = -10,

  /*! @brief Indicates a problem when trying to refresh the tokens.
   */
  EkoOIDErrorCodeTokenRefreshError = -11,

  /*! @brief Indicates a problem occurred constructing the registration response from the JSON.
   */
  EkoOIDErrorCodeRegistrationResponseConstructionError = -12,

  /*! @brief Indicates a problem occurred deserializing the response/JSON.
   */
  EkoOIDErrorCodeJSONSerializationError = -13,

  /*! @brief The ID Token did not parse.
   */
  EkoOIDErrorCodeIDTokenParsingError = -14,

  /*! @brief The ID Token did not pass validation (e.g. issuer, audience checks).
   */
  EkoOIDErrorCodeIDTokenFailedValidationError = -15,
};

/*! @brief Enum of all possible OAuth error codes as defined by RFC6749
    @discussion Used by @c ::EkoOIDErrorCodeOAuthAuthorization and @c ::EkoOIDErrorCodeOAuthToken
        which define endpoint-specific subsets of OAuth codes. Those enum types are down-castable
        to this one.
    @see https://tools.ietf.org/html/rfc6749#section-11.4
    @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
    @see https://tools.ietf.org/html/rfc6749#section-5.2
 */
typedef NS_ENUM(NSInteger, EkoOIDErrorCodeOAuth) {

  /*! @remarks invalid_request
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthInvalidRequest = -2,

  /*! @remarks unauthorized_client
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthUnauthorizedClient = -3,

  /*! @remarks access_denied
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  EkoOIDErrorCodeOAuthAccessDenied = -4,

  /*! @remarks unsupported_response_type
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  EkoOIDErrorCodeOAuthUnsupportedResponseType = -5,

  /*! @remarks invalid_scope
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthInvalidScope = -6,

  /*! @remarks server_error
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  EkoOIDErrorCodeOAuthServerError = -7,

  /*! @remarks temporarily_unavailable
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  EkoOIDErrorCodeOAuthTemporarilyUnavailable = -8,

  /*! @remarks invalid_client
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthInvalidClient = -9,

  /*! @remarks invalid_grant
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthInvalidGrant = -10,

  /*! @remarks unsupported_grant_type
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthUnsupportedGrantType = -11,

  /*! @remarks invalid_redirect_uri
      @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationError
   */
  EkoOIDErrorCodeOAuthInvalidRedirectURI = -12,

  /*! @remarks invalid_client_metadata
      @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationError
   */
  EkoOIDErrorCodeOAuthInvalidClientMetadata = -13,

  /*! @brief An authorization error occurring on the client rather than the server. For example,
        due to a state mismatch or misconfiguration. Should be treated as an unrecoverable
        authorization error.
   */
  EkoOIDErrorCodeOAuthClientError = -0xEFFF,

  /*! @brief An OAuth error not known to this library
      @discussion Indicates an OAuth error as per RFC6749, but the error code was not in our
          list. It could be a custom error code, or one from an OAuth extension. See the "error" key
          of the \NSError_userInfo property. Such errors are assumed to invalidate the
          authentication state
   */
  EkoOIDErrorCodeOAuthOther = -0xF000,
};

/*! @brief The error codes for the @c ::EkoOIDOAuthAuthorizationErrorDomain error domain
    @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
 */
typedef NS_ENUM(NSInteger, EkoOIDErrorCodeOAuthAuthorization) {
  /*! @remarks invalid_request
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  EkoOIDErrorCodeOAuthAuthorizationInvalidRequest = EkoOIDErrorCodeOAuthInvalidRequest,

  /*! @remarks unauthorized_client
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  EkoOIDErrorCodeOAuthAuthorizationUnauthorizedClient = EkoOIDErrorCodeOAuthUnauthorizedClient,

  /*! @remarks access_denied
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  EkoOIDErrorCodeOAuthAuthorizationAccessDenied =
      EkoOIDErrorCodeOAuthAccessDenied,

  /*! @remarks unsupported_response_type
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  EkoOIDErrorCodeOAuthAuthorizationUnsupportedResponseType =
      EkoOIDErrorCodeOAuthUnsupportedResponseType,

  /*! @brief Indicates a network error or server error occurred.
      @remarks invalid_scope
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  EkoOIDErrorCodeOAuthAuthorizationAuthorizationInvalidScope = EkoOIDErrorCodeOAuthInvalidScope,

  /*! @brief Indicates a server error occurred.
      @remarks server_error
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  EkoOIDErrorCodeOAuthAuthorizationServerError = EkoOIDErrorCodeOAuthServerError,

  /*! @remarks temporarily_unavailable
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  EkoOIDErrorCodeOAuthAuthorizationTemporarilyUnavailable = EkoOIDErrorCodeOAuthTemporarilyUnavailable,

  /*! @brief An authorization error occurring on the client rather than the server. For example,
        due to a state mismatch or client misconfiguration. Should be treated as an unrecoverable
        authorization error.
   */
  EkoOIDErrorCodeOAuthAuthorizationClientError = EkoOIDErrorCodeOAuthClientError,

  /*! @brief An authorization OAuth error not known to this library
      @discussion this indicates an OAuth error as per RFC6749, but the error code was not in our
          list. It could be a custom error code, or one from an OAuth extension. See the "error" key
          of the \NSError_userInfo property. We assume such errors are not transient.
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  EkoOIDErrorCodeOAuthAuthorizationOther = EkoOIDErrorCodeOAuthOther,
};


/*! @brief The error codes for the @c ::EkoOIDOAuthTokenErrorDomain error domain
    @see https://tools.ietf.org/html/rfc6749#section-5.2
 */
typedef NS_ENUM(NSInteger, EkoOIDErrorCodeOAuthToken) {
  /*! @remarks invalid_request
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthTokenInvalidRequest = EkoOIDErrorCodeOAuthInvalidRequest,

  /*! @remarks invalid_client
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthTokenInvalidClient = EkoOIDErrorCodeOAuthInvalidClient,

  /*! @remarks invalid_grant
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthTokenInvalidGrant = EkoOIDErrorCodeOAuthInvalidGrant,

  /*! @remarks unauthorized_client
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthTokenUnauthorizedClient = EkoOIDErrorCodeOAuthUnauthorizedClient,

  /*! @remarks unsupported_grant_type
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthTokenUnsupportedGrantType = EkoOIDErrorCodeOAuthUnsupportedGrantType,

  /*! @remarks invalid_scope
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthTokenInvalidScope = EkoOIDErrorCodeOAuthInvalidScope,

  /*! @brief An unrecoverable token error occurring on the client rather than the server.
   */
  EkoOIDErrorCodeOAuthTokenClientError = EkoOIDErrorCodeOAuthClientError,

  /*! @brief A token endpoint OAuth error not known to this library
      @discussion this indicates an OAuth error as per RFC6749, but the error code was not in our
          list. It could be a custom error code, or one from an OAuth extension. See the "error" key
          of the \NSError_userInfo property. We assume such errors are not transient.
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthTokenOther = EkoOIDErrorCodeOAuthOther,
};

/*! @brief The error codes for the @c ::EkoOIDOAuthRegistrationErrorDomain error domain
    @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationError
 */
typedef NS_ENUM(NSInteger, EkoOIDErrorCodeOAuthRegistration) {
  /*! @remarks invalid_request
      @see http://tools.ietf.org/html/rfc6750#section-3.1
   */
  EkoOIDErrorCodeOAuthRegistrationInvalidRequest = EkoOIDErrorCodeOAuthInvalidRequest,

  /*! @remarks invalid_redirect_uri
      @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationError
   */
  EkoOIDErrorCodeOAuthRegistrationInvalidRedirectURI = EkoOIDErrorCodeOAuthInvalidRedirectURI,

  /*! @remarks invalid_client_metadata
      @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationError
   */
  EkoOIDErrorCodeOAuthRegistrationInvalidClientMetadata = EkoOIDErrorCodeOAuthInvalidClientMetadata,

  /*! @brief An unrecoverable token error occurring on the client rather than the server.
   */
  EkoOIDErrorCodeOAuthRegistrationClientError = EkoOIDErrorCodeOAuthClientError,

  /*! @brief A registration endpoint OAuth error not known to this library
      @discussion this indicates an OAuth error, but the error code was not in our
          list. It could be a custom error code, or one from an OAuth extension. See the "error" key
          of the \NSError_userInfo property. We assume such errors are not transient.
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  EkoOIDErrorCodeOAuthRegistrationOther = EkoOIDErrorCodeOAuthOther,
};


/*! @brief The exception text for the exception which occurs when a
        @c EkoOIDExternalUserAgentSession receives a message after it has already completed.
 */
extern NSString *const EkoOIDOAuthExceptionInvalidAuthorizationFlow;

/*! @brief The text for the exception which occurs when a Token Request is constructed
        with a null redirectURL for a grant_type that requires a nonnull Redirect
 */
extern NSString *const EkoOIDOAuthExceptionInvalidTokenRequestNullRedirectURL;

NS_ASSUME_NONNULL_END
