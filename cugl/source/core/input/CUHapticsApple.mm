//
//  CUHapticsApple.mm
//  TUGL, built for Cornell University Game Library (CUGL)
//
//  iOS implementation of the Haptics and HapticPlayer classes.
//
//  Architecture:
//    - Single shared CHHapticEngine (per Apple's recommendation)
//    - Pre-allocated UIFeedbackGenerators for preset haptics
//    - HapticPlayer instances borrow the shared engine
//
//  Author: Luke Leh (ll594)
//  Version: 4.1, 12/30/25
//
//  TUGL MIT License - See header file for full license text.
//

#include "cugl/core/input/CUHaptics.h"
#include <TargetConditionals.h>
#include <algorithm>

using namespace cugl;

std::shared_ptr<Haptics::Impl> Haptics::_impl = nullptr;
bool Haptics::_initialized = false;

// =============================================================================
#pragma mark - Non-iOS Stubs
// =============================================================================

#if !TARGET_OS_IPHONE

class Haptics::Impl {
public:
  bool isSupported() { return false; }
  void light() {}
  void medium() {}
  void heavy() {}
  void selection() {}
  void tap(float, float) {}
  void transient(float, float) {}
  void buzz(float, float, float) {}
  bool play(const std::string &) { return false; }
  void *getSharedEngine() { return nullptr; }
};

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

bool Haptics::isSupported() { return false; }
void Haptics::light() {}
void Haptics::medium() {}
void Haptics::heavy() {}
void Haptics::selection() {}
void Haptics::tap(float, float) {}
void Haptics::transient(float, float) {}
void Haptics::buzz(float, float, float) {}
bool Haptics::play(const std::string &) { return false; }

class HapticPlayer::Impl {
public:
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

static inline float clamp01(float v) { return std::max(0.f, std::min(1.f, v)); }

HapticPlayer::HapticPlayer()
    : _impl(std::make_unique<Impl>()), _intensity(1.f), _sharpness(0.5f),
      _looping(false) {}
HapticPlayer::~HapticPlayer() = default;
HapticPlayer::HapticPlayer(HapticPlayer &&o) noexcept
    : _impl(std::move(o._impl)), _intensity(o._intensity),
      _sharpness(o._sharpness), _looping(o._looping) {}
HapticPlayer &HapticPlayer::operator=(HapticPlayer &&o) noexcept {
  if (this != &o) {
    _impl = std::move(o._impl);
    _intensity = o._intensity;
    _sharpness = o._sharpness;
    _looping = o._looping;
  }
  return *this;
}
void HapticPlayer::start(float i, float s) {
  _intensity = clamp01(i);
  _sharpness = clamp01(s);
}
bool HapticPlayer::load(const std::string &) { return false; }
void HapticPlayer::play() {}
void HapticPlayer::pause() {}
void HapticPlayer::stop() {}
bool HapticPlayer::isPlaying() const { return false; }
void HapticPlayer::setLooping(bool l) { _looping = l; }
void HapticPlayer::setIntensity(float i) { _intensity = clamp01(i); }
void HapticPlayer::setSharpness(float s) { _sharpness = clamp01(s); }

#else

// =============================================================================
#pragma mark - iOS Implementation
// =============================================================================

#import <CoreHaptics/CoreHaptics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

namespace {

inline float clamp01(float v) { return std::max(0.f, std::min(1.f, v)); }

inline void onMainThread(void (^block)(void)) {
  if ([NSThread isMainThread])
    block();
  else
    dispatch_async(dispatch_get_main_queue(), block);
}

// Schedules release of a player after delay (MRC equivalent of ARC
// auto-release)
inline void releaseAfterDelay(id<CHHapticPatternPlayer> player, int64_t delayMs)
    API_AVAILABLE(ios(13.0)) {
  [player retain];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayMs * NSEC_PER_MSEC),
                 dispatch_get_main_queue(), ^{
                   [player release];
                   [player release];
                 });
}

