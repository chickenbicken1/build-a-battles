-- DEBUG TEST - Is Wine crashing on our UI?
task.wait(3) -- Wait for everything to load
print("=== DEBUG TEST ===")
print("If you see this in Output window, basic Lua works!")
print("GameId:", game.GameId)
print("PlaceId:", game.PlaceId)
print("==================")
