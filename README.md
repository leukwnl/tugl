# `tugl` — Mobile Platform Haptics for CUGL
## What is `tugl`?
`tugl` (pronounced 'tuggle') is a companion library to Cornell University’s Game Library (CUGL) that enables haptic feedback in mobile games on iOS and Android devices.

By bridging Core Haptics on iOS with Android's vibration APIs (via JNI), tugl provides developers a unified, platform agnostic API for triggering responsive and dynamic haptic effects.

Save time from writing platform-specific Objective-C, Swift, or Java/Kotlin code. No more custom JNI glue. `tugl` gives developers clean unified calls from C++ that can work anywhere.

*Documentation coming soon.*

## Motivation
In the history of Cornell's CS4152/5152: Advanced Game Architecture at Cornell courses, *no* mobile game project has successfully implemented haptic feedback until 2025. I created the first successful implementation for innate studios and our game *Trigger Happy*.

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

## Quick Start

## Usage

## Examples

## Contributing

## What Else?
