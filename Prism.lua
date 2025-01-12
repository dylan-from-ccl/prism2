
--[[

  ____       _                 ____  
 |  _ \ _ __(_)___ _ __ ___   |___ \ 
 | |_) | '__| / __| '_ ` _ \    __) |
 |  __/| |  | \__ \ | | | | |  / __/ 
 |_|   |_|  |_|___/_| |_| |_| |_____|
                                     
  
  An open-source project by Carr Creative Labs

  ┏┓┏┓┓ 
  ┃ ┃ ┃ 
  ┗┛┗┛┗┛
      
      

                                                
]]


-- These are three security clearance levels we want to create
local PrismCore = {} -- Functions accessable only within Prism's core, these are the most sensitive functions.

-- These are protected variables, that cannot be accessed from anything except Prism. 
-- Please note: in client environments, this data can still be accessed through external software


-- Establish the table for our services
PrismCore.Services = {} 

PrismCore.Logic = {}
PrismCore.Logic.Toolkit = {}
PrismCore.Logic.CommonFunctions = {} 
PrismCore.Logic.ExternalFunctions = {} 
PrismCore.Logic.CharsTable = {}
PrismCore.Logic.FunctionsOnHeartbeat = {} -- Every function in this table is executed on each heartbeat. Only accessable by drivers/internally.

PrismCore.Analytics = {}  -- Table containing 

PrismCore.Analytics.Applications = {}
PrismCore.Analytics.Applications.ApiCallCount = {} -- Dictionary using application keys, and the amount of times that PRocessFcn has been used on this application 
PrismCore.Analytics.Applications.ResponseTimes = {} -- Dictionary using application keys, containing each response time when processfcn is used and the app responds  
PrismCore.Analytics.Applications.AvgResponseTime = {} -- using the above ResponseTimes, when updating responsetimes create an average of all the numbers in that ResponseTimes table 

PrismCore.Analytics.Internal = {}
PrismCore.Analytics.Internal.BitGetTotalCalls = 0 -- Number of times BitGet has been called
PrismCore.Analytics.Internal.BitSetTotalCalls = 0  -- Number of times BitSEt has been called 
PrismCore.Analytics.Internal.ProdAllInstances = {} -- This table stores all instances produces by the Prod() function. Only accessable by drivers/internally.

PrismCore.Kernel = {} 
PrismCore.Kernel.Version = "2.0b"
PrismCore.Kernel.DriverManagement = {} 
PrismCore.Kernel.DriverManagement.Unsigned = {}
PrismCore.Kernel.DriverManagement.Signed = {} 
PrismCore.Kernel.Security = {}
PrismCore.Kernel.Cache = {}
PrismCore.Kernel.Cache.AppStrToKey  = {} -- [App Name]    = Private Key (string)
PrismCore.Kernel.Cache.KeyToAppInst = {} -- [Private Key] = App Instance (script)
PrismCore.Kernel.Cache.KeyToAppAPI  = {} -- [Private Key] = App's shared API (table)
PrismCore.Kernel.Cache.KeyToAppStr  = {} -- [Private Key] = App Name (string)
PrismCore.Kernel.SystemLog = {}
PrismCore.Kernel.SystemMemory = {} -- We are using this table to store data that apps are exchanging with Prism
PrismCore.Kernel.Cache.FullAPIList = {} -- This table contains all gathered API functions from installed apps

local function Write(...)
	PrismCore.Logic.CommonFunctions:Write(PrismCore.Kernel.Security.SelfSign, ...)
end

function PrismCore.Logic.CommonFunctions:Write(Key, ...)
	-- Capture varargs into a table
	local Args = table.pack(...)

	-- Initialize PrismCore and log heartbeat
	PrismCore.Logic:InitiatePrism()
	PrismCore.Logic.Hearbeat("PrismCore.Logic.CommonFunctions:Write()", Args)

	-- Determine the app name based on the key
	local AppName = "Unknown"
	if Key == PrismCore.Kernel.Security.SelfSign then
		AppName = script.Name
	else
		-- Attempt to get the app name from the key
		AppName = PrismCore.Logic.Toolkit.AppFgpt({ Mode = "GNFK", Key = Key }) or "Unknown"
		if AppName == "Unknown" then return end -- Invalid key, exit early
	end

	-- Convert message arguments to strings and concatenate them
	local success, Message = pcall(function()
		for i = 1, Args.n do
			Args[i] = tostring(Args[i])
		end
		return table.concat(Args, " ")
	end)
	if not success then
		Write("Write(): Failed to process message.")
		return
	end

	-- Create the log entry
	local PlatformPrefix = string.sub(PrismCore.Logic.CommonFunctions:GetPlatform(), 1, 1)
	local LogEntry = string.format("🔒 [%s] %s ::: %s", PlatformPrefix, AppName, Message)
	warn(LogEntry)

	-- Prepend the log entry to the terminal log
	table.insert(PrismCore.Kernel.SystemLog, 1, LogEntry)

	-- Return the updated terminal log
	return PrismCore.Kernel.SystemLog
end


PrismCore.Analytics.FirstInitiation = false -- Tracks if the core has already been initiated.

function PrismCore.Logic:InitiatePrism()
	if PrismCore.Analytics.FirstInitiation then
		return -- Early return to avoid unnecessary execution
	end

	PrismCore.Analytics.FirstInitiation = true

	-- Attach Roblox services to PrismCore
	local services = {
		RUN = "RunService",
		DS = "DataStoreService",
		TS = "TeleportService",
		HS = "HttpService",
		UIS = "UserInputService",
		MS = "MarketplaceService",
		BS = "BadgeService",
		CS = "CollectionService",
	}

	for key, serviceName in pairs(services) do
		PrismCore.Services[key] = game:GetService(serviceName)
	end

	-- Log successful installation
	Write("Prism v" .. PrismCore.Kernel.Version .. " has successfully been installed into " .. tostring(script.Parent) .. ".")

	-- Define Toolkit function
	function PrismCore.Logic.Toolkit:VersionIntegrityFix(value)
		PrismCore.Logic.Hearbeat("PrismCore.Logic.Toolkit:VersionIntegrityFix", value)

		-- Validate input
		if not value then return nil end

		-- Condense the string to a maximum of 5 characters
		local condensedStr = string.sub(value, 1, 5)

		-- Validate the condensed string
		local lowerCaseCount = 0
		for char in condensedStr:gmatch(".") do
			if char:match("%l") then
				lowerCaseCount = lowerCaseCount + 1
				if lowerCaseCount > 1 then
					return false
				end
			elseif not char:match("[%d%.]") then
				return false
			end
		end

		return condensedStr
	end
end


-- ////////////////////////////////////////


PrismCore.Flags = {
	AllowInsecureConnections = false; -- By default, only apps inside the Prism security network can utilize each other. Setting this to false will allow app functions to be used from any Script
	CustomHeartBeatThrottle = nil; -- This allows you to set a custom throttle in seconds to the heartbeat function, yielding the entire Prism framework
}

-- Function to verify the app's key before providing access to PrismCore.Logic.CommonFunctions functions
function PrismCore.Logic.Toolkit.AppFgpt(CondensedData)
	-- Validate the input
	if type(CondensedData) ~= "table" or not CondensedData.Mode then
		Write("AppFgpt failed: Invalid input data.")
		return nil
	end

	-- Define mode-specific logic
	local ModeLogic = {
		GNFK = function(Key)
			-- Get Name From Key
			for Name, AppKey in pairs(PrismCore.Kernel.Cache.AppStrToKey) do
				if AppKey == Key then
					return Name
				end
			end
			return nil
		end,

		GKFN = function(Name)
			-- Get Key From Name
			return PrismCore.Kernel.Cache.AppStrToKey[Name]
		end,

		GFDT = function(FunctionString)
			-- Get Function Data from Table
			return PrismCore.Kernel.Cache.FullAPIList[FunctionString]
		end,

		FNFK = function(Key)
			-- Placeholder for future mode logic
			return nil
		end,
	}

	-- Fetch mode and associated logic
	local Mode = CondensedData.Mode
	local ModeFunction = ModeLogic[Mode]

	if not ModeFunction then
		error("Fatal PrismCore.Logic.Toolkit.AppFgpt() failure: Invalid mode - " .. tostring(Mode))
	end

	-- Execute mode logic with relevant parameters
	return ModeFunction(CondensedData.Key or CondensedData.Name or CondensedData.FcnName)
end

function PrismCore.Logic.CommonFunctions:CheckDepends(data, friendlyname, timeout, onDependencyMissing)
	timeout = timeout or 10 -- Default timeout to 10 seconds
	local startTime = os.time()

	-- Precompute a set of app names for quick lookup
	local AppSet = {}
	for _, appName in pairs(PrismCore.Kernel.Cache.KeyToAppStr) do
		AppSet[appName] = true
	end

	-- Store missing dependencies
	local missingDependencies = {}

	-- Check all dependencies
	for _, dependency in ipairs(data) do
		if not AppSet[dependency] then
			local dependencyFound = false
			local deadline = startTime + timeout

			-- Wait until dependency is loaded or timeout expires
			while not dependencyFound and os.time() <= deadline do
				if AppSet[dependency] then
					dependencyFound = true
				else
					task.wait(1) -- Yield for 1 second
				end
			end

			-- If still not found, add to missing dependencies
			if not dependencyFound then
				table.insert(missingDependencies, dependency)
				if onDependencyMissing then
					onDependencyMissing(dependency, friendlyname)
				end
			end
		end
	end

	-- Report missing dependencies
	if #missingDependencies > 0 then
		Write("'" .. friendlyname .. "' cannot be installed due to missing dependencies: " .. table.concat(missingDependencies, ", "))
		return false, missingDependencies
	end

	return true
end

function PrismCore.Logic.Hearbeat(...)
	for _, func in pairs(PrismCore.Logic.FunctionsOnHeartbeat) do
		if PrismCore.Flags.CustomHeartBeatThrottle then
			wait(PrismCore.Flags.CustomHeartBeatThrottle)
		end
		func({...})
	end
end

-- Function to forcibly disconnect an app from the Prism framework
function PrismCore.Logic.Toolkit:BlockApp(AppName)
	-- Validate input
	if not AppName or type(AppName) ~= "string" then
		Write("BlockApp failed: Invalid AppName.")
		return
	end

	PrismCore.Logic.Hearbeat("BlockApp", AppName)

	-- Fetch the app's key
	local key = PrismCore.Kernel.Cache.AppStrToKey[AppName]
	if not key then
		Write("BlockApp failed: App '" .. AppName .. "' is not connected.")
		return
	end

	-- Remove app references from PrismCore tables
	for tableName, tableRef in pairs({ 
		AppStrToKey = PrismCore.Kernel.Cache.AppStrToKey, 
		KeyToAppInst = PrismCore.Kernel.Cache.KeyToAppInst, 
		KeyToAppAPI = PrismCore.Kernel.Cache.KeyToAppAPI, 
		KeyToAppStr = PrismCore.Kernel.Cache.KeyToAppStr 
		}) do
		tableRef[key or AppName] = nil
	end

	-- Log the successful disconnection
	Write("App '" .. AppName .. "' has been blocked from the Prism Security Network.")
end

function PrismCore.Logic.CommonFunctions:Prod(PrivateKey, Properties)
	-- Allow calling with a single table argument
	if type(PrivateKey) == "table" then
		Properties = PrivateKey
	end

	-- Validate input properties
	if not Properties or type(Properties) ~= "table" then
		Write("Prod(): Properties must be a table.")
		return nil
	end

	local ClassName = Properties.ClassName
	if not ClassName or type(ClassName) ~= "string" then
		Write("Prod(): ClassName property must be provided and must be a string.")
		return nil
	end

	-- Attempt to create the instance
	local success, instance = pcall(Instance.new, ClassName)
	if not success then
		Write("Prod(): Failed to create instance of class: " .. tostring(ClassName))
		return nil
	end

	-- Remove ClassName from properties to avoid redundancy
	Properties.ClassName = nil

	-- Attempt to assign properties
	for propertyName, propertyValue in pairs(Properties) do
		if type(propertyName) == "string" then
			local ok, err = pcall(function()
				instance[propertyName] = propertyValue
			end)
			if not ok then
				Write("Prod(): Failed to set property '" .. propertyName .. "' on " .. tostring(instance) .. ". Error: " .. tostring(err))
			end
		else
			Write("Prod(): Invalid property name. Must be a string.")
		end
	end

	-- Track the produced instance
	if instance then
		PrismCore.Analytics.Internal.ProdAllInstances[instance.Name] = instance
	end

	return instance
end



function PrismCore.Logic.CommonFunctions:GenerateKey(ForcedKeyLength, ForcedTimeout)
	PrismCore.Logic.Hearbeat("GenerateKey", ForcedKeyLength, ForcedTimeout)

	-- Ensure CharsTable is initialized
	if not PrismCore.Logic.CharsTable or #PrismCore.Logic.CharsTable == 0 then
		local CharsTable = {}
		for i = 48, 57 do table.insert(CharsTable, string.char(i)) end -- Numbers
		for i = 65, 90 do table.insert(CharsTable, string.char(i)) end -- Uppercase
		for i = 97, 122 do table.insert(CharsTable, string.char(i)) end -- Lowercase
		for i = 32, 47 do table.insert(CharsTable, string.char(i)) end -- Symbols
		for i = 58, 64 do table.insert(CharsTable, string.char(i)) end
		for i = 91, 96 do table.insert(CharsTable, string.char(i)) end
		for i = 123, 126 do table.insert(CharsTable, string.char(i)) end
		PrismCore.Logic.CharsTable = CharsTable
	end

	local CharsTable = PrismCore.Logic.CharsTable

	-- Cache references
	local UsedKeys = PrismCore.Kernel.GeneratedKeys or {}
	local StartTime = os.time()
	local Timeout = ForcedTimeout or 10
	local KeyLength = ForcedKeyLength or 16

	-- Validate key length
	if KeyLength < 16 or KeyLength > 128 then
		KeyLength = 16
		Timeout = 10
		PrismCore.Logic.CommonFunctions:Write(PrismCore.Kernel.Security.SelfSign, "Warning: Invalid key length. Defaulting to 16.")
	end

	local Key = ""
	-- Generate key
	repeat
		Key = "" -- Reset key for each attempt
		for i = 1, KeyLength do
			local RandIndex = math.random(#CharsTable)
			Key = Key .. CharsTable[RandIndex]
		end
		if os.difftime(os.time(), StartTime) > Timeout then
			PrismCore.Logic.CommonFunctions:Write(PrismCore.Kernel.Security.SelfSign, "Fatal Error: Key generation timed out.")
			return nil
		end
	until not UsedKeys[Key]

	-- Save and return the key
	UsedKeys[Key] = true
	PrismCore.Kernel.GeneratedKeys = UsedKeys -- Update the reference
	return Key
end

PrismCore.Kernel.Security.SelfSign = PrismCore.Logic.CommonFunctions:GenerateKey(50)


-- Function to get the current platform/environment
function PrismCore.Logic.CommonFunctions:GetPlatform()
	PrismCore.Logic.Hearbeat("GetPlatform()")
	local RunService = PrismCore.Services.RUN or game:GetService("RunService")
	if RunService:IsStudio() then
		if RunService:IsClient() then
			return "Local"
		elseif RunService:IsServer() then
			return "Server"
		end
	elseif RunService:IsRunMode() then
		return "Plugin"
	else
		-- Default to 'N/A' if none of the conditions match
		-- This is a safeguard and should not typically occur
		return "N/A"
	end
end


function PrismCore.Logic.CommonFunctions:BitSet(PrivateKey, Namespace, ValName, Val, Expiration, Persist, Callback)
	-- Record start time for analytics
	PrismCore.Analytics.Internal.BitSetTotalCalls = 
		(PrismCore.Analytics.Internal.BitSetTotalCalls or 0) + 1

	PrismCore.Logic.Hearbeat("BitSet", PrivateKey, Namespace, ValName, Val, Expiration)

	-- Verify the app's key
	local AppName = PrismCore.Logic.Toolkit.AppFgpt({ Key = PrivateKey, Mode = "GNFK" })
	if not AppName then
		Write("BitSet: Invalid private key.")
		return
	end

	-- Initialize namespace
	PrismCore.Kernel.SystemMemory[AppName] = PrismCore.Kernel.SystemMemory[AppName] or {}
	PrismCore.Kernel.SystemMemory[AppName][Namespace] = PrismCore.Kernel.SystemMemory[AppName][Namespace] or {}
	PrismCore.Kernel.SystemMemory[AppName][Namespace][ValName] = Val

	-- Handle expiration
	if Expiration then
		delay(Expiration, function()
			PrismCore.Kernel.SystemMemory[AppName][Namespace][ValName] = nil
			if Callback then
				Callback(ValName, "Expired")
			end
		end)
	end

	-- Handle persistence
	if Persist then
		local success, err = pcall(function()
			local DS = PrismCore.Services.DS:GetDataStore(AppName .. "_" .. Namespace)
			DS:SetAsync(ValName, Val)
		end)
		if not success then
			Write("BitSet: Failed to persist data. Error: " .. tostring(err))
		end
	end

	return true
end

function PrismCore.Logic.CommonFunctions:BitGet(PrivateKey, Namespace, ValName, Default)
	-- Increment BitGet call count
	PrismCore.Analytics.Internal.BitGetTotalCalls = 
		(PrismCore.Analytics.Internal.BitGetTotalCalls or 0) + 1

	PrismCore.Logic.Hearbeat("BitGet", PrivateKey, Namespace, ValName)

	-- Verify the app's key
	local AppName = PrismCore.Logic.Toolkit.AppFgpt({ Key = PrivateKey, Mode = "GNFK" })
	if not AppName then
		Write("BitGet: Invalid private key.")
		return nil
	end

	-- Retrieve the value or return default
	local value
	if PrismCore.Kernel.SystemMemory[AppName] and PrismCore.Kernel.SystemMemory[AppName][Namespace] and PrismCore.Kernel.SystemMemory[AppName][Namespace][ValName] then
		value = PrismCore.Kernel.SystemMemory[AppName][Namespace][ValName]
	else
		Write("BitGet: Value not found. Returning default.")
		value = Default
	end

	return value
end

-- Whitelist of allowed unique phrases
local AllowedPhrases = {
	"SecureDriverPhrase123",
	"LoggingDriverPhrase456",
	"AnalyticsDriverPhrase789",
}

local function AuthenticateCommon(Entity, EntityData, isDriver)
	PrismCore.Logic:InitiatePrism()

	-- Validate the version string and FriendlyName
	local success, FriendlyName, ValVS = pcall(function()
		return EntityData.FriendlyName or "UNKNOWN APP TYPE",
		PrismCore.Logic.Toolkit:VersionIntegrityFix(EntityData.Version)
	end)

	if not success or not ValVS then
		Write("Install failed for " .. tostring(FriendlyName or Entity.Name) .. ". Compatibility error.")
		return nil
	end

	-- Validate EntityData
	if not (typeof(EntityData) == "table" and EntityData.Version and EntityData.API and Entity) then
		Write("Launch of '" .. Entity.Name .. "' blocked: Invalid EntityData.")
		return nil
	end

	-- Handle unique phrase verification for drivers
	if isDriver then
		local uniquePhrase = EntityData.UniquePhrase
		if not uniquePhrase or type(uniquePhrase) ~= "string" then
			Write("Driver '" .. Entity.Name .. "' must provide a valid unique phrase.")
			return nil
		end

		-- Check if the phrase is in the allowed list
		if not table.find(AllowedPhrases, uniquePhrase) then
			Write("Driver '" .. Entity.Name .. "' provided an unapproved phrase: '" .. uniquePhrase .. "'. Registration denied.")
			return nil
		end

		-- Check if the phrase is already registered
		if PrismCore.Kernel.DriverManagement.Signed[uniquePhrase] then
			Write("Driver '" .. Entity.Name .. "' attempted to register a duplicate phrase: '" .. uniquePhrase .. "'.")
			return nil
		end

		-- Register the driver in the Signed table using its phrase as the key
		PrismCore.Kernel.DriverManagement.Signed[uniquePhrase] = {
			Name = Entity.Name,
			FriendlyName = FriendlyName,
			Version = ValVS,
		}

		Write("Driver '" .. Entity.Name .. "' registered with unique phrase: '" .. uniquePhrase .. "'. Added to Signed table.")
	end

	-- Generate a unique key and store entity details
	local key = PrismCore.Logic.CommonFunctions:GenerateKey()
	PrismCore.Kernel.Cache.AppStrToKey[Entity.Name], PrismCore.Kernel.Cache.KeyToAppInst[key], PrismCore.Kernel.Cache.KeyToAppAPI[key], PrismCore.Kernel.Cache.KeyToAppStr[key] = key, Entity, EntityData.API, Entity.Name

	-- Check dependencies
	if EntityData.Depends then
		local dependenciesSatisfied = PrismCore.Logic.CommonFunctions:CheckDepends(EntityData.Depends, EntityData.FriendlyName)
		if not dependenciesSatisfied then
			Write("Dependencies not satisfied for " .. EntityData.FriendlyName .. ". Aborting.")
			return nil
		end
	end

	-- Process API functions and detect conflicts
	for FcnName, Fcn in pairs(EntityData.API) do
		if PrismCore.Kernel.Cache.FullAPIList[FcnName] then
			Write("Launch of '" .. Entity.Name .. "' failed: Function conflict detected (" .. FcnName .. ").")
			return nil
		end
		PrismCore.Kernel.Cache.FullAPIList[FcnName] = Fcn
	end

	-- Create API package
	local APIPackage = {
		Key = key,
		AppAPI = PrismCore.Logic.CommonFunctions,
		PrismExt = PrismCore.Logic.ExternalFunctions,
	}

	-- Add driver-specific access
	if isDriver then
		APIPackage.PrismCore = PrismCore
		APIPackage.Internal = PrismCore
	end

	Write((isDriver and "Driver" or "App") .. " installation complete: " .. EntityData.FriendlyName .. " (" .. Entity.Name .. ".luau) v" .. tostring(ValVS))
	return APIPackage
end

function PrismCore.Logic.ExternalFunctions:Authenticate(App, AppData)
	return AuthenticateCommon(App, AppData, false)
end

function PrismCore.Logic.ExternalFunctions:AuthenticateDriver(Driver, DriverData)
	return AuthenticateCommon(Driver, DriverData, true)
end

function PrismCore.Logic.ProcessFcn(PrivateKey, ...)
	-- Record start time for response time analytics
	local startTime = os.clock()

	-- Perform a heartbeat for tracking
	PrismCore.Logic.Hearbeat("ProcessFcn", PrivateKey, ...)

	-- Validate inputs early
	if not PrivateKey then
		Write("ProcessFcn failed: Missing PrivateKey.")
		return nil
	end

	local Arguments = table.pack(...)
	local FunctionString = Arguments[1]
	if not FunctionString then
		Write("ProcessFcn failed: Missing FunctionString.")
		return nil
	end

	-- Verify the private key and get the app name
	local AppName = PrismCore.Logic.Toolkit.AppFgpt({ Key = PrivateKey, Mode = "GNFK" })
	if not AppName then
		Write("ProcessFcn failed: Invalid private key, access denied.")
		return nil
	end

	-- Analytics: Increment API call count for this app
	PrismCore.Analytics.Applications.ApiCallCount[AppName] = 
		(PrismCore.Analytics.Applications.ApiCallCount[AppName] or 0) + 1

	-- Retrieve the function from the preprocessed dictionary
	local Fcn = PrismCore.Kernel.Cache.FullAPIList[FunctionString]
	if not Fcn then
		Write("ProcessFcn failed: Function '" .. FunctionString .. "' not found.")
		return nil
	end

	-- Execute the function with the provided arguments
	local success, result = pcall(Fcn, table.unpack(Arguments, 2, Arguments.n))
	if not success then
		Write("ProcessFcn execution failed: " .. tostring(result))
		return nil
	end

	-- Record execution time
	local executionTime = os.clock() - startTime

	-- Analytics: Log response time and calculate average response time
	local ResponseTimes = PrismCore.Analytics.Applications.ResponseTimes[AppName] or {}
	table.insert(ResponseTimes, executionTime)
	PrismCore.Analytics.Applications.ResponseTimes[AppName] = ResponseTimes

	local total = 0
	for _, time in ipairs(ResponseTimes) do
		total = total + time
	end
	PrismCore.Analytics.Applications.AvgResponseTime[AppName] = total / #ResponseTimes

	return result
end

-- All of Prism's API functions are now available directly in the PrismCore.Logic.CommonFunctions table. This prevents the need of apps and drivers to 

-- Function to call ProcessFcn() with the provided private key and arguments
function PrismCore.Logic.CommonFunctions:Fcn(PrivateKey,...)
	return PrismCore.Logic.ProcessFcn(PrivateKey, ...)
end

-- Function to call ProcessFcn() asynchronously with the provided private key and arguments
function PrismCore.Logic.CommonFunctions:FcnAsync(PrivateKey, ...)
	local Attachments = {...}
	spawn(function()
		PrismCore.Logic.ProcessFcn(PrivateKey, unpack(Attachments))
	end)
end

-- Short form function names for ease of scripting
function PrismCore.Logic.CommonFunctions:f(PrivateKey,...)
	return PrismCore.Logic.ProcessFcn(PrivateKey, ...)
end

function PrismCore.Logic.CommonFunctions:fa(PrivateKey, ...)
	local Attachments = {...}
	spawn(function()
		PrismCore.Logic.ProcessFcn(PrivateKey, unpack(Attachments))
	end)
end

return PrismCore.Logic.ExternalFunctions