NSDictionary *loadAHAPFile(const std::string &filename) {
  NSString *name = [NSString stringWithUTF8String:filename.c_str()];
  NSURL *url =
      [[NSBundle mainBundle] URLForResource:name.stringByDeletingPathExtension
                              withExtension:name.pathExtension];
  if (!url) {
    url = [[NSBundle mainBundle]
        URLForResource:[@"haptics/" stringByAppendingString:
                                        name.stringByDeletingPathExtension]
         withExtension:name.pathExtension];
  }
  if (!url)
    return nil;

  NSError *err = nil;
  NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&err];
  if (err || !data)
    return nil;

  return [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
}

} // anonymous namespace

// =============================================================================
#pragma mark - Haptics::Impl
// =============================================================================

class Haptics::Impl {
  void *_lightGen = nullptr;
  void *_mediumGen = nullptr;
  void *_heavyGen = nullptr;
  void *_selectionGen = nullptr;
  void *_engine = nullptr;

  CHHapticEngine *engine() API_AVAILABLE(ios(13.0)) {
    return (__bridge CHHapticEngine *)_engine;
  }

public:
  Impl() {
    if (@available(iOS 10.0, *)) {
      _lightGen = (__bridge_retained void *)[[UIImpactFeedbackGenerator alloc]
          initWithStyle:UIImpactFeedbackStyleLight];
      _mediumGen = (__bridge_retained void *)[[UIImpactFeedbackGenerator alloc]
          initWithStyle:UIImpactFeedbackStyleMedium];
      _heavyGen = (__bridge_retained void *)[[UIImpactFeedbackGenerator alloc]
          initWithStyle:UIImpactFeedbackStyleHeavy];
      _selectionGen =
          (__bridge_retained void *)[[UISelectionFeedbackGenerator alloc] init];
    }
    if (@available(iOS 13.0, *)) {
      NSError *err = nil;
      CHHapticEngine *eng = [[CHHapticEngine alloc] initAndReturnError:&err];
      if (!err && eng) {
        _engine = (__bridge_retained void *)eng;
        __unsafe_unretained CHHapticEngine *weakEng = eng;
        eng.resetHandler = ^{
          [weakEng startAndReturnError:nil];
        };
        [eng startAndReturnError:nil];
      }
    }
  }

  ~Impl() {
    if (_lightGen)
      CFRelease(_lightGen);
    if (_mediumGen)
      CFRelease(_mediumGen);
    if (_heavyGen)
      CFRelease(_heavyGen);
    if (_selectionGen)
      CFRelease(_selectionGen);
    if (_engine) {
      if (@available(iOS 13.0, *))
        [engine() stopWithCompletionHandler:nil];
      CFRelease(_engine);
    }
  }

  bool isSupported() {
    if (@available(iOS 10.0, *))
      return true;
    return false;
  }

  void *getSharedEngine() { return _engine; }

  // ---------------------------------------------------------------------------
  // Preset feedback (iOS 10+)
  // ---------------------------------------------------------------------------

  void light() {
    if (!_lightGen)
      return;
    auto *gen = (__bridge UIImpactFeedbackGenerator *)_lightGen;
    onMainThread(^{
      [gen prepare];
      [gen impactOccurred];
    });
  }

  void medium() {
    if (!_mediumGen)
      return;
    auto *gen = (__bridge UIImpactFeedbackGenerator *)_mediumGen;
    onMainThread(^{
      [gen prepare];
      [gen impactOccurred];
    });
  }

  void heavy() {
    if (!_heavyGen)
      return;
    auto *gen = (__bridge UIImpactFeedbackGenerator *)_heavyGen;
    onMainThread(^{
      [gen prepare];
      [gen impactOccurred];
    });
  }

  void selection() {
    if (!_selectionGen)
      return;
    auto *gen = (__bridge UISelectionFeedbackGenerator *)_selectionGen;
    onMainThread(^{
      [gen prepare];
      [gen selectionChanged];
    });
  }

  // ---------------------------------------------------------------------------
  // Variable intensity tap (iOS 13+, falls back to presets)
  // Uses UIImpactFeedbackGenerator - fastest, but sharpness is approximated
  // ---------------------------------------------------------------------------

