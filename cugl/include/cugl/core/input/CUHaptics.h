//
//  CUHaptics.h
//
//  This class provides cross-platform haptic feedback support.
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
//  Version: 2.0, 12/4/25

#ifndef __CU_HAPTICS_H__
#define __CU_HAPTICS_H__

#include <cugl/core/input/CUInput.h>
#include <memory>
#include <string>

namespace cugl {

/**
 * Provides cross-platform haptic feedback functionality.
 */
class HapticFeedback {
private:
  /** Private implementation class */
  class HapticImpl;

  /** Shared pointer to implementation */
  static std::shared_ptr<HapticImpl> _impl;

  /** Whether haptics have been initialized */
  static bool _initialized;

public:
  /**
   * Initializes the haptic feedback system.
   *
   * @return true if initialization was successful
   */
  static bool init();

  /**
   * Returns whether the haptic system has been initialized.
   *
   * @return true if initialized
   */
  static bool isInitialized() { return _initialized; }

  /**
   * Returns whether haptic feedback is supported on this device.
   *
   * @return true if supported
   */
  static bool isSupported();

  /** Triggers light haptic feedback. */
  static void triggerLight();

  /** Triggers medium haptic feedback. */
  static void triggerMedium();

  /** Triggers heavy haptic feedback. */
  static void triggerHeavy();

  /** Triggers selection feedback. */
  static void triggerSelection();

  /**
   * Triggers a custom haptic pattern from a file.
   *
   * @param filename The filename of the custom haptic pattern
   * @return true if pattern was successfully played
   */
  static bool triggerCustom(const std::string &filename);

  /** Cleans up haptic feedback resources. */
  static void dispose();
};

} // namespace cugl

#endif /* __CU_HAPTICS_H__ */
