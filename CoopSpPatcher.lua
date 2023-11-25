--[[
Copyright (c) [2023] [Flash_Hit a/k/a Bree_Arnold]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

---@param p_Instance DataContainer
local function _PatchLevelDescriptionAsset(p_Instance)
	p_Instance = LevelDescriptionAsset(p_Instance)
	p_Instance:MakeWritable()
	---@cast p_Instance LevelDescriptionAsset

	if p_Instance.description.isMenu then return end

	p_Instance.description.isCoop = false
	p_Instance.description.isMultiplayer = true

	local s_Category = p_Instance.categories[1]
	if not s_Category then
		p_Instance.categories:add(LevelDescriptionInclusionCategory())
		s_Category = p_Instance.categories[1]
		s_Category.category = "GameMode"
	end

	p_Instance.startPoints:clear()
end

---@param p_LevelReportingAsset DataContainer
local function _OnLevelReportingAsset(p_LevelReportingAsset)
	p_LevelReportingAsset = LevelReportingAsset(p_LevelReportingAsset)
	---@cast p_LevelReportingAsset LevelReportingAsset

	for _, l_LevelDescriptionAsset in ipairs(p_LevelReportingAsset.builtLevels) do
		if l_LevelDescriptionAsset.isLazyLoaded then
			l_LevelDescriptionAsset:RegisterLoadHandlerOnce(_PatchLevelDescriptionAsset)
		else
			_PatchLevelDescriptionAsset(l_LevelDescriptionAsset)
		end
	end
end

ResourceManager:RegisterInstanceLoadHandlerOnce(Guid("4B6D07D6-F84D-11DD-BE32-C64EACA26B06"), Guid("4B6D07D7-FE4D-11DD-A232-C64E4C926B06"), _OnLevelReportingAsset)

if SharedUtils:IsClientModule() then
	local s_LevelReportingAsset = ResourceManager:FindInstanceByGuid(Guid("4B6D07D6-F84D-11DD-BE32-C64EACA26B06"), Guid("4B6D07D7-FE4D-11DD-A232-C64E4C926B06"))

	if s_LevelReportingAsset then
		_OnLevelReportingAsset(s_LevelReportingAsset)
	end
end

local m_LevelPartitionList = {
	COOP_002 = Guid("B1BA4ED2-E692-11DF-8AB9-825AA2E1EF0A"),
	COOP_003 = Guid("3D86F044-C978-48CC-8BBB-97474DE4572D"),
	COOP_006 = Guid("23535E3D-E72F-11DF-99CA-879440EEBD7A"),
	COOP_007 = Guid("66606821-E69C-11DF-9B0E-AF9CA6E0236B"),
	COOP_009 = Guid("F94C5091-E69C-11DF-9B0E-AF9CA6E0236B"),
	COOP_010 = Guid("333BDB92-E69D-11DF-9B0E-AF9CA6E0236B"),
	SP_Bank = Guid("5119BCE8-E277-11DF-AC57-D4F216B966DB"),
	SP_Earthquake = Guid("C8D40579-CA37-11DF-B1FE-C90CED16BE7F"),
	SP_Earthquake2 = Guid("6FD69AE4-5B8A-11E0-BC14-D5B461CF665B"),
	SP_Finale = Guid("8DA3322E-3E60-11E0-BFEE-95DA3EB52033"),
	SP_Jet = Guid("3C0DE194-B689-11DF-B8D0-D42ED28AF832"),
	SP_New_York = Guid("936D5695-A989-4F39-B8C7-6404B0F55C5D"),
	SP_Paris = Guid("61417F2E-BCD9-11DF-A157-A17CBD8140DE"),
	SP_Sniper = Guid("DBCE4061-E2A4-11DF-A647-FE6A1B285059"),
	SP_Tank = Guid("A263A077-CA17-11DF-830F-E4337AA80D37"),
	SP_Tank_b = Guid("7662E9AF-091E-4A19-B7ED-751D083E7693"),
	SP_Valley = Guid("9B6EE657-5639-4A04-AA88-16E9E201806E"),
	SP_Villa = Guid("6B420080-18CB-11E0-B456-BF5782883243")
}

SubWorldBundleLoadingList = {
	COOP_002 = {},
	COOP_003 = {},
	COOP_006 = {},
	COOP_007 = {},
	COOP_009 = {},
	COOP_010 = {},
	SP_Bank = {},
	SP_Earthquake = {},
	SP_Earthquake2 = {},
	SP_Finale = {},
	SP_Jet = {},
	SP_New_York = {},
	SP_Paris = {},
	SP_Sniper = {},
	SP_Tank = {},
	SP_Tank_b = {},
	SP_Valley = {},
	SP_Villa = {}
}

---@param p_Partition DatabasePartition
local function _TweakLevel(p_Partition)
	local s_LevelData = LevelData(p_Partition.primaryInstance)
	s_LevelData:MakeWritable()

	s_LevelData.levelDescription.isCoop = false
	s_LevelData.levelDescription.isMultiplayer = true

	local s_Name = s_LevelData.name:gsub(".*/", "")

	for _, l_Instance in ipairs(p_Partition.instances) do
		if l_Instance.typeInfo.name == "SubWorldReferenceObjectData" then
			l_Instance = SubWorldReferenceObjectData(l_Instance)
			l_Instance:MakeWritable()

			local s_AutoLoad = SubWorldBundleLoadingList[s_Name][l_Instance.bundleName:gsub(".*/", "")]
			if s_AutoLoad ~= nil then
				l_Instance.autoLoad = s_AutoLoad
			end
		end
	end
end

---@param p_HookCtx HookContext
---@param p_Bundles string[]
---@param p_Compartment ResourceCompartment|integer
local function OnLoadBundles(p_HookCtx, p_Bundles, p_Compartment)
	if p_Compartment == ResourceCompartment.ResourceCompartment_Game then
		local s_LevelName = SharedUtils:GetLevelName():gsub(".*/", "")
		---@cast s_LevelName -nil

		if not s_LevelName:match("COOP_") and not s_LevelName:match("SP_") then
			return
		end

		local s_LevelPartitionGuid = m_LevelPartitionList[s_LevelName]

		if not s_LevelPartitionGuid then
			error(string.format("PartitionGuid not found for %s", s_LevelName))
		end

		ResourceManager:RegisterPartitionLoadHandlerOnce(s_LevelPartitionGuid, _TweakLevel)
	end
end

Hooks:Install("ResourceManager:LoadBundles", 1, OnLoadBundles)
