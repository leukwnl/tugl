<div align="center">

# tugl
###  Haptics Library for CUGL

<img height="280" alt="logo" src="https://github.com/user-attachments/assets/e64be617-7fd7-4464-978b-a55ed913f7d3" />
</div>

## What is `tugl`?
`tugl` (pronounced 'tuggle') is a companion library to Cornell University’s Game Library (CUGL) for crafting haptic experiences on iOS and Android devices.

By bridging Core Haptics on iOS with Android's vibration APIs (via JNI), tugl aims to provide developers with a unified, platform agnostic API for triggering responsive and dynamic haptic effects.

Save time from writing platform-specific Objective-C, Swift, or Java/Kotlin code. No more custom JNI glue. `tugl` gives developers clean unified calls from C++ that can work anywhere.

*API Documentation coming soon.*

## Motivation
Feedback from in-game events shapes how players experience video games and interactive media as a whole. Visual and auditory feedback are commonly used to enhance game feel, but one often underappreciated domain is touch. This is especially true in showcase environments, which are frequently loud and distracting. In such spaces, auditory feedback can easily be drowned out, diminishing the player’s experience. Haptic feedback introduces a new way for players to feel what’s happening in the game, while also offering a more accessible avenue for experiencing interactive systems.

In the history of Cornell's CS4152/5152: Advanced Game Architecture at Cornell courses, *no* mobile game project (to my knowledge) has successfully implemented haptic feedback until 2025. I created the first successful implementation for innate studios and our game *Trigger Happy*.

The absence of haptics hasn't been due to lack of interest, rather because doing so has traditionally been impractical. Common obstacles include:
- Platform fragmentation: iOS uses Core Haptics or UIFeedbackGenerator, while Android uses multiple vibration APIs with behaviors varying between devices.
- Lack of JNI experience: Student teams often avoid writing or debugging native bridges for Android due to time constraints.
- Minimal engine support: CUGL provides no built-in abstractions for haptics, forcing teams to write everything from scratch on both platforms.

Yet haptics are one of the most impactful UX tools available to game designers. They provide:
- Instant, intuitive feedback
- Increased game feel
- A channel for accessibile feedback
- Higher player immersion

`tugl` aims to remove these barriers and make high-quality haptics easy and standardized for all future mobile games built on CUGL.

This project also aims to provide a clear example of cross-platform bridging. Although such extensions are recommended in the course, there has historically been little example content for students to reference. `tugl` helps fill that gap in how it write extensions for the CUGL engine, bridging libraries from both Android and iOS.

## Updates
- Currently, only iOS haptics are supported.
- Android platform bridging is on hiatus at the moment.
- Feel free to contact me if you'd like to contribute!

## Usage
For now, only manual extraction is supported.
1. Extract `cugl\` to the root directory that contains the CUGL library.
2. Replace the file `cu_input.h` at `cugl\Include\cugl\core\input` when prompted.
3. Then, add the new files to the XCode Project.
4. To do that, find the `cugl\Include\cugl\core\input` folder on the XCode project navigator, and add the file `CUHaptics.h`.
5. Finally, find the `cugl\Source\cugl\core\input` folder on the XCode project navigator, then add the files `CUHapticsStub.cpp`, `CUHapticsAndroid.cpp` and `CUHapticsApple.mm`.

## Examples
See more at [`tuggle-demo`](https://github.com/leukwnl/tuggle-demo).

## Contributing
Email me at ll594@cornell.edu for any tweaks, bugs or contributions.

## What Else?
If this library helped your game feel better at all, stars are appreciated!
