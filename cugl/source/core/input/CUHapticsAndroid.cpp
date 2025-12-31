//
//  CUHapticsAndroid.cpp
//  TUGL, built for Cornell University Game Library (CUGL)
//
//  This module provides the Android implementation of the Haptics and
//  HapticPlayer classes. Currently a stub - will interface with Android
//  Vibrator service through JNI in future versions.
//
//
//  Author: Luke Leh (ll594)
//  Version: 3.0, 12/9/25

#include "cugl/core/input/CUHaptics.h"

#if defined(__ANDROID__)

#include "SDL_system.h"
#include <algorithm>
#include <android/log.h>
#include <jni.h>

using namespace cugl;

// Static member initialization
std::shared_ptr<Haptics::Impl> Haptics::_impl = nullptr;
bool Haptics::_initialized = false;

/**
 * Android implementation of Haptics::Impl
 * TODO: Implement JNI calls to Android Vibrator service
 */
class Haptics::Impl {
public:
  Impl() {}
  ~Impl() {}

  bool isSupported() {
    // TODO: Check if device has vibrator via JNI
    return true;
  }

  void light() {
    // TODO: Call Android vibrator with light pattern
  }

  void medium() {
    // TODO: Call Android vibrator with medium pattern
  }

  void heavy() {
    // TODO: Call Android vibrator with heavy pattern
  }

  void selection() {
    // TODO: Call Android vibrator with selection pattern
  }

  void tap(float intensity, float sharpness) {
    // TODO: Call Android vibrator with short vibration
    // Note: Android doesn't support sharpness parameter
  }

  void buzz(float intensity, float sharpness, float duration) {
    // TODO: Call Android vibrator with timed vibration
  }

  bool play(const std::string &filename) {
    // TODO: Parse AHAP and create Android vibration pattern
    return false;
  }
};

// Haptics public API
bool Haptics::init() {
  if (_initialized)
    return true;
  _impl = std::make_shared<Impl>();
  _initialized = true;
  return true;
}

void Haptics::dispose() {
  _impl = nullptr;
  _initialized = false;
}

bool Haptics::isSupported() {
  if (!_initialized || !_impl)
    return false;
  return _impl->isSupported();
}

void Haptics::light() {
  if (_initialized && _impl)
    _impl->light();
}

void Haptics::medium() {
  if (_initialized && _impl)
    _impl->medium();
}

void Haptics::heavy() {
  if (_initialized && _impl)
    _impl->heavy();
}

void Haptics::selection() {
  if (_initialized && _impl)
    _impl->selection();
}

void Haptics::tap(float intensity, float sharpness) {
  if (_initialized && _impl)
    _impl->tap(intensity, sharpness);
}

void Haptics::buzz(float intensity, float sharpness, float duration) {
  if (_initialized && _impl)
    _impl->buzz(intensity, sharpness, duration);
}

bool Haptics::play(const std::string &filename) {
  if (!_initialized || !_impl)
    return false;
  return _impl->play(filename);
}

/**
 * Android implementation of HapticPlayer::Impl
 * TODO: Implement controlled vibration playback
 */
class HapticPlayer::Impl {
public:
  Impl() {}
  ~Impl() {}

  void start(float intensity, float sharpness) {
    // TODO: Start continuous vibration
  }

  bool load(const std::string &filename) {
    // TODO: Load AHAP pattern
    return false;
  }

  void play() {
    // TODO: Start playback
  }

  void pause() {
    // TODO: Pause playback
  }

  void stop() {
    // TODO: Stop playback
  }

  bool isPlaying() const { return false; }

  void setLooping(bool loop) {
    // TODO: Set looping state
  }

  void setIntensity(float intensity) {
    // TODO: Update intensity (if supported)
  }

  void setSharpness(float sharpness) {
    // TODO: Update sharpness (not supported on Android)
  }
};

// HapticPlayer public API

HapticPlayer::HapticPlayer()
    : _impl(std::make_unique<Impl>()), _intensity(1.0f), _sharpness(0.5f),
      _looping(false) {}

HapticPlayer::~HapticPlayer() = default;

HapticPlayer::HapticPlayer(HapticPlayer &&other) noexcept
    : _impl(std::move(other._impl)), _intensity(other._intensity),
      _sharpness(other._sharpness), _looping(other._looping) {}

HapticPlayer &HapticPlayer::operator=(HapticPlayer &&other) noexcept {
  if (this != &other) {
    _impl = std::move(other._impl);
    _intensity = other._intensity;
    _sharpness = other._sharpness;
    _looping = other._looping;
  }
  return *this;
}

void HapticPlayer::start(float intensity, float sharpness) {
  _intensity = std::max(0.0f, std::min(1.0f, intensity));
  _sharpness = std::max(0.0f, std::min(1.0f, sharpness));
  if (_impl)
    _impl->start(_intensity, _sharpness);
}

bool HapticPlayer::load(const std::string &filename) {
  if (!_impl)
    return false;
  return _impl->load(filename);
}

void HapticPlayer::play() {
  if (_impl)
    _impl->play();
}

void HapticPlayer::pause() {
  if (_impl)
    _impl->pause();
}

void HapticPlayer::stop() {
  if (_impl)
    _impl->stop();
}

bool HapticPlayer::isPlaying() const {
  if (!_impl)
    return false;
  return _impl->isPlaying();
}

void HapticPlayer::setLooping(bool loop) {
  _looping = loop;
  if (_impl)
    _impl->setLooping(loop);
}

void HapticPlayer::setIntensity(float intensity) {
  _intensity = std::max(0.0f, std::min(1.0f, intensity));
  if (_impl)
    _impl->setIntensity(_intensity);
}

void HapticPlayer::setSharpness(float sharpness) {
  _sharpness = std::max(0.0f, std::min(1.0f, sharpness));
  if (_impl)
    _impl->setSharpness(_sharpness);
}

#endif // defined(__ANDROID__)
