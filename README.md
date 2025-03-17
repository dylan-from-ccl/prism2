# Prism Framework

```
  ____       _                 ____  
 |  _ \ _ __(_)___ _ __ ___   |___ \ 
 | |_) | '__| / __| '_ ` _ \    __) |
 |  __/| |  | \__ \ | | | | |  / __/ 
 |_|   |_|  |_|___/_| |_| |_| |_____|
```

Prism is an open-source framework designed to empower developers on Roblox by streamlining the way applications and drivers interact and operate. As the successor to Prism 1, it provides a structured, secure foundation that simplifies managing interconnected systems, enabling you to focus on innovation and creativity.

With Prism, you can build scalable, organized, and collaborative projects, unlocking new possibilities for seamless integration and efficient development.

## Best Use Cases

- **Rapid Development**: Quickly build and deploy games and plugins.
- **Secure Development**: Ensure secure interactions between applications and drivers.
- **Scalable Projects**: Develop projects that can easily scale with your needs.
- **Collaborative Projects**: Simplify collaboration among multiple developers.

## External API Functions

### `PrismCore.Logic.ExternalFunctions:Authenticate(App, AppData)`

**Description**: Authenticates an application with Prism.

**Parameters**:
- `App`: The application instance to authenticate.
- `AppData`: Metadata about the application, including API and dependencies.

**Returns**: An API package for the app.

### `PrismCore.Logic.ExternalFunctions:AuthenticateDriver(Driver, DriverData)`

**Description**: Authenticates a driver with Prism.

**Parameters**:
- `Driver`: The driver instance to authenticate.
- `DriverData`: Metadata about the driver, including API and unique fingerprint.

**Returns**: An API package for the driver.

### `PrismCore.Logic.CommonFunctions:Write(Key, ...)`

**Description**: Logs messages with security and application context.

**Parameters**:
- `Key`: The app's private key or security context.
- `...`: The messages to log.

### `PrismCore.Logic.CommonFunctions:GenerateKey(ForcedKeyLength, ForcedTimeout)`

**Description**: Generates a secure, unique key for use in the framework.

**Parameters**:
- `ForcedKeyLength`: Optional parameter to specify the key length (default: 16).
- `ForcedTimeout`: Optional parameter to specify the timeout for generation (default: 10 seconds).

**Returns**: A unique key.

### `PrismCore.Logic.CommonFunctions:Prod(PrivateKey, Properties)`

**Description**: Creates a new Roblox instance and applies properties.

**Parameters**:
- `PrivateKey`: The app's private key (optional).
- `Properties`: Table containing the ClassName and other properties to set on the instance.

**Returns**: The created instance.

### `PrismCore.Logic.CommonFunctions:BitSet(PrivateKey, Namespace, ValName, Val, Expiration, Persist, Callback)`

**Description**: Securely sets a value in the system memory namespace for an application.

**Parameters**:
- `PrivateKey`: The app's private key for authentication.
- `Namespace`: A logical grouping to organize stored values.
- `ValName`: The name of the value to set.
- `Val`: The value to store.
- `Expiration`: Optional expiration time in seconds.
- `Persist`: Reserved for future use to support persistence.
- `Callback`: Function to execute upon expiration of the value.

**Returns**: `true` if the operation is successful.

### `PrismCore.Logic.CommonFunctions:BitGet(PrivateKey, Namespace, ValName, Default)`

**Description**: Securely retrieves a value from the system memory namespace for an application.

**Parameters**:
- `PrivateKey`: The app's private key for authentication.
- `Namespace`: A logical grouping to organize stored values.
- `ValName`: The name of the value to retrieve.
- `Default`: The default value to return if the requested value is not found.

**Returns**: The retrieved value or the default value if not found.

## Sample App

```lua
-- Define the app and its data
local SimpleApp = {
	Name = "SimpleApp", -- App name
	Version = "1.0.0", -- Version of the app
	FriendlyName = "Simple Application", -- Display name
	Depends = {}, -- No dependencies for this example
	API = {}, -- Define functions that this app exposes
}

-- Function to authenticate the app with Prism
local function AuthenticateApp()
	-- Locate PrismCore in ReplicatedStorage
	local PrismCoreModule = game.ReplicatedStorage:WaitForChild("Prism")

	-- Ensure PrismCore is available
	if not PrismCoreModule then
		warn("PrismCore module not found in ReplicatedStorage!")
		return nil
	end

	-- Require the PrismCore module
	local PrismCore = require(PrismCoreModule)

	-- Attempt to authenticate the app
	local success, PrismAPI = pcall(function()
		return PrismCore:Authenticate(script, SimpleApp)
	end)

	if success and PrismAPI then
		print("SimpleApp authenticated successfully!")
		return PrismAPI -- Return the authenticated API
	else
		return nil
	end
end

-- Authenticate the app and retrieve its API
local PrismAPI = AuthenticateApp()

-- Verify the connection and test the app
if PrismAPI then
	-- Log the success
	PrismAPI.AppAPI:Write(PrismAPI.Key, "Hello world")

	-- Demonstrate using an API function exposed by Prism
	local success = PrismAPI.AppAPI:BitSet(PrismAPI.Key, "SimpleAppData", "TestValue", 123)
	if success then
		PrismAPI.AppAPI:Write("Successfully set a test value in Prism!")
	else
		PrismAPI.AppAPI:Write("Failed to set a test value in Prism.")
	end
end


```

## Difference Between Apps and Drivers

**Apps**:
- Applications are general-purpose scripts that utilize Prism for various functionalities.
- They interact with the framework using the provided API and can depend on other applications or drivers.

**Drivers**:
- Drivers are specialized scripts with elevated security and control within the Prism framework.
- They have unique phrases for authentication and are registered with specific privileges.

For more information, please refer to the source code and additional documentation provided within the framework.
