//
//  CUHaptics.h
//
//  This module provides cross-platform haptic feedback support.
//  TUGL, built for Cornell University Game Library (CUGL)
//
//
//  TUGL MIT License:
//      This software is provided 'as-is', without any express or implied
//      warranty.  In no event will the authors be held liable for any damages
//      arising from the use of this software.
//
//      Permission is granted to anyone to use this software for any purpose,
//      including commercial applications, and to alter it and redistribute it
//      freely, subject to the following restrictions:
//
//      1. The origin of this software must not be misrepresented; you must not
//      claim that you wrote the original software. If you use this software
//      in a product, an acknowledgment in the product documentation would be
//      appreciated but is not required.
//
//      2. Altered source versions must be plainly marked as such, and must not
//      be misrepresented as being the original software.
//
//      3. This notice may not be removed or altered from any source
//      distribution.
//
//
//  Author: Luke Leh (ll594)
//  Version: 3.0, 12/9/25

#ifndef __CU_HAPTICS_H__
#define __CU_HAPTICS_H__

#include <cugl/core/input/CUInput.h>
#include <memory>
#include <string>

namespace cugl
{

  /**
   * Static utility class for fire-and-forget haptic feedback.
   *
   * Use this class for simple haptic effects that play immediately and require
   * no lifecycle management. For haptics that need to be stopped, paused, or
   * modulated in real-time, use HapticPlayer instead.
   *
   * Think of Haptics like firing a gun - pull the trigger, bullet fires, done.
   * You don't control the bullet after it leaves.
   *
   * Example usage:
   * ```
   * // Button click
   * Haptics::medium();
   *
   * // Dynamic drag feedback
   * void onDrag(Vec2 velocity) {
   *     float intensity = std::min(velocity.length(), 2000.0f) / 2000.0f;
   *     if (intensity > 0.05f) {
   *         Haptics::tap(intensity, 0.5f);
   *     }
   * }
   *
   * // Play a pre-designed pattern
   * Haptics::play("explosion.ahap");
   * ```
   */
  class Haptics
  {
  private:
    /** Private implementation class */
    class Impl;

    /** Shared pointer to implementation */
    static std::shared_ptr<Impl> _impl;

    /** Whether haptics have been initialized */
    static bool _initialized;

    /** HapticPlayer needs access to the shared engine */
    friend class HapticPlayer;

  public:
#pragma mark - Lifecycle

    /**
     * Initializes the haptic feedback system.
     *
     * This must be called before using any other haptic methods.
     *
     * @return true if initialization was successful
     */
    static bool init();

    /**
     * Cleans up haptic feedback resources.
     *
     * Call this when shutting down the application.
     */
    static void dispose();

    /**
     * Returns whether haptic feedback is supported on this device.
     *
     * @return true if haptics are supported
     */
    static bool isSupported();

#pragma mark - Preset Feedback

    /** Triggers light haptic feedback (subtle tap). */
    static void light();

    /** Triggers medium haptic feedback (standard tap). */
    static void medium();

    /** Triggers heavy haptic feedback (strong impact). */
    static void heavy();

    /** Triggers selection feedback (picker/list tick). */
    static void selection();

#pragma mark - Custom Feedback

    /**
     * Plays a transient (tap) haptic effect using UIImpactFeedbackGenerator.
     *
     * A transient haptic is a brief, sharp tap sensation. This method uses
     * UIImpactFeedbackGenerator internally, which is efficient for high-frequency
     * calls but has limited sharpness control (only 3 levels).
     *
     * Use this for maximum performance when calling haptics very rapidly.
     * Use transient() instead for full intensity + sharpness control.
     *
     * @param intensity The haptic intensity (0.0 = silent, 1.0 = max)
     * @param sharpness The haptic sharpness (0.0 = dull/round, 1.0 = sharp/crisp)
     *                  Note: Sharpness is approximated using light/medium/heavy generators
     */
    static void tap(float intensity, float sharpness = 0.5f);

    /**
     * Plays a transient haptic effect using full CoreHaptics.
     *
     * This is the exact equivalent of the Swift CHHapticEvent(.hapticTransient)
     * approach. Provides true continuous control over BOTH intensity AND sharpness,
     * unlike tap() which approximates sharpness using generator presets.
     *
     * Safe for high-frequency calls (uses delayed release like Swift's ARC).
     * Use this when you need precise haptic expression, like the Fidgetable app.
     *
     * Example (equivalent to Swift Fidgetable's slideHaptic):
     * ```
     * void onDrag(Vec2 velocity) {
     *     float intensity = std::min(velocity.length(), 2500.0f) / 2500.0f;
     *     if (intensity > 0.05f) {
     *         Haptics::transient(intensity, 0.5f);
     *     }
     * }
     * ```
     *
     * @param intensity The haptic intensity (0.0 = silent, 1.0 = max)
     * @param sharpness The haptic sharpness (0.0 = dull/round, 1.0 = sharp/crisp)
     */
    static void transient(float intensity, float sharpness = 0.5f);

    /**
     * Plays a continuous (buzz) haptic effect with fixed duration.
     *
     * A continuous haptic is a sustained vibration/rumble. Ideal for
     * explosions, short rumbles, and timed effects.
     *
     * @param intensity The haptic intensity (0.0 = silent, 1.0 = max)
     * @param sharpness The haptic sharpness (0.0 = dull/smooth, 1.0 = sharp/buzzy)
     * @param duration The duration in seconds
     */
    static void buzz(float intensity, float sharpness, float duration);