  void tap(float intensity, float sharpness) {
    intensity = clamp01(intensity);
    sharpness = clamp01(sharpness);

    void *gen = sharpness > 0.66f
                    ? _lightGen
                    : (sharpness > 0.33f ? _mediumGen : _heavyGen);
    if (!gen)
      return;

    if (@available(iOS 13.0, *)) {
      auto *g = (__bridge UIImpactFeedbackGenerator *)gen;
      onMainThread(^{
        [g prepare];
        [g impactOccurredWithIntensity:intensity];
      });
    } else if (@available(iOS 10.0, *)) {
      if (intensity > 0.66f)
        heavy();
      else if (intensity > 0.33f)
        medium();
      else
        light();
    }
  }

  // ---------------------------------------------------------------------------
  // Full CoreHaptics transient (iOS 13+)
  // True continuous control of intensity AND sharpness
  // ---------------------------------------------------------------------------

  void transient(float intensity, float sharpness) {
    if (@available(iOS 13.0, *)) {
      if (!_engine)
        return;
      intensity = clamp01(intensity);
      sharpness = clamp01(sharpness);

      CHHapticEngine *eng = engine();
      onMainThread(^{
        NSError *err = nil;
        [eng startAndReturnError:&err];
        if (err)
          return;

        CHHapticEventParameter *iParam = [[CHHapticEventParameter alloc]
            initWithParameterID:CHHapticEventParameterIDHapticIntensity
                          value:intensity];
        CHHapticEventParameter *sParam = [[CHHapticEventParameter alloc]
            initWithParameterID:CHHapticEventParameterIDHapticSharpness
                          value:sharpness];
        CHHapticEvent *event = [[CHHapticEvent alloc]
            initWithEventType:CHHapticEventTypeHapticTransient
                   parameters:@[ iParam, sParam ]
                 relativeTime:0];
        [iParam release];
        [sParam release];

        CHHapticPattern *pattern =
            [[CHHapticPattern alloc] initWithEvents:@[ event ]
                                         parameters:@[]
                                              error:&err];
        [event release];
        if (err || !pattern)
          return;

        id<CHHapticPatternPlayer> player = [eng createPlayerWithPattern:pattern
                                                                  error:&err];
        [pattern release];
        if (err || !player)
          return;

        [player startAtTime:0 error:nil];
        releaseAfterDelay(player, 100);
      });
    } else {
      tap(intensity, sharpness);
    }
  }

  // ---------------------------------------------------------------------------
  // Continuous buzz (iOS 13+)
  // ---------------------------------------------------------------------------

