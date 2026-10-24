# 0.13 PC performance bounds

Graphics quality has Performance, Balanced and Rich settings. A fixed pool contains eight shadow-free PointLight2D nodes; Balanced enables up to four and Rich up to eight. Performance and the safe launcher disable those lights and ground-detail additions. Scenery draw commands are cached using the original camera/chest/build invalidation path. Terrain texture noise is generated when the seasonal palette changes, not every frame. Spell zones and temporary visual effects use existing bounded world simulation and redraw paths. The laptop frame cap is adjustable to 30 or 60 FPS.

These bounds and passing headless integration checks do not establish the player's Windows GPU performance. This environment could not open a native graphics display; no rendered screenshot or physical FPS result is claimed. Use Performance or Start-Low-Power.bat on a laptop where Balanced is slow.

# Reproducing the script benchmark

Run `godot --headless --path . --script res://tests/benchmark.gd`.

The benchmark creates 38 enemies, including off-screen enemies, requests 250 drawing frames and samples render-command construction after a warmup. It then times 600 simulation ticks. Frame caps are disabled during this measurement. It measures CPU-side GDScript work in a synthetic headless scene, not rendered GPU frames or physical phone performance. The version 0.3 baseline is available from the project's prior archive version. See VERIFICATION.md for the observed result and limits.

Run `godot --headless --path . --script res://tests/test_movement.gd` for movement, camera, cache, and mode checks. Tests write fixture saves into the engine's user-data directory; back up development saves before running them.

For landscape movement checks, append `-- landscape` to the movement command. The suite sets the logical viewport explicitly because physical headless window sizes are not reliable.

Run `godot --headless --path . --script res://tests/test_live_frames.gd` for the real-loop drawing regression; append `-- landscape` for the wider viewport. This catches disabled world processing, which the original coordinate-only suite missed. Historical synthetic benchmark results manually invoked drawing and must not be read as proof of live movement.
