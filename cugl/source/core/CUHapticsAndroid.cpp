//
//  CUHapticsAndroid.cpp
//
//  This module provides the Android implementation of the HapticFeedback class.
//  It will interface with the Android Vibrator service through JNI.
//
//  Author: Luke Leh (ll594)
//  Version: 1.1, 5/13/25
//

#include "cugl/core/input/CUHaptics.h"

// Only compile this file for Android
#if defined(__ANDROID__)

#include "SDL_system.h"
#include <android/log.h>
#include <jni.h>

using namespace cugl;

/**
 * Implementation of the nested HapticImpl class for Android
 */
class HapticFeedback::HapticImpl {
public:
  HapticImpl() {
    // Initialize JNI and Android Vibrator service references
  }

  ~HapticImpl() {
    // Clean up JNI references
  }

  bool isSupported() {
    // Future implementation: Check if device has vibrator
    // Example JNI call:
    /*
    JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv();
    jobject activity = (jobject)SDL_AndroidGetActivity();
    jclass clazz = env->GetObjectClass(activity);
    jmethodID methodID = env->GetMethodID(clazz, "hasVibrator", "()Z");
    jboolean hasVibrator = env->CallBooleanMethod(activity, methodID);

    env->DeleteLocalRef(activity);
    env->DeleteLocalRef(clazz);

    return hasVibrator;
    */

    // Placeholder implementation
    return true;
  }

  void triggerLight() {
    // Future implementation: Call Android Vibrator with light pattern
    // Example JNI call:
    /*
    JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv();
    jobject activity = (jobject)SDL_AndroidGetActivity();
    jclass clazz = env->GetObjectClass(activity);
    jmethodID methodID = env->GetMethodID(clazz, "vibrateLight", "()V");
    env->CallVoidMethod(activity, methodID);

    env->DeleteLocalRef(activity);
    env->DeleteLocalRef(clazz);
    */
  }

  void triggerMedium() {
    // Future implementation: Call Android Vibrator with medium pattern
  }

  void triggerHeavy() {
    // Future implementation: Call Android Vibrator with heavy pattern
  }

  void triggerSelection() {
    // Future implementation: Call Android Vibrator with selection pattern
  }

  bool triggerCustom(const std::string &filename) {
    // Future implementation: Load custom pattern from file
    return false;
  }
};

// Implementation of the public API methods
bool HapticFeedback::init() {
  if (_initialized)
    return true;

  _impl = std::make_shared<HapticImpl>();
  _initialized = true;
  return true;
}

bool HapticFeedback::isSupported() {
  if (!_initialized)
    return false;
  return _impl->isSupported();
}

void HapticFeedback::triggerLight() {
  if (!_initialized)
    return;
  _impl->triggerLight();
}

void HapticFeedback::triggerMedium() {
  if (!_initialized)
    return;
  _impl->triggerMedium();
}

void HapticFeedback::triggerHeavy() {
  if (!_initialized)
    return;
  _impl->triggerHeavy();
}

void HapticFeedback::triggerSelection() {
  if (!_initialized)
    return;
  _impl->triggerSelection();
}

bool HapticFeedback::triggerCustom(const std::string &filename) {
  if (!_initialized)
    return false;
  return _impl->triggerCustom(filename);
}

void HapticFeedback::dispose() {
  _impl = nullptr;
  _initialized = false;
}

#endif // defined(__ANDROID__)