    /**
     * Plays a haptic pattern from an AHAP file.
     *
     * AHAP (Apple Haptic and Audio Pattern) files define complex haptic
     * sequences. The pattern plays immediately and cannot be stopped.
     *
     * @param filename The path to the AHAP file
     * @return true if the pattern was successfully started
     */
    static bool play(const std::string &filename);
  };

  /**
   * Instance-based haptic player for controllable playback.
   *
   * Use this class when you need haptics that play until explicitly stopped,
   * can be paused/resumed, or need real-time intensity adjustment. Each
   * HapticPlayer instance is independent - multiple can play concurrently.
   *
   * Think of HapticPlayer like holding a garden hose - turn on, water flows,
   * turn off when done. You control the flow while it's running.
   *
   * Example usage:
   * ```
   * // Toggle rumble on/off
   * auto rumble = HapticPlayer::alloc();
   * rumble->start(0.5f, 0.3f);  // Starts rumbling...
   * // ... later
   * rumble->stop();  // Now it stops
   *
   * // Looping pattern with real-time modulation
   * auto engine = HapticPlayer::alloc();
   * engine->load("engine_rumble.ahap");
   * engine->setLooping(true);
   * engine->play();
   * // In game loop:
   * engine->setIntensity(rpm / maxRpm);
   * ```
   */
  class HapticPlayer
  {
  private:
    /** Private implementation class */
    class Impl;

    /** Pointer to implementation */
    std::unique_ptr<Impl> _impl;

    /** Current intensity value (0.0 - 1.0) */
    float _intensity;

    /** Current sharpness value (0.0 - 1.0) */
    float _sharpness;

    /** Whether looping is enabled */
    bool _looping;

  public:
    /**
     * Creates a haptic player ready for use.
     */
    HapticPlayer();

    /**
     * Destroys this haptic player, releasing all resources.
     */
    ~HapticPlayer();

    // Disable copy
    HapticPlayer(const HapticPlayer &) = delete;
    HapticPlayer &operator=(const HapticPlayer &) = delete;

    // Enable move
    HapticPlayer(HapticPlayer &&other) noexcept;
    HapticPlayer &operator=(HapticPlayer &&other) noexcept;

#pragma mark - Static Allocator

    /**
     * Returns a newly allocated haptic player ready for use.
     *
     * @return A newly allocated haptic player
     */
    static std::shared_ptr<HapticPlayer> alloc()
    {
      return std::make_shared<HapticPlayer>();
    }

#pragma mark - Starting Haptics

    /**
     * Starts a simple continuous haptic with the given parameters.
     *
     * This is the easiest way to start a controllable haptic. The haptic
     * plays continuously until stop() is called. Use setLooping(true) if
     * you want it to loop (which is the default behavior for start()).
     *
     * @param intensity The haptic intensity (0.0 - 1.0)
     * @param sharpness The haptic sharpness (0.0 - 1.0)
     */
    void start(float intensity, float sharpness);

    /**
     * Loads a haptic pattern from an AHAP file.
     *
     * After loading, call play() to start the pattern. This allows for
     * more complex haptic sequences than start() provides.
     *
     * @param filename The path to the AHAP file
     * @return true if the pattern was successfully loaded
     */
    bool load(const std::string &filename);

#pragma mark - Playback Control

    /**
     * Starts or resumes haptic playback.
     *
     * If paused, resumes from where it left off. If stopped, starts from
     * the beginning. For simple continuous haptics, use start() instead.
     */
    void play();

    /**
     * Pauses haptic playback.
     *
     * The haptic can be resumed by calling play().
     */
    void pause();

    /**
     * Stops haptic playback and resets to the beginning.
     */
    void stop();

    /**
     * Returns whether this player is currently playing.
     *
     * @return true if playing
     */
    bool isPlaying() const;

#pragma mark - Looping

    /**
     * Sets whether this player should loop.
     *
     * When enabled, the haptic repeats indefinitely until stop() is called.
     *
     * @param loop true to enable looping
     */
    void setLooping(bool loop);

    /**
     * Returns whether looping is enabled.
     *
     * @return true if looping
     */
    bool isLooping() const { return _looping; }

#pragma mark - Real-time Modulation

    /**
     * Sets the haptic intensity.
     *
     * Can be called during playback for real-time modulation.
     *
     * @param intensity The intensity (0.0 = silent, 1.0 = full)
     */
    void setIntensity(float intensity);

    /**
     * Returns the current haptic intensity.
     *
     * @return The intensity (0.0 - 1.0)
     */
    float getIntensity() const { return _intensity; }

    /**
     * Sets the haptic sharpness.
     *
     * Can be called during playback for real-time modulation.
     *
     * @param sharpness The sharpness (0.0 = dull, 1.0 = sharp)
     */
    void setSharpness(float sharpness);

    /**
     * Returns the current haptic sharpness.
     *
     * @return The sharpness (0.0 - 1.0)
     */
    float getSharpness() const { return _sharpness; }
  };

} // namespace cugl

#endif /* __CU_HAPTICS_H__ */
