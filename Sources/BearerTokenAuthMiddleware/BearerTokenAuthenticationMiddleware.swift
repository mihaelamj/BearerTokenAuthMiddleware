import OpenAPIRuntime
import Foundation
import HTTPTypes

// An actor to manage the authentication token state thread-safely.
// This is kept internal to the middleware's implementation.
private actor TokenStorage {
    var token: String?
    
    func getToken() -> String? {
        token
    }
    
    func setToken(_ newToken: String?) {
        token = newToken
    }
}

/// A client middleware that injects a bearer token into the `Authorization` header of requests.
public struct BearerTokenAuthenticationMiddleware {
    
    private let storage = TokenStorage()
    
    /// A closure to determine whether the authorization header should be skipped for a given operation.
    private let skipAuthorization: @Sendable (String) -> Bool

    /// Creates a new middleware for bearer token authentication.
    ///
    /// - Parameters:
    ///   - initialToken: The initial bearer token (without the "Bearer " prefix).
    ///   - skipAuthorization: A closure that returns `true` if the authorization header
    ///     should be omitted for a specific `operationID`. Defaults to `false` for all operations.
    public init(
        initialToken: String?,
        skipAuthorization: @escaping @Sendable (String) -> Bool = { _ in false }
    ) {
        self.skipAuthorization = skipAuthorization
        // Set initial token without capturing self in an escaping context.
        Task { [storage] in
            await storage.setToken(initialToken)
        }
    }
    
    /// Updates the bearer token value.
    /// - Parameter newToken: The new bearer token (without the "Bearer " prefix).
    public func updateToken(_ newToken: String?) {
        Task { [storage] in
            await storage.setToken(newToken)
        }
    }
}

extension BearerTokenAuthenticationMiddleware: ClientMiddleware {
    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        // If the skip condition is met, proceed without adding the Authorization header.
        if skipAuthorization(operationID) {
            return try await next(request, body, baseURL)
        }
        
        var modifiedRequest = request
        
        // Retrieve the token from storage and add the "Bearer " prefix.
        if let token = await storage.getToken() {
            modifiedRequest.headerFields[.authorization] = "Bearer \(token)"
        }
        
        return try await next(modifiedRequest, body, baseURL)
    }
}
