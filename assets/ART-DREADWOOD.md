# Dreadwood vector art

New source-authored SVG atlases are maintained by tools/build_visual_assets.py using only Python's standard library. Run that script from any directory to regenerate the same SVG bytes. No remote image service or third-party art download is needed at runtime or build time. Original sprites.svg and all existing license/credit notices remain in the project.

Enemy atlas: 640×480, five columns of 128×160 cells, in this order: goblin, skeleton, archer, ice_archer, guardian, slime, bog_toad, wisp, crystal_wisp, wolf, frost_wolf, root_warden, hollow_heart. Empty final cells are intentional. Feet anchor around source y=128. The game renders ordinary creatures at 64×80, bosses at 96×120; this does not alter their collision radius.

Environment atlas: 512×192; four 128×192 cells: tree, rock, closed chest, open chest. Feet anchor around y=128. New atlases use clipped texture sampling, alpha borders, no mipmap chain and no runtime vector tessellation. Godot imports them once into textures. Approximate raw RGBA budget: 1,622,016 bytes total before engine overhead.

Slower phones keep all creature designs in Performance quality with no real lights; optional lighting is controlled separately. Native drawing adds breathing, hover, existing lunges/recoil and hit/slow tint without changing game state.
