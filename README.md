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

CloudSDK.instance.createSession(for: authRequest, needsAuthentication: { webview in
  // adjust the style of the webview by setting tintColor and barTintColor
  // present the webview in your app so the user can log in and grant authorization to your app
}, authenticated: {
  // dismiss the webview
  // user granted authorization, continue with your requests
}, failure: { error in
  // dismiss the webview
  // user cancelled the authorization or an error occured
})
```

### Get user information

Once your app is authenticated, you can access the users information:

```swift
CloudSDK.instance.getUserInfo(completion: { user in
  // handle user information
}, failure: { (error, statusCode) in
  // an error occured
})
```

### Perform Authenticated requests

Once your app is authenticated, you can perform authenticated requests with the PACE backend. Requests to an URL other than the PACE API are rejected.

```swift
let request = URLRequest(url: url)
CloudSDK.instance.perform(request: request) { (data, response, error) in
  // handle response
}
```

### Check if a valid session exists

```swift
CloudSDK.instance.hasValidSession { hasValidSession in
  // sessions are renewed automatically by CloudSDK
  // if the session is invalid you may need to authenticate again
}
```

### Get short lived session token

```swift
CloudSDK.instance.getSessionToken { sessionToken in
  // nil if no session exists or token is invalid
}
```

### Logout

You can logout and remove the session from the keychain:

```swift
CloudSDK.instance.logout()
```
