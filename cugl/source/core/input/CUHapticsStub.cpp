//
//  CUHapticsStub.cpp
//  TUGL, built for Cornell University Game Library (CUGL)
//
//  This module provides stub implementations of the Haptics and HapticPlayer
//  classes for platforms that do not support haptic feedback (Windows, Linux).
//
//
//  Author: Luke Leh (ll594)
//  Version: 3.0, 12/9/25

#include "cugl/core/input/CUHaptics.h"
#include <algorithm>

// Only compile for desktop platforms (not Android, not iOS/macOS)
#if !defined(__ANDROID__) && !defined(TARGET_OS_IPHONE) && \
    !defined(TARGET_OS_MAC)

using namespace cugl;

// =============================================================================
// Haptics Stub Implementation
// =============================================================================

class Haptics::Impl
{
public:
  Impl() {}
  ~Impl() {}
  bool isSupported() { return false; }
  void light() {}
  void medium() {}
  void heavy() {}
  void selection() {}
  void tap(float, float) {}
  void buzz(float, float, float) {}
  bool play(const std::string &) { return false; }
};

// Static member initialization
std::shared_ptr<Haptics::Impl> Haptics::_impl = nullptr;
bool Haptics::_initialized = false;

bool Haptics::init()
{
  if (_initialized)
    return true;
  _impl = std::make_shared<Impl>();
  _initialized = true;
  return true;
}

void Haptics::dispose()
{
  _impl = nullptr;
  _initialized = false;
}

bool Haptics::isSupported() { return false; }
void Haptics::light() {}
void Haptics::medium() {}
void Haptics::heavy() {}
void Haptics::selection() {}
void Haptics::tap(float intensity, float sharpness) {}
void Haptics::buzz(float intensity, float sharpness, float duration) {}
bool Haptics::play(const std::string &filename) { return false; }

// =============================================================================
// HapticPlayer Stub Implementation
// =============================================================================

class HapticPlayer::Impl
{
public:
  Impl() {}
  ~Impl() {}
  void start(float, float) {}
  bool load(const std::string &) { return false; }
  void play() {}
  void pause() {}
  void stop() {}
  bool isPlaying() const { return false; }
  void setLooping(bool) {}
  void setIntensity(float) {}
  void setSharpness(float) {}
};

HapticPlayer::HapticPlayer()
    : _impl(std::make_unique<Impl>()), _intensity(1.0f), _sharpness(0.5f),
      _looping(false) {}

HapticPlayer::~HapticPlayer() = default;

HapticPlayer::HapticPlayer(HapticPlayer &&other) noexcept
    : _impl(std::move(other._impl)), _intensity(other._intensity),
      _sharpness(other._sharpness), _looping(other._looping) {}

HapticPlayer &HapticPlayer::operator=(HapticPlayer &&other) noexcept
{
  if (this != &other)
  {
    _impl = std::move(other._impl);
    _intensity = other._intensity;
    _sharpness = other._sharpness;
    _looping = other._looping;
  }
  return *this;
}

void HapticPlayer::start(float intensity, float sharpness)
{
  _intensity = std::max(0.0f, std::min(1.0f, intensity));
  _sharpness = std::max(0.0f, std::min(1.0f, sharpness));
}

bool HapticPlayer::load(const std::string &filename) { return false; }
void HapticPlayer::play() {}
void HapticPlayer::pause() {}
void HapticPlayer::stop() {}
bool HapticPlayer::isPlaying() const { return false; }
void HapticPlayer::setLooping(bool loop) { _looping = loop; }

void HapticPlayer::setIntensity(float intensity)
{
  _intensity = std::max(0.0f, std::min(1.0f, intensity));
}

void HapticPlayer::setSharpness(float sharpness)
{
  _sharpness = std::max(0.0f, std::min(1.0f, sharpness));
}

#endif // Desktop platforms
