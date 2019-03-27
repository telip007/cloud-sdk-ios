# PACE Cloud SDK for iOS

## Getting Started

Link the CloudSDK.framework with your project as `Embedded Binary`.

## Usage

### OAuth Authentication

To authenticate with PACE via OAuth provide the following information to Cloud SDK:
- clientId
- clientSecret
- redirectUrl
- scope

```swift
let authRequest = AuthorizationRequest(clientId: "ABC",
                                       clientSecret: "XYZ",
                                       redirectUrl: "CloudSDK://oauth",
                                       scope: "read")

CloudSDK.shared.createSession(for: authRequest, needsAuthentication: { webview in
  // adjust the style of the webview by setting tintColor and barTintColor
  // present the webview in your app so the user can log in and grant authorization to your app
}, authenticated: { token in
  // dismiss the webview
  // user granted authorization, continue with your requests
}, failure: { error in
  // dismiss the webview
  // user cancelled the authorization or an error occurred
})
```

### Get user information

Once your app is authenticated, you can access the users information:

```swift
CloudSDK.shared.getUserInfo(completion: { user in
  // handle user information
}, failure: { (error, statusCode) in
  // an error occurred
})
```

### Perform Authenticated requests

Once your app is authenticated, you can perform authenticated requests with the PACE backend. Requests to an URL other than the PACE API are rejected.

```swift
let request = URLRequest(url: url)
CloudSDK.shared.perform(request: request) { (data, response, error) in
  // handle response
}
```

### Check if a valid session exists

```swift
CloudSDK.shared.hasValidSession { hasValidSession in
  // sessions are renewed automatically by CloudSDK
  // if the session is invalid you may need to authenticate again
}
```

### Get short lived session token

```swift
CloudSDK.shared.getSessionToken { sessionToken in
  // nil if no session exists or token is invalid
}
```

### Logout

You can logout and remove the session from the keychain:

```swift
CloudSDK.shared.logout()
```
