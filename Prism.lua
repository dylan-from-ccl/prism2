
	--[[

	  ____       _                 ____  
	 |  _ \ _ __(_)___ _ __ ___   |___ \ 
	 | |_) | '__| / __| '_ ` _ \    __) |
	 |  __/| |  | \__ \ | | | | |  / __/ 
	 |_|   |_|  |_|___/_| |_| |_| |_____|
	 	
	 	
	      B R O U G H T   T O   Y O U   B Y  :                                                                                                                               
	  	  _              _                                      
		 / )  _  _  _   / )  _  _  _ _/  '     _   /   _  /   _ 
		(__  (/ /  /   (__  /  (- (/ /  /  \/ (-  (__ (/ () _)  
		                                                        
		Prism is an open-source framework designed to empower developers on Roblox by 
		streamlining the way applications and drivers interact and operate. 
		As the successor to Prism 1, it provides a structured, secure foundation that 
		simplifies managing interconnected systems, enabling you to focus on innovation and creativity. 

		With Prism, you can build scalable, organized, and collaborative projects, unlocking new possibilities for seamless integration and efficient development.
	      
	                                        
	]]


	-- These are three security clearance levels we want to create
	local PrismCore = {
		Services = {}, -- Services table

		Logic = { -- General functionality operations
			Toolkit = {},
			CommonFunctions = {},
			ExternalFunctions = {},
			CharsTable = {},
			FunctionsOnHeartbeat = {}, -- Functions executed on each heartbeat, accessible internally by drivers.
		},

		Analytics = { -- Tracking application and driver usage for monitoring and security
			Applications = {
				ApiCallCount = {}, -- API call counts per application
				ResponseTimes = {}, -- Response times for each API call per application
				AvgResponseTime = {}, -- Average response times calculated from ResponseTimes
			},
			Internal = {
				BitGetTotalCalls = 0, -- Total BitGet calls
				BitSetTotalCalls = 0, -- Total BitSet calls
				ProdAllInstances = {}, -- Instances created by the Prod() function, accessible internally.
			},
		},

		Kernel = { -- Core functionality and critical operations
			Version = "2.00007b",
			DriverManagement = {
--[[/!@@]]		AllowedFingerprints = {"SecureDriverPhrase123"},
				Signed = {}, -- Tracks registered drivers
			},
			Security = {}, -- Security-related configurations
			Cache = { -- Cached data for efficient lookups
				AppStrToKey = {}, -- [App Name] = Private Key (string)
				KeyToAppInst = {}, -- [Private Key] = App Instance (script)
				KeyToAppAPI = {}, -- [Private Key] = App's shared API (table)
				KeyToAppStr = {}, -- [Private Key] = App Name (string)
				FullAPIList = {}, -- All gathered API functions from installed apps
				DriverNames = {}, -- All driver names in PRism 
			
			},
			SystemLog = {}, -- Logs system events
			SystemMemory = {}, -- Memory storage for data exchanged with Prism
			Config = { -- Configuration flags
				Flags = {
					CustomHeartBeatThrottle = nil, -- Custom throttle (in seconds) for the heartbeat function
				},
			},
		},
	}

	local function Write(...)
		PrismCore.Logic.CommonFunctions:Write(PrismCore.Kernel.Security.SelfSign, ...)
	end

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

function PrismCore.Logic.CommonFunctions:Write(Key, ...)
	-- Capture varargs into a table
	local Args = table.pack(...)

	-- Initialize PrismCore and log heartbeat
	PrismCore.Logic:InitiatePrism()
	PrismCore.Logic.Hearbeat("PrismCore.Logic.CommonFunctions:Write()", Args)

	-- Determine the app name based on the key
	local AppName = "Unknown"
	local isDriver = false -- Default to app
	if Key == PrismCore.Kernel.Security.SelfSign then
		AppName = script.Name
	else
		-- Attempt to get the app name from the key
		AppName = PrismCore.Logic.Toolkit.AppFgpt({ Mode = "GNFK", Key = Key }) or "Unknown"
		if AppName == "Unknown" then return end -- Invalid key, exit early

		-- Check if the key belongs to a driver
		if PrismCore.Kernel.Cache.DriverNames[AppName] then
			isDriver = true
		end
	end

	-- Convert message arguments to strings and concatenate them
	local success, Message = pcall(function()
		for i = 1, Args.n do
			Args[i] = tostring(Args[i])
		end
		return table.concat(Args, " ")
	end)
	if not success then
		-- Avoid recursive calls; use warn directly
		warn("Write(): Failed to process message.")
		return
	end

	-- Split the message into lines if it contains \n
	local Lines = {}
	for line in Message:gmatch("([^\n]*)\n?") do
		if line and line ~= "" then
			table.insert(Lines, line)
		end
	end

	-- Determine the maximum lines based on app/driver status
	local MaxLines = isDriver and 10 or 4
	if #Lines > MaxLines then
		-- Truncate to maximum allowed lines
		Lines = { unpack(Lines, 1, MaxLines) }
		table.insert(Lines, "... (max. lines reached)")
	end

	-- Combine the header and message lines
	local PlatformPrefix = string.sub(PrismCore.Logic.CommonFunctions:GetPlatform(), 1, 1)
	local LogHeader = string.format("🔒 [%s] %s :::", PlatformPrefix, AppName)
	local FormattedMessage = table.concat(Lines, "\n")
	local FullLogEntry = LogHeader .. "\n" .. FormattedMessage

	-- Log the combined entry only once
	warn(FullLogEntry)

	-- Prepend the log entry to the terminal log
	table.insert(PrismCore.Kernel.SystemLog, 1, FullLogEntry)

	-- Return the updated terminal log
	return PrismCore.Kernel.SystemLog
end

	-- ////////////////////////////////////////




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
			if PrismCore.Kernel.Config.Flags.CustomHeartBeatThrottle then
				wait(PrismCore.Kernel.Config.Flags.CustomHeartBeatThrottle)
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
	-- Creates a new Roblox instance and applies properties.
	-- PrivateKey: The app's private key (not used here but can be extended for future validation).
	-- Properties: Table containing the ClassName and other properties to set on the instance.

	-- Allow shorthand call with only the Properties table
	if type(PrivateKey) == "table" then
		Properties = PrivateKey
	end

	-- Ensure Properties is valid
	if not Properties or type(Properties) ~= "table" then
		Write("Prod(): Properties must be a table.")
		return nil
	end

	-- Validate ClassName in Properties
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

	-- Avoid redundant property by removing ClassName from Properties
	Properties.ClassName = nil

	-- Apply each property in the Properties table to the instance
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

	-- Track the instance in analytics for debugging and monitoring
	if instance then
		PrismCore.Analytics.Internal.ProdAllInstances[instance.Name] = instance
	end

	return instance -- Return the created instance
end

function PrismCore.Logic.CommonFunctions:GenerateKey(ForcedKeyLength, ForcedTimeout)
	-- Generates a secure, unique key for use in the framework.
	-- ForcedKeyLength: Optional parameter to specify the key length (default: 16).
	-- ForcedTimeout: Optional parameter to specify the timeout for generation (default: 10 seconds).

	PrismCore.Logic.Hearbeat("GenerateKey", ForcedKeyLength, ForcedTimeout)

	-- Ensure the CharsTable (used for key generation) is initialized
	if not PrismCore.Logic.CharsTable or #PrismCore.Logic.CharsTable == 0 then
		local CharsTable = {}
		for i = 48, 57 do table.insert(CharsTable, string.char(i)) end -- Numbers
		for i = 65, 90 do table.insert(CharsTable, string.char(i)) end -- Uppercase letters
		for i = 97, 122 do table.insert(CharsTable, string.char(i)) end -- Lowercase letters
		for i = 32, 47 do table.insert(CharsTable, string.char(i)) end -- Symbols
		for i = 58, 64 do table.insert(CharsTable, string.char(i)) end
		for i = 91, 96 do table.insert(CharsTable, string.char(i)) end
		for i = 123, 126 do table.insert(CharsTable, string.char(i)) end
		PrismCore.Logic.CharsTable = CharsTable
	end

	local CharsTable = PrismCore.Logic.CharsTable

	-- References for used keys and initialization time
	local UsedKeys = PrismCore.Kernel.GeneratedKeys or {}
	local StartTime = os.time()
	local Timeout = ForcedTimeout or 10
	local KeyLength = ForcedKeyLength or 16

	-- Ensure key length is within bounds
	if KeyLength < 16 or KeyLength > 128 then
		KeyLength = 16
		Timeout = 10
		PrismCore.Logic.CommonFunctions:Write(PrismCore.Kernel.Security.SelfSign, "Warning: Invalid key length. Defaulting to 16.")
	end

	local Key = ""
	-- Generate a unique key
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
	until not UsedKeys[Key] -- Ensure the key is unique

	-- Mark the key as used
	UsedKeys[Key] = true
	PrismCore.Kernel.GeneratedKeys = UsedKeys -- Update the generated keys cache
	return Key -- Return the generated key
end

PrismCore.Kernel.Security.SelfSign = PrismCore.Logic.CommonFunctions:GenerateKey(50)

function PrismCore.Logic.CommonFunctions:GetPlatform()
	-- Determines the current platform/environment where the script is running.
	-- Possible return values:
	-- "Local": Running in Studio as a local script.
	-- "Server": Running in Studio as a server script.
	-- "Plugin": Running as a plugin.
	-- "N/A": Default fallback if no condition matches.

	PrismCore.Logic.Hearbeat("GetPlatform()")

	local RunService = PrismCore.Services.RUN or game:GetService("RunService")
	if RunService:IsStudio() then
		if RunService:IsClient() then
			return "Local" -- Running as a client in Studio
		elseif RunService:IsServer() then
			return "Server" -- Running as a server in Studio
		end
	elseif RunService:IsRunMode() then
		return "Plugin" -- Running as a plugin
	else
		return "N/A" -- Unknown or unhandled environment
	end
end


function PrismCore.Logic.CommonFunctions:BitSet(PrivateKey, Namespace, ValName, Val, Expiration, Persist, Callback)
	-- Securely sets a value in the system memory namespace for an application.
	-- PrivateKey: The app's private key for authentication.
	-- Namespace: A logical grouping to organize stored values.
	-- ValName: The name of the value to set.
	-- Val: The value to store.
	-- Expiration: Optional expiration time in seconds.
	-- Persist: Reserved for future use to support persistence.
	-- Callback: Function to execute upon expiration of the value.

	-- Record start time for analytics
	PrismCore.Analytics.Internal.BitSetTotalCalls = 
		(PrismCore.Analytics.Internal.BitSetTotalCalls or 0) + 1

	-- Signal activity through a heartbeat
	PrismCore.Logic.Hearbeat("BitSet", PrivateKey, Namespace, ValName, Val, Expiration)

	-- Validate the app's private key
	local AppName = PrismCore.Logic.Toolkit.AppFgpt({ Key = PrivateKey, Mode = "GNFK" })
	if not AppName then
		Write("BitSet: Invalid private key.")
		return
	end

	-- Initialize or retrieve the namespace for the app
	PrismCore.Kernel.SystemMemory[AppName] = PrismCore.Kernel.SystemMemory[AppName] or {}
	PrismCore.Kernel.SystemMemory[AppName][Namespace] = PrismCore.Kernel.SystemMemory[AppName][Namespace] or {}
	PrismCore.Kernel.SystemMemory[AppName][Namespace][ValName] = Val -- Store the value

	-- Handle expiration, if provided
	if Expiration then
		delay(Expiration, function()
			-- Remove the value upon expiration
			PrismCore.Kernel.SystemMemory[AppName][Namespace][ValName] = nil
			if Callback then
				Callback(ValName, "Expired") -- Notify via callback
			end
		end)
	end

	return true -- Indicate successful operation
end

function PrismCore.Logic.CommonFunctions:BitGet(PrivateKey, Namespace, ValName, Default)
	-- Securely retrieves a value from the system memory namespace for an application.
	-- PrivateKey: The app's private key for authentication.
	-- Namespace: A logical grouping to organize stored values.
	-- ValName: The name of the value to retrieve.
	-- Default: The default value to return if the requested value is not found.

	-- Increment analytics counter for BitGet operations
	PrismCore.Analytics.Internal.BitGetTotalCalls = 
		(PrismCore.Analytics.Internal.BitGetTotalCalls or 0) + 1

	-- Signal activity through a heartbeat
	PrismCore.Logic.Hearbeat("BitGet", PrivateKey, Namespace, ValName)

	-- Validate the app's private key
	local AppName = PrismCore.Logic.Toolkit.AppFgpt({ Key = PrivateKey, Mode = "GNFK" })
	if not AppName then
		Write("BitGet: Invalid private key.")
		return nil
	end

	-- Attempt to retrieve the value
	local value
	if PrismCore.Kernel.SystemMemory[AppName] and 
		PrismCore.Kernel.SystemMemory[AppName][Namespace] and 
		PrismCore.Kernel.SystemMemory[AppName][Namespace][ValName] then
		value = PrismCore.Kernel.SystemMemory[AppName][Namespace][ValName]
	else
		Write("BitGet: Value not found. Returning default.")
		value = Default -- Return the default value if not found
	end

	return value
end

local function AuthenticateCommon(Entity, EntityData, isDriver)
	-- Common function to authenticate apps and drivers.
	-- Entity: The script or object representing the app/driver.
	-- EntityData: Metadata including version, API, and dependencies.
	-- isDriver: Boolean indicating whether the entity is a driver.

	-- Ensure Prism is initialized
	PrismCore.Logic:InitiatePrism()

	-- Validate the version string and friendly name
	local success, FriendlyName, ValVS = pcall(function()
		return EntityData.FriendlyName or "UNKNOWN APP TYPE", PrismCore.Logic.Toolkit:VersionIntegrityFix(EntityData.Version)
	end)

	if not success or not ValVS then
		Write("Install failed for " .. tostring(FriendlyName or Entity.Name) .. ". Compatibility error.")
		return nil
	end

	-- Reject direct ModuleScript connections for security reasons
	if Entity:IsA("ModuleScript") then 
		Write("Due to security concerns, ModuleScripts ("..Entity.Name..") are forbidden from connecting directly to Prism.\nThey can still be used by connecting to your apps, but the actual app needs to be a (local)script.")
		return nil
	end

	-- Validate the structure of EntityData
	if not (typeof(EntityData) == "table" and EntityData.Version and EntityData.API and Entity) then
		Write("Driver installation security Errno0")
		return nil
	end

	-- Handle driver-specific unique phrase verification
	if isDriver then
		local uniquePhrase = EntityData.UniquePhrase
		if not uniquePhrase or type(uniquePhrase) ~= "string" then
			Write("Driver installation security Errno1")
			return nil
		end

		-- Ensure the unique phrase is authorized
		if not table.find(PrismCore.Kernel.DriverManagement.AllowedFingerprints, uniquePhrase) then
			Write("Driver installation security Errno2")
			return nil
		end

		-- Check for duplicate registration of the unique phrase
		if PrismCore.Kernel.DriverManagement.Signed[uniquePhrase] then
			Write("Driver installation security Errno3")
			return nil
		end

		-- Register the driver
		PrismCore.Kernel.DriverManagement.Signed[uniquePhrase] = {
			Name = Entity.Name,
			FriendlyName = FriendlyName,
			Version = ValVS,
		}

		Write("Driver '" .. Entity.Name .. "' has been successfully installed into Prism.")
	end

	-- Generate a unique key for the entity
	local key = PrismCore.Logic.CommonFunctions:GenerateKey()
	PrismCore.Kernel.Cache.AppStrToKey[Entity.Name] = key
	PrismCore.Kernel.Cache.KeyToAppInst[key] = Entity
	PrismCore.Kernel.Cache.KeyToAppAPI[key] = EntityData.API
	PrismCore.Kernel.Cache.KeyToAppStr[key] = Entity.Name

	if isDriver then
		PrismCore.Kernel.Cache.DriverNames[Entity.Name] = Entity 
	end

	-- Validate and resolve dependencies
	if EntityData.Depends then
		local dependenciesSatisfied = PrismCore.Logic.CommonFunctions:CheckDepends(EntityData.Depends, EntityData.FriendlyName)
		if not dependenciesSatisfied then
			Write("Dependencies not satisfied for " .. EntityData.FriendlyName .. ". Aborting.")
			return nil
		end
	end

	-- Register API functions and check for conflicts
	for FcnName, Fcn in pairs(EntityData.API) do
		if PrismCore.Kernel.Cache.FullAPIList[FcnName] then
			Write("Launch of '" .. Entity.Name .. "' failed: Function conflict detected (" .. FcnName .. ").")
			return nil
		end
		PrismCore.Kernel.Cache.FullAPIList[FcnName] = Fcn
	end

	-- Create and return the API package for the app/driver
	local APIPackage = {
		Key = key,
		AppAPI = PrismCore.Logic.CommonFunctions,
		PrismExt = PrismCore.Logic.ExternalFunctions,
	}

	-- Add driver-specific access if applicable
	if isDriver then
		APIPackage.PrismCore = PrismCore
		APIPackage.Internal = PrismCore
	end

	Write((isDriver and "Driver" or "App") .. " installation complete: " .. EntityData.FriendlyName .. " (" .. Entity.Name .. ".luau) v" .. tostring(ValVS))
	return APIPackage
end

function PrismCore.Logic.ExternalFunctions:Authenticate(App, AppData)
	-- Authenticate an application with Prism.
	-- This function validates and registers the application using shared logic.
	-- App: The application instance to authenticate.
	-- AppData: Metadata about the application, including API and dependencies.
	return AuthenticateCommon(App, AppData, false) -- Use common logic for authentication.
end

function PrismCore.Logic.ExternalFunctions:AuthenticateDriver(Driver, DriverData)
	-- Authenticate a driver with Prism.
	-- This function validates and registers the driver using shared logic.
	-- Driver: The driver instance to authenticate.
	-- DriverData: Metadata about the driver, including API and unique fingerprint.
	return AuthenticateCommon(Driver, DriverData, true) -- Use common logic for driver authentication.
end

function PrismCore.Logic.ProcessFcn(PrivateKey, ...)
	-- Process a function call securely through Prism.
	-- Validates the caller's private key and executes the requested function.

	-- Record start time for analytics
	local startTime = os.clock()

	-- Perform a heartbeat to signal activity
	PrismCore.Logic.Hearbeat("ProcessFcn", PrivateKey, ...)

	-- Validate that a private key is provided
	if not PrivateKey then
		Write("ProcessFcn failed: Missing PrivateKey.")
		return nil
	end

	-- Collect arguments and extract the function string
	local Arguments = table.pack(...)
	local FunctionString = Arguments[1] -- The function to be executed
	if not FunctionString then
		Write("ProcessFcn failed: Missing FunctionString.")
		return nil
	end

	-- Verify the private key and resolve the associated application name
	local AppName = PrismCore.Logic.Toolkit.AppFgpt({ Key = PrivateKey, Mode = "GNFK" })
	if not AppName then
		Write("ProcessFcn failed: Invalid private key, access denied.")
		return nil
	end

	-- Increment API call count for analytics
	PrismCore.Analytics.Applications.ApiCallCount[AppName] = 
		(PrismCore.Analytics.Applications.ApiCallCount[AppName] or 0) + 1

	-- Retrieve the requested function from the cache
	local Fcn = PrismCore.Kernel.Cache.FullAPIList[FunctionString]
	if not Fcn then
		Write("ProcessFcn failed: Function '" .. FunctionString .. "' not found.")
		return nil
	end

	-- Execute the function securely and capture the result
	local success, result = pcall(Fcn, table.unpack(Arguments, 2, Arguments.n))
	if not success then
		Write("ProcessFcn execution failed: " .. tostring(result))
		return nil
	end

	-- Calculate execution time for analytics
	local executionTime = os.clock() - startTime

	-- Record response time and update average response time for analytics
	local ResponseTimes = PrismCore.Analytics.Applications.ResponseTimes[AppName] or {}
	table.insert(ResponseTimes, executionTime)
	PrismCore.Analytics.Applications.ResponseTimes[AppName] = ResponseTimes

	local total = 0
	for _, time in ipairs(ResponseTimes) do
		total = total + time
	end
	PrismCore.Analytics.Applications.AvgResponseTime[AppName] = total / #ResponseTimes

	-- Return the result of the function execution
	return result
end

-- Simplified wrappers for ProcessFcn to streamline usage

function PrismCore.Logic.CommonFunctions:Fcn(PrivateKey, ...)
	-- Wrapper for ProcessFcn to directly call a function with arguments.
	return PrismCore.Logic.ProcessFcn(PrivateKey, ...)
end

function PrismCore.Logic.CommonFunctions:FcnAsync(PrivateKey, ...)
	-- Wrapper for ProcessFcn to call a function asynchronously.
	local Attachments = {...}
	spawn(function()
		PrismCore.Logic.ProcessFcn(PrivateKey, unpack(Attachments))
	end)
end

-- Shorter aliases for streamlined scripting

function PrismCore.Logic.CommonFunctions:f(PrivateKey, ...)
	-- Alias for Fcn (short form)
	return PrismCore.Logic.ProcessFcn(PrivateKey, ...)
end

function PrismCore.Logic.CommonFunctions:fa(PrivateKey, ...)
	-- Alias for FcnAsync (short form)
	local Attachments = {...}
	spawn(function()
		PrismCore.Logic.ProcessFcn(PrivateKey, unpack(Attachments))
	end)
end

return PrismCore.Logic.ExternalFunctions
