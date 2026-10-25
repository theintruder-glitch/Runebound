# Thornwatch Keep

`thornwatch.png` is the restored original image-generation asset from the saved
0.25.0 checkpoint. Its dark gothic spires, gray stone, gold trim, ivy, violet
windows and green gate follow the VYRNSPIRE website reference used in the prior
development session. The live website returned an authentication wall during
this resume, so no new claim of inspecting the live website is made.

The transparent exterior is a single 1254 × 1254 image (about 6 MiB base RGBA),
drawn only when the castle overlaps cached visible scenery. The collidable
exterior foundation, approach road and entrance transition are authored in
`scripts/kingdom_landscape.gd`; the image is not used as a gameplay collision mask.

The interior is a separate three-level playable layout, with seventeen named
rooms in total. Only one level's terrain, actors and props are active. Existing
enemy and environment atlases remain original editable project assets.

Riverbanks, hill contours, cliff strata, bridge, paths, vegetation accents and
water animation are lightweight cached/distance-culled Godot draw commands.
No generated bitmap was reconstructed or edited during this resume.
