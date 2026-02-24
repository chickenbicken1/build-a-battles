-- TestRunner.server.lua
-- Autonomous script to run all test suites and report results to Output

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Testing = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Testing")
local TestSuites = require(Testing:WaitForChild("TestSuites"))

print("\n🧪 [TEST RUNNER] Starting tests...")
local passed = 0
local failed = 0
local total = 0

local function RunTest(name, suite)
    print("▶ Running: " .. name)
    for testName, testFunc in pairs(suite) do
        total = total + 1
        local success, err = pcall(testFunc)
        if success then
            passed = passed + 1
        else
            failed = failed + 1
            warn("❌ FAILED [" .. name .. "]: " .. testName .. " - " .. tostring(err))
        end
    end
end

-- Wait a moment for server to initialize
task.wait(2)

RunTest("Utils", TestSuites.Utils)
RunTest("RollService", TestSuites.RollService)
RunTest("EggShop", TestSuites.EggShop)

print("\n" .. string.rep("═", 30))
if failed == 0 then
    print("✅ ALL TESTS PASSED! (" .. passed .. "/" .. total .. ")")
else
    warn("🚨 TESTS COMPLETED WITH ERRORS: " .. failed .. " FAILED, " .. passed .. " PASSED")
end
print(string.rep("═", 30) .. "\n")
