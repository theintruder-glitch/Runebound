# Runebound Android repository

This repository contains the recovered **v0.12.0 editable Godot game source**, configured for **Android ARM64** with touchscreen controls and an Android-only export preset.

The source was previously described as the "Laptop Edition" because that version also added Windows-specific functionality. This repository is now Android-focused. Desktop-related helper code stays only where it is still referenced by the game; it does not turn Android exports into Windows builds.

**Not included:** Android signing keys, prior APKs, the historical legacy-Android migration bundle, or a completed v0.13.0 project.

Do not commit `.jks` files or credentials. Keep your original Android signing key secure to preserve update compatibility with the app already installed on your phone.

Building and testing the APK is a separate step; changing the export preset does **not** automatically create an installable APK.
