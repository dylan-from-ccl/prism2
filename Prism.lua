---- Importing the Prism framework from the ReplicatedStorage
--local PrismObject = game.ReplicatedStorage:WaitForChild("Prism", 2)

----if not PrismObject then 
----	PrismObject = script.Parent.Prism
----	PrismObject.Parent = game.ReplicatedStorage
----else
----	script.Parent.Prism:Destroy()
----end

--local PrismFramework = require(PrismObject)

----script.Parent.Parent = game.ServerScriptService

---- Configuration settings
--local Config = {
--}

--local Ext = {}
--local Internal = {}
----Internal.Version = script.Parent.Version.Value
----local camera = workspace.CurrentCamera

---- Authenticates with the Prism framework and starts the service
--function Internal:AuthenticateWithPrism(AppData)
--	local APIPackage = PrismFramework:AuthenticateDriver(script, AppData)

--	if not APIPackage then 
--		error("Prism authentication failure, halting thread execution")
--	end
--	Internal.PrivateKey = APIPackage.Key
--	Internal.AppAPI = APIPackage.AppAPI 
--	Internal.PrismCore = APIPackage.PrismCore
--end
---- AppData for DataPlus, containing metadata
--local AppData = {
--	Version = "1.0.0",
--	API = {}, -- Driver-specific API
--	FriendlyName = "ExampleDriver",
--	UniquePhrase = "SecureDriverPhrase123", -- The unique phrase for this driver
--	Depends = {}, -- Dependencies
--}

--Internal:AuthenticateWithPrism(AppData)

--local function wr(...)
--	Internal.AppAPI:Write(Internal.PrivateKey, ...)
--end

--wr("generating memory dump.....")
--print("memory dump:", Internal.PrismCore)
--wait(10) 
--wr("setdata")
--Internal.AppAPI:f(Internal.PrivateKey, "SetData", "PlayerScore", 100) 
--wait(1)
--wr("getdata")
--wr(Internal.AppAPI:f(Internal.PrivateKey, "GetData", "PlayerScore")) 


-- Define the driver and its data
local SimpleDriver = {
	Name = "SimpleDriver", -- Driver name
	Version = "1.0.0", -- Version of the driver
	FriendlyName = "Simple Driver", -- Display name
	UniquePhrase = "SecureDriverPhrase123", -- Driver's unique security phrase
	API = {}, -- Define functions that this driver exposes
}

-- Add a function to the driver's API
function SimpleDriver.API.SayHello()
	print("Hello from SimpleDriver!")
end

-- Add another API function
function SimpleDriver.API.GetServerTime()
	return os.time()
end

-- Function to authenticate the driver with Prism
local function AuthenticateDriver()
	-- Locate PrismCore in ReplicatedStorage
	local PrismCoreModule = game.ReplicatedStorage:WaitForChild("Prism")

	-- Ensure PrismCore is available
	if not PrismCoreModule then
		warn("PrismCore module not found in ReplicatedStorage!")
		return nil
	end

	-- Require the PrismCore module
	local PrismCore = require(PrismCoreModule)

	-- Attempt to authenticate the driver
	local success, PrismAPI = pcall(function()
		return PrismCore:AuthenticateDriver(script, SimpleDriver)
	end)

	if success and PrismAPI then
		print("SimpleDriver authenticated successfully!")
		return PrismAPI -- Return the authenticated API
	else
		warn("Failed to authenticate SimpleDriver with Prism.")
		return nil
	end
end

-- Authenticate the driver and retrieve its API
local PrismAPI = AuthenticateDriver()

-- Verify the connection and test the driver
if PrismAPI then
	-- Log the success
	PrismAPI.PrismCore.Logic.CommonFunctions:Write(PrismAPI.Key, "SimpleDriver\nis\nrunning\nand\nconnected\nto\nPrism.")

	-- Use the driver's API to call a function
	local serverTime = SimpleDriver.API.GetServerTime()
	PrismAPI.PrismCore.Logic.CommonFunctions:Write(PrismAPI.Key, "The server time is: " .. serverTime)

	-- Demonstrate using an API function exposed by Prism
	local success = PrismAPI.PrismCore.Logic.CommonFunctions:BitSet(PrismAPI.Key, "SimpleDriverData", "TestValue", 456)
	if success then
		print("Successfully set a test value in Prism!")
	else
		warn("Failed to set a test value in Prism.")
	end
end
