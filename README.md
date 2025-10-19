# BearerTokenAuthenticationMiddleware

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS-blue.svg)

A lightweight, concurrency-safe Swift middleware that injects a **Bearer token** into outgoing OpenAPI client requests.

Built for `OpenAPIRuntime`, this package provides a composable, dependency-free way to handle token-based authentication in OpenAPI-generated Swift clients.

---

## 🧩 Overview

`BearerTokenAuthenticationMiddleware` automatically adds an `Authorization` header to each outgoing request, using the standard `Bearer <token>` format.

It’s thread-safe, actor-isolated, and works seamlessly with other OpenAPI middlewares such as:

- [`OpenAPILoggingMiddleware`](https://github.com/mihaelamj/OpenAPILoggingMiddleware)
- `APICorrectionMiddleware`
- or any custom middlewares in your stack.

You can dynamically update the token at runtime, and even decide **which operations** should skip authentication (for example, public endpoints).

---

## 🚀 Installation

Add the package to your **`Package.swift`**:

```swift
.package(url: "https://github.com/mihaelamj/BearerTokenAuthMiddleware.git", from: "1.0.0")
```

and include it in your target dependencies:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "BearerTokenAuthMiddleware", package: "BearerTokenAuthMiddleware")
    ]
)
```

Then import it:

```swift
import BearerTokenAuthMiddleware
```

---

## ⚙️ Usage

### Basic setup

```swift
import OpenAPIRuntime
import BearerTokenAuthMiddleware

let authMiddleware = BearerTokenAuthenticationMiddleware(
    initialToken: "my-secret-token"
)

let client = Client(
    serverURL: URL(string: "https://api.example.com")!,
    transport: AsyncHTTPClientTransport(),
    middlewares: [authMiddleware]
)
```

Each request sent through this client will automatically include:

```
Authorization: Bearer my-secret-token
```

---

### Conditional Authorization

You can specify which endpoints should **skip** authentication by providing a `skipAuthorization` closure:

```swift
let authMiddleware = BearerTokenAuthenticationMiddleware(
    initialToken: "public-or-private",
    skipAuthorization: { operationID in
        // Return true to skip adding the Authorization header
        ["login", "register", "healthcheck"].contains(operationID)
    }
)
```

---

### Updating the token at runtime

Because the middleware manages token state through a dedicated actor, you can safely update the token from any async context:

```swift
authMiddleware.updateToken("new-access-token")
```

The next outgoing request will use the updated token automatically.

---

## 🧠 How It Works

The middleware wraps outgoing `HTTPRequest` objects and, unless excluded by your `skipAuthorization` rule, injects a header in the following format:

```
Authorization: Bearer <token>
```

The token itself is stored inside an internal `TokenStorage` actor:

```swift
private actor TokenStorage {
    var token: String?
    
    func getToken() -> String? { token }
    func setToken(_ newToken: String?) { token = newToken }
}
```

This ensures the token is **never accessed concurrently** or mutated outside an isolated context — an important detail when using Swift Concurrency in multi-request environments.

---

## 🔒 Example Integration with `ApiClient`

This package fits naturally into a middleware chain.
For example, here’s how it integrates in a real-world client alongside `OpenAPILoggingMiddleware` and other middlewares:

```swift
import Foundation
import OpenAPIRuntime
import OpenAPIAsyncHTTPClient
import OpenAPILoggingMiddleware
import BearerTokenAuthMiddleware

public actor ApiClient {
    public var client: Client

    public init(environment: ServerEnvironment) async throws {
        let authMiddleware = BearerTokenAuthenticationMiddleware(
            initialToken: await ApiClientState.shared.token,
            skipAuthorization: { operationID in
                await ApiClientState.shared.isPublicOperation(operationID)
            }
        )
        
        let loggingMiddleware = LoggingMiddleware(appName: "NSSpainAPI", logPrefix: "🚚 APIClient: ")
        
        let serverURL = try environment.getURL()
        client = Client(
            serverURL: serverURL,
            transport: AsyncHTTPClientTransport(),
            middlewares: [loggingMiddleware, authMiddleware]
        )
    }
}
```

This design allows you to toggle authentication and logging dynamically via a shared `ApiClientState` actor.

---

## 🧰 API Reference

### `init(initialToken:skipAuthorization:)`

Creates a new middleware.

| Parameter | Description |
|------------|-------------|
| `initialToken` | The initial bearer token (without “Bearer” prefix). |
| `skipAuthorization` | Closure that determines whether to skip adding the header for a given `operationID`. Defaults to `false` for all. |

### `func updateToken(_ newToken: String?)`

Updates the current bearer token. Thread-safe and async-safe.

---

## ✅ Example Output

```
[POST] /api/user/profile (200 OK)
Authorization: Bearer 9b0f0d9e-XXXX-XXXX-XXXX-XXXXXXXXXXXX
Duration: 120 ms
```

---

## 🧪 Tests & Stability

- 100% Swift Concurrency–safe (`Sendable`, `actor` isolation)
- Zero dependencies
- Designed for Swift 6.0+ toolchains
- Compatible with `OpenAPIRuntime`, `OpenAPIVapor`, and `OpenAPIAsyncHTTPClient`

---

## 📄 License

MIT License © 2025 [Mihaela Mihaljević Jakić](https://github.com/mihaelamj)

---

> “Clean code should be composable, testable, and visible when it runs.”