  void buzz(float intensity, float sharpness, float duration) {
    if (@available(iOS 13.0, *)) {
      if (!_engine)
        return;
      intensity = clamp01(intensity);
      sharpness = clamp01(sharpness);
      duration = std::max(0.f, duration);

      CHHapticEngine *eng = engine();
      int64_t delayMs = (int64_t)(duration * 1000) + 100;

      onMainThread(^{
        NSError *err = nil;
        [eng startAndReturnError:&err];
        if (err)
          return;

        CHHapticEventParameter *iParam = [[CHHapticEventParameter alloc]
            initWithParameterID:CHHapticEventParameterIDHapticIntensity
                          value:intensity];
        CHHapticEventParameter *sParam = [[CHHapticEventParameter alloc]
            initWithParameterID:CHHapticEventParameterIDHapticSharpness
                          value:sharpness];
        CHHapticEvent *event = [[CHHapticEvent alloc]
            initWithEventType:CHHapticEventTypeHapticContinuous
                   parameters:@[ iParam, sParam ]
                 relativeTime:0
                     duration:duration];
        [iParam release];
        [sParam release];

        CHHapticPattern *pattern =
            [[CHHapticPattern alloc] initWithEvents:@[ event ]
                                         parameters:@[]
                                              error:&err];
        [event release];
        if (err || !pattern)
          return;

        id<CHHapticPatternPlayer> player = [eng createPlayerWithPattern:pattern
                                                                  error:&err];
        [pattern release];
        if (err || !player)
          return;

        [player startAtTime:0 error:nil];
        releaseAfterDelay(player, delayMs);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // AHAP pattern playback (iOS 13+)
  // ---------------------------------------------------------------------------

  bool play(const std::string &filename) {
    if (@available(iOS 13.0, *)) {
      if (!_engine)
        return false;

      NSDictionary *dict = loadAHAPFile(filename);
      if (!dict)
        return false;

      CHHapticEngine *eng = engine();
      onMainThread(^{
        NSError *err = nil;
        [eng startAndReturnError:&err];
        if (err)
          return;

        CHHapticPattern *pattern =
            [[CHHapticPattern alloc] initWithDictionary:dict error:&err];
        if (err || !pattern)
          return;

        id<CHHapticPatternPlayer> player = [eng createPlayerWithPattern:pattern
                                                                  error:&err];
        [pattern release];
        if (err || !player)
          return;

        [player startAtTime:0 error:nil];
        releaseAfterDelay(player, 5000); // 5s should cover most patterns
      });
      return true;
    }
    return false;
  }
};

// =============================================================================
#pragma mark - Haptics Public API
// =============================================================================

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
  return _initialized && _impl && _impl->isSupported();
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
void Haptics::tap(float i, float s) {
  if (_initialized && _impl)
    _impl->tap(i, s);
}
void Haptics::transient(float i, float s) {
  if (_initialized && _impl)
    _impl->transient(i, s);
}
void Haptics::buzz(float i, float s, float d) {
  if (_initialized && _impl)
    _impl->buzz(i, s, d);
}
bool Haptics::play(const std::string &f) {
  return _initialized && _impl && _impl->play(f);
}

// =============================================================================
#pragma mark - HapticPlayer::Impl
// =============================================================================

class HapticPlayer::Impl {
  CHHapticEngine *_engine API_AVAILABLE(ios(13.0)) = nil;
  id<CHHapticAdvancedPatternPlayer> _player API_AVAILABLE(ios(13.0)) = nil;
  CHHapticPattern *_pattern API_AVAILABLE(ios(13.0)) = nil;
  bool _isPlaying = false;
  bool _looping = false;

  CHHapticEngine *getSharedEngine() API_AVAILABLE(ios(13.0)) {
    if (!Haptics::_initialized || !Haptics::_impl)
      return nil;
    void *ptr = Haptics::_impl->getSharedEngine();
    return ptr ? (__bridge CHHapticEngine *)ptr : nil;
  }

  void releasePlayerResources() API_AVAILABLE(ios(13.0)) {
    if (_player) {
      [_player release];
      _player = nil;
    }
    if (_pattern) {
      [_pattern release];
      _pattern = nil;
    }
  }

  bool setupPlayer() API_AVAILABLE(ios(13.0)) {
    if (!_engine || !_pattern)
      return false;

    NSError *err = nil;
    _player = [_engine createAdvancedPlayerWithPattern:_pattern error:&err];
    if (err || !_player) {
      [_pattern release];
      _pattern = nil;
      return false;
    }
    _player.loopEnabled = _looping;

    Impl *self = this;
    _player.completionHandler = ^(NSError *) {
      self->_isPlaying = false;
    };
    return true;
  }

public:
  Impl() {
    if (@available(iOS 13.0, *)) {
      _engine = getSharedEngine();
    }
  }

  ~Impl() {
    stop();
    if (@available(iOS 13.0, *))
      releasePlayerResources();
  }

  void start(float intensity, float sharpness) {
    if (@available(iOS 13.0, *)) {
      if (!_engine)
        _engine = getSharedEngine();
      if (!_engine)
        return;

      stop();
      releasePlayerResources();

      intensity = clamp01(intensity);
      sharpness = clamp01(sharpness);

      CHHapticEventParameter *iParam = [[CHHapticEventParameter alloc]
          initWithParameterID:CHHapticEventParameterIDHapticIntensity
                        value:intensity];
      CHHapticEventParameter *sParam = [[CHHapticEventParameter alloc]
          initWithParameterID:CHHapticEventParameterIDHapticSharpness
                        value:sharpness];
      CHHapticEvent *event = [[CHHapticEvent alloc]
          initWithEventType:CHHapticEventTypeHapticContinuous
                 parameters:@[ iParam, sParam ]
               relativeTime:0
                   duration:30.0];
      [iParam release];
      [sParam release];

      NSError *err = nil;
      _pattern = [[CHHapticPattern alloc] initWithEvents:@[ event ]
                                              parameters:@[]
                                                   error:&err];
      [event release];
      if (err || !_pattern)
        return;

      _looping = true;
      if (!setupPlayer())
        return;
      _player.loopEnabled = YES;
      play();
    }
  }

  bool load(const std::string &filename) {
    if (@available(iOS 13.0, *)) {
      if (!_engine)
        _engine = getSharedEngine();
      if (!_engine)
        return false;

      stop();
      releasePlayerResources();

      NSDictionary *dict = loadAHAPFile(filename);
      if (!dict)
        return false;

      NSError *err = nil;
      _pattern = [[CHHapticPattern alloc] initWithDictionary:dict error:&err];
      if (err || !_pattern)
        return false;

      return setupPlayer();
    }
    return false;
  }

  void play() {
    if (@available(iOS 13.0, *)) {
      if (!_player || !_engine)
        return;
      NSError *err = nil;
      [_engine startAndReturnError:&err];
      if (!err) {
        [_player startAtTime:CHHapticTimeImmediate error:&err];
        if (!err)
          _isPlaying = true;
      }
    }
  }

  void pause() {
    if (@available(iOS 13.0, *)) {
      if (_player && _isPlaying) {
        [_player pauseAtTime:CHHapticTimeImmediate error:nil];
        _isPlaying = false;
      }
    }
  }

  void stop() {
    if (@available(iOS 13.0, *)) {
      if (_player) {
        [_player stopAtTime:CHHapticTimeImmediate error:nil];
        _isPlaying = false;
      }
    }
  }

  bool isPlaying() const { return _isPlaying; }

  void setLooping(bool loop) {
    _looping = loop;
    if (@available(iOS 13.0, *)) {
      if (_player)
        _player.loopEnabled = loop;
    }
  }

  void setIntensity(float intensity) {
    if (@available(iOS 13.0, *)) {
      if (!_player)
        return;
      CHHapticDynamicParameter *p = [[CHHapticDynamicParameter alloc]
          initWithParameterID:CHHapticDynamicParameterIDHapticIntensityControl
                        value:clamp01(intensity)
                 relativeTime:0];
      [_player sendParameters:@[ p ] atTime:CHHapticTimeImmediate error:nil];
      [p release];
    }
  }

  void setSharpness(float sharpness) {
    if (@available(iOS 13.0, *)) {
      if (!_player)
        return;
      CHHapticDynamicParameter *p = [[CHHapticDynamicParameter alloc]
          initWithParameterID:CHHapticDynamicParameterIDHapticSharpnessControl
                        value:clamp01(sharpness)
                 relativeTime:0];
      [_player sendParameters:@[ p ] atTime:CHHapticTimeImmediate error:nil];
      [p release];
    }
  }
};

// =============================================================================
#pragma mark - HapticPlayer Public API
// =============================================================================

HapticPlayer::HapticPlayer()
    : _impl(std::make_unique<Impl>()), _intensity(1.f), _sharpness(0.5f),
      _looping(false) {}

HapticPlayer::~HapticPlayer() = default;

HapticPlayer::HapticPlayer(HapticPlayer &&o) noexcept
    : _impl(std::move(o._impl)), _intensity(o._intensity),
      _sharpness(o._sharpness), _looping(o._looping) {}

HapticPlayer &HapticPlayer::operator=(HapticPlayer &&o) noexcept {
  if (this != &o) {
    _impl = std::move(o._impl);
    _intensity = o._intensity;
    _sharpness = o._sharpness;
    _looping = o._looping;
  }
  return *this;
}

void HapticPlayer::start(float i, float s) {
  _intensity = clamp01(i);
  _sharpness = clamp01(s);
  if (_impl)
    _impl->start(_intensity, _sharpness);
}

bool HapticPlayer::load(const std::string &f) {
  if (!_impl)
    return false;
  _impl->setLooping(_looping);
  return _impl->load(f);
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
bool HapticPlayer::isPlaying() const { return _impl && _impl->isPlaying(); }
void HapticPlayer::setLooping(bool l) {
  _looping = l;
  if (_impl)
    _impl->setLooping(l);
}
void HapticPlayer::setIntensity(float i) {
  _intensity = clamp01(i);
  if (_impl)
    _impl->setIntensity(_intensity);
}
void HapticPlayer::setSharpness(float s) {
  _sharpness = clamp01(s);
  if (_impl)
    _impl->setSharpness(_sharpness);
}

#endif // TARGET_OS_IPHONE
