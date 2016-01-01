--[[
    Author: Ramnishath Anaswara
    Plugin for Adobe LightRoom. 
    
    Once installed,this plugin can be invoked to create image collections 
    organised by the year and month of the date of capture of the image.
--]]

-- **
-- In case you are interested in the logic, read this file from the bottom - up direction. 
-- Good luck!
-- **

-- Access the Lightroom SDK namespaces.
local LrLogger = import 'LrLogger'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'

-- Create the logger and enable the print function.
local myLogger = LrLogger( 'smartCollections' )  -- File is written into the Documents folder.
myLogger:enable( "logfile" )

local function outputToLog( message )
	myLogger:trace( message )
end

local catalog = LrApplication.activeCatalog()

-- Name of the master collection
local masterCollectionName = "All Files1"

-- Time period for which the files are organised as collections.
local yearStart = 2000
local yearEnd = 2016

local monthStart = 1
local monthEnd = 12

local function getMonth(month)
	local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
	return months[tonumber(month)]
end

local function createSmartCollectionToDb(collectionName, searchCriteria, parent)
	local sc = catalog:createSmartCollection(collectionName, searchCriteria, parent, false)
	if sc then
		outputToLog("Created sub 'smart' collection '" .. collectionName .. "' for the parent '" .. parent:getName() .. "'")
	end
end

local function createSmartSearchCriteria(year, month, fileType)
	if fileType then
		return {
			{
				criteria = "captureTime",
				operation = "in",
				value = year .. "-" .. month .. "-01",
				value2 = year .. "-" .. month .. "-31",
				value_units = "days",
			},
			{
				criteria = "fileFormat",
				operation = "==",
				value = string.upper(fileType),
			},
			combine = "intersect",
		}
	else
		return {
			criteria = "captureTime",
			operation = "in",
			value = year .. "-" .. month .. "-01",
			value2 = year .. "-" .. month .. "-31",
			value_units = "days",
		}
	end
end

local function createSmartSearchCriteriaYear(year)
	return {
			criteria = "captureTime",
			operation = "in",
			value = year .. "-01-01",
			value2 = year .. "-12-31",
			value_units = "days",
	}
end

local function createSmartCollectionName(year, month, fileType)
	if fileType then
		return year .. "-" .. getMonth(month) .. " " .. fileType
	else
		return year .. "-" .. getMonth(month)
	end 
end

local function createSmartCollectionNameYear(year)
	return "All Files"
end

local function createSmartCollection(parent, year, month, fileType)
    local collectionName = createSmartCollectionName(year, month, fileType)
	local searchCriteria = createSmartSearchCriteria(year, month, fileType)
	createSmartCollectionToDb(collectionName, searchCriteria, parent)
end

local function createSmartCollectionYear(parent, year)
    local collectionName = createSmartCollectionNameYear(year)
	local searchCriteria = createSmartSearchCriteriaYear(year)
	createSmartCollectionToDb(collectionName, searchCriteria, parent)
end

local function createSmartCollectionSets()
	for i,v in ipairs(catalog:getChildCollectionSets()) do
		if (masterCollectionName == v:getName()) then 
			for i,yearSet in ipairs(v:getChildCollectionSets()) do
				createSmartCollectionYear(yearSet, yearSet:getName())
				for i,monthSet in ipairs(yearSet:getChildCollectionSets()) do
					createSmartCollection(monthSet, yearSet:getName(), string.sub(monthSet:getName(), 0, 2), null)
					createSmartCollection(monthSet, yearSet:getName(), string.sub(monthSet:getName(), 0, 2), "JPG")
					createSmartCollection(monthSet, yearSet:getName(), string.sub(monthSet:getName(), 0, 2), "Raw")
					createSmartCollection(monthSet, yearSet:getName(), string.sub(monthSet:getName(), 0, 2), "Video")
					-- add one more line if you need another smart collection
				end
			end
		end
    end	
end

local function createSubCollectionSet(parentCollectionSet, subCollectionSetName)
	local subCollectionSet = catalog:createCollectionSet(subCollectionSetName, parentCollectionSet, false)
		if subCollectionSet then
			outputToLog("Created sub collection set '" .. subCollectionSetName .. "' for the parent '" .. parentCollectionSet:getName() .. "'")
	end
end

local function createMonthCollectionSets()
	for i,v in ipairs(catalog:getChildCollectionSets()) do
		if (masterCollectionName == v:getName()) then 
			for i,yearSet in ipairs(v:getChildCollectionSets()) do
				for month = monthStart, monthEnd
				do 
					createSubCollectionSet(yearSet, string.format("%02d", month) .. " " .. getMonth(month))
				end
			end
		end
    end	
end

local function createYearCollectionSets()
	for i,v in ipairs(catalog:getChildCollectionSets()) do
		if (masterCollectionName == v:getName()) then 
			for year = yearStart, yearEnd
			do 
				createSubCollectionSet(v, year .. "")
			end
		end
    end	
end

local function createMaster()
    local masterSet = catalog:createCollectionSet(masterCollectionName, null, false)
    if masterSet then
    	outputToLog("Created master collection set '" .. masterCollectionName .. "'")
    end
end

local function runCommand ()
 	LrTasks.startAsyncTask(function()
 		catalog:withWriteAccessDo("Create master collection set", createMaster)
	   	catalog:withWriteAccessDo("Create sub collection set by year", createYearCollectionSets)
	   	catalog:withWriteAccessDo("Create sub collection set by month", createMonthCollectionSets)
	   	catalog:withWriteAccessDo("Create smart collections", createSmartCollectionSets)
 		end 
 	)
end

runCommand()

