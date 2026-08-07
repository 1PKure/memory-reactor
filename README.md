# Memory Reactor

## Overview

**Memory Reactor** is a 3D memory-based game developed in **Godot 4**. The player must observe and reproduce reactor sequences while managing the reactor's stability across multiple rounds.

The main differentiating mechanic is the **Overclock System**, which introduces a risk/reward decision: the player can stabilize the reactor and play safely, or activate overclock to increase the challenge in exchange for additional score.

The project was designed with a controlled scope, focusing on a complete gameplay loop, clear UI feedback, reusable scene structure, and a polished Web-ready presentation.

## Core Gameplay

- Observe the reactor sequence.
- Reproduce the sequence correctly through player input.
- Complete successive rounds as the challenge increases.
- Manage reactor stability throughout the session.
- Choose between stabilizing the reactor or using **Overclock**.
- Earn additional score by accepting the increased risk of Overclock.
- Reach the end of the level without losing reactor stability.

## Overclock System

The Overclock mechanic is the core risk/reward feature of Memory Reactor.

When available, the player can choose to:

- **Stabilize the reactor:** maintain a safer state and reduce risk.
- **Overclock the reactor:** increase difficulty and instability in exchange for bonus score.

This forces the player to make an active decision between consistency and a higher scoring opportunity instead of only repeating memory sequences.

## Game Flow

The project includes a complete navigation and gameplay flow:

1. Splash Screen
2. Main Menu
3. Level Selector
4. Gameplay
5. Pause Menu
6. Win / Lose flow
7. Return to the corresponding menu or level flow

## Main Menu

The Main Menu was expanded beyond the default interface to provide a more complete game presentation.

Implemented features include:

- Animated background presentation.
- Sci-fi visual identity consistent with the game.
- Custom typography.
- Button hover feedback and UI animation.
- Main menu music.
- Access to Play, Options, and the remaining game flow.

## Level Selector

A dedicated Level Selector was implemented to separate level selection from gameplay logic.

It includes:

- Individual level entries.
- Level preview/navigation structure.
- Animated visual background.
- Reusable level-selection components.
- Separation between menu UI and gameplay scenes.

## Gameplay UI

The gameplay HUD was iterated after testing and teacher feedback to improve readability and game-state communication.

Current HUD elements include:

- Score display.
- Timer.
- Reactor stability indicator.
- Stability represented through a **ProgressBar** instead of plain text.
- Current round indicator.
- Overclock-related feedback.
- Win/Lose feedback.

## Pause System

The pause interface was corrected so that it always renders above the active gameplay scene.

The implementation uses the appropriate UI layering structure so that the pause menu is not hidden behind the 3D scene or gameplay HUD.

The pause flow allows the player to safely stop gameplay and return to the expected game state afterward.

## Options Menu

The options system was reviewed and simplified so that the exposed settings are relevant to the game.

Current configuration includes:

- **Audio settings**.
- **Video settings**.
- Reusable options UI shared between the Main Menu and Pause Menu flows.
- Centralized options structure through the master options menu.
- Removal of unnecessary input-related configuration from the visible tab structure.

Input actions remain managed through Godot's **Input Map**.

## Audio

Audio integration includes:

- Sci-fi background music for the Main Menu.
- Loop-compatible audio assets.
- Godot-compatible audio formats such as OGG/WAV.
- Separation between menu music and gameplay to avoid unnecessary distraction during the memory sequences.

## Visual Presentation

Several presentation passes were made during development:

- Custom splash screen.
- Animated menu backgrounds.
- Gameplay background integration.
- Texture transparency adjustments to preserve text readability.
- Lighting adjustments for the 3D environment.
- `WorldEnvironment` integration.
- Reduced excessive brightness and reflections to keep the scene readable without looking unnaturally illuminated.
- Improved reactor readability and visual hierarchy.

## Architecture

The project follows Godot's scene-based architecture and separates responsibilities between gameplay, menus, reusable UI, and level content.

Main architectural concepts used throughout the project include:

- Scene composition.
- Reusable UI scenes.
- Signals for decoupled communication between systems.
- Input actions managed through the Input Map.
- Centralized menu/options behavior.
- Separation between level content and global game flow.

The project was structured so that gameplay logic does not depend directly on presentation-only elements whenever possible.

## Project Structure

```text
memory-reactor/
├── addons/       # External Godot addons and reusable systems
├── assets/       # Textures, models, fonts, and visual assets
├── audio/        # Music and sound assets
├── builds/       # Local exported builds
├── examples/     # Reference/example content used during development
├── resources/    # Godot resources and configuration data
├── scenes/       # Menus, gameplay, levels, UI, and reusable scenes
├── scripts/      # GDScript gameplay and system logic
├── shaders/      # Custom shader resources
├── project.godot
└── README.md
```

The `builds/` directory is kept for local exports and is excluded from version control through `.gitignore`.

## Development Changes and Improvements

The project went through multiple review and polish passes. The main changes made during development include:

- Finalized the game name as **Memory Reactor**.
- Defined Overclock as the main differentiating gameplay mechanic.
- Added a complete Splash Screen → Menu → Level Selector → Gameplay flow.
- Added animated backgrounds to menu-related scenes.
- Added and refined sci-fi audio presentation.
- Improved gameplay lighting and environment configuration.
- Corrected gameplay/background rendering order issues.
- Corrected the Pause Menu so it renders above gameplay.
- Replaced the reactor stability text representation with a ProgressBar.
- Added a visible round counter.
- Improved reactor readability and player feedback.
- Refined the HUD to communicate the current game state more clearly.
- Refined Main Menu and Pause Menu options integration.
- Kept Audio and Video configuration available independently from gameplay.
- Simplified the options tabs by removing unnecessary input-related UI.
- Improved button hover and menu interaction feedback.
- Added support for Web export and itch.io distribution.
- Organized exported builds under a dedicated `builds/` directory.
- Added `builds/` to `.gitignore` so generated exports are not tracked by Git.

## Web Build

Memory Reactor is prepared for **Godot Web export** and browser distribution through platforms such as **itch.io**.

For browser builds, exported files should be generated from Godot's Web export preset and uploaded together as part of the final Web build package.

## Technologies

- **Engine:** Godot 4
- **Language:** GDScript
- **Rendering:** Godot 3D / PBR workflow
- **Target Platforms:** Web and PC
- **Version Control:** Git / GitHub

## Project Goal

Memory Reactor was developed as a complete Godot project focused on demonstrating:

- 3D scene creation.
- GDScript gameplay programming.
- Game flow and scene management.
- UI and menu systems.
- Input handling.
- Audio integration.
- Rendering and environment configuration.
- Reusable project architecture.
- A clearly defined original risk/reward mechanic through the Overclock System.
