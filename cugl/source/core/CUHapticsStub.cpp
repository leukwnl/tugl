//
//  CUHapticsStub.cpp
//  Cornell University Game Library (CUGL)
//
//  This module provides empty stub implementations of the HapticFeedback class
//  for platforms that do not support haptic feedback (Windows, macOS, Linux).
//
//  Author: Luke Leh (ll594)
//  Version: 1.1, 5/13/25
//

#include "cugl/core/input/CUHaptics.h"

// Only compile this file for desktop platforms
#if !defined(__ANDROID__) && !defined(TARGET_OS_IPHONE) &&                     \
    !defined(TARGET_OS_MAC)

using namespace cugl;

/**
 * Implementation of the nested HapticImpl class for desktop platforms
 */
class HapticFeedback::HapticImpl {
public:
  HapticImpl() {}
  ~HapticImpl() {}

  bool isSupported() { return false; }
  void triggerLight() {}
  void triggerMedium() {}
  void triggerHeavy() {}
  void triggerSelection() {}
  bool triggerCustom(const std::string &) { return false; }
};

// Implementation of the public API methods
bool HapticFeedback::init() {
  if (_initialized)
    return true;

  _impl = std::make_shared<HapticImpl>();
  _initialized = true;
  return true;
}

bool HapticFeedback::isSupported() { return false; }

void HapticFeedback::triggerLight() {
  // Do nothing on desktop
}

void HapticFeedback::triggerMedium() {
  // Do nothing on desktop
}

void HapticFeedback::triggerHeavy() {
  // Do nothing on desktop
}

void HapticFeedback::triggerSelection() {
  // Do nothing on desktop
}

bool HapticFeedback::triggerCustom(const std::string &filename) {
  // Do nothing on desktop
  return false;
}

void HapticFeedback::dispose() {
  _impl = nullptr;
  _initialized = false;
}

#endif // Desktop platforms
