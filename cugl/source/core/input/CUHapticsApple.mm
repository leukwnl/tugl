//
//  CUHapticsApple.mm
//  TUGL, built for Cornell University Game Library (CUGL)
//
//  This module provides the iOS implementation of the HapticFeedback class.
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

#include "cugl/core/input/CUHaptics.h"
#include <TargetConditionals.h>

using namespace cugl;

// Static member initialization for all platforms
std::shared_ptr<HapticFeedback::HapticImpl> HapticFeedback::_impl = nullptr;
bool HapticFeedback::_initialized = false;

#if !TARGET_OS_IPHONE
// Empty implementation for non-iOS platforms
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

// Implementation of the public API methods for non-iOS platforms
bool HapticFeedback::init() {
  if (_initialized)
    return true;
  _impl = std::make_shared<HapticImpl>();
  _initialized = true;
  return true;
}

bool HapticFeedback::isSupported() { return false; }
void HapticFeedback::triggerLight() {}
void HapticFeedback::triggerMedium() {}
void HapticFeedback::triggerHeavy() {}
void HapticFeedback::triggerSelection() {}
bool HapticFeedback::triggerCustom(const std::string &filename) {
  return false;
}
void HapticFeedback::dispose() {
  _impl = nullptr;
  _initialized = false;
}

#else

// iOS specific implementation
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
#import <CoreHaptics/CoreHaptics.h>
#endif

// Implementation of HapticImpl class for iOS
class HapticFeedback::HapticImpl {
private:
  void *_lightGenerator;
  void *_mediumGenerator;
  void *_heavyGenerator;
  void *_selectionGenerator;
  void *_customGenerator;
  void *_hapticEngine; // CoreHaptics engine for custom patterns (iOS 13+)

  // Helper method to reduce code duplication for trigger methods
  template <typename GeneratorType>
  void triggerFeedback(void *generator, void (^action)(GeneratorType *)) {
    if (generator == nullptr)
      return;

    GeneratorType *gen = (__bridge GeneratorType *)generator;

    // Always dispatch to main thread for UIKit operations
    if (![NSThread isMainThread]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [gen prepare];
        action(gen);
      });
    } else {
      // Already on main thread, execute directly
      [gen prepare];
      action(gen);
    }
  }

public:
  HapticImpl() {
    // Check for haptics support before creating generators
    if (@available(iOS 10.0, *)) {
      _lightGenerator =
          (__bridge_retained void *)[[UIImpactFeedbackGenerator alloc]
              initWithStyle:UIImpactFeedbackStyleLight];
      _mediumGenerator =
          (__bridge_retained void *)[[UIImpactFeedbackGenerator alloc]
              initWithStyle:UIImpactFeedbackStyleMedium];
      _heavyGenerator =
          (__bridge_retained void *)[[UIImpactFeedbackGenerator alloc]
              initWithStyle:UIImpactFeedbackStyleHeavy];
      _selectionGenerator =
          (__bridge_retained void *)[[UISelectionFeedbackGenerator alloc] init];

      // Custom pattern generator (iOS 13+)
      if (@available(iOS 13.0, *)) {
        _customGenerator =
            (__bridge_retained void *)[[UINotificationFeedbackGenerator alloc]
                init];

        // Initialize CoreHaptics engine for custom patterns
        NSError *error = nil;
        CHHapticEngine *engine =
            [[CHHapticEngine alloc] initAndReturnError:&error];
        if (error == nil && engine != nil) {
          _hapticEngine = (__bridge_retained void *)engine;

          // Start the engine (it auto-stops when idle to save power)
          [engine startAndReturnError:&error];
          if (error != nil) {
            NSLog(@"Warning: Could not start haptic engine: %@",
                  error.localizedDescription);
          }
        } else {
          _hapticEngine = nullptr;
          NSLog(@"Warning: Could not create haptic engine: %@",
                error.localizedDescription);
        }
      } else {
        _customGenerator = nullptr;
        _hapticEngine = nullptr;
      }
    } else {
      _lightGenerator = nullptr;
      _mediumGenerator = nullptr;
      _heavyGenerator = nullptr;
      _selectionGenerator = nullptr;
      _customGenerator = nullptr;
      _hapticEngine = nullptr;
    }
  }

  ~HapticImpl() {
    // Release all the generators using ARC bridge
    if (_lightGenerator != nullptr) {
      CFRelease(_lightGenerator);
      _lightGenerator = nullptr;
    }

    if (_mediumGenerator != nullptr) {
      CFRelease(_mediumGenerator);
      _mediumGenerator = nullptr;
    }

    if (_heavyGenerator != nullptr) {
      CFRelease(_heavyGenerator);
      _heavyGenerator = nullptr;
    }

    if (_selectionGenerator != nullptr) {
      CFRelease(_selectionGenerator);
      _selectionGenerator = nullptr;
    }

    if (_customGenerator != nullptr) {
      CFRelease(_customGenerator);
      _customGenerator = nullptr;
    }

    if (_hapticEngine != nullptr) {
      // Stop the engine before releasing
      CHHapticEngine *engine = (__bridge CHHapticEngine *)_hapticEngine;
      NSError *error = nil;
      [engine stopWithCompletionHandler:^(NSError *_Nullable stopError) {
        if (stopError != nil) {
          NSLog(@"Error stopping haptic engine: %@",
                stopError.localizedDescription);
        }
      }];

      CFRelease(_hapticEngine);
      _hapticEngine = nullptr;
    }
  }

  bool isSupported() {
    if (@available(iOS 10.0, *)) {
      return YES;
    }
    return NO;
  }

  void triggerLight() {
    triggerFeedback<UIImpactFeedbackGenerator>(
        _lightGenerator, ^(UIImpactFeedbackGenerator *gen) {
          [gen impactOccurred];
        });
  }

  void triggerMedium() {
    triggerFeedback<UIImpactFeedbackGenerator>(
        _mediumGenerator, ^(UIImpactFeedbackGenerator *gen) {
          [gen impactOccurred];
        });
  }

  void triggerHeavy() {
    triggerFeedback<UIImpactFeedbackGenerator>(
        _heavyGenerator, ^(UIImpactFeedbackGenerator *gen) {
          [gen impactOccurred];
        });
  }

  void triggerSelection() {
    triggerFeedback<UISelectionFeedbackGenerator>(
        _selectionGenerator, ^(UISelectionFeedbackGenerator *gen) {
          [gen selectionChanged];
        });
  }

  bool triggerCustom(const std::string &filename) {
    // Custom haptic patterns require iOS 13+ with CoreHaptics
    if (@available(iOS 13.0, *)) {
      if (_hapticEngine == nullptr) {
        // Fallback to notification feedback if engine unavailable
        triggerFeedback<UINotificationFeedbackGenerator>(
            _customGenerator, ^(UINotificationFeedbackGenerator *gen) {
              [gen notificationOccurred:UINotificationFeedbackTypeSuccess];
            });
        return true;
      }

      // Create an NSString from the C++ string
      NSString *nsFilename = [NSString stringWithUTF8String:filename.c_str()];

      // Try to find the file in the main bundle
      NSURL *fileURL = [[NSBundle mainBundle]
          URLForResource:nsFilename.stringByDeletingPathExtension
           withExtension:nsFilename.pathExtension];

      // If not found, try in the haptics folder
      if (fileURL == nil) {
        fileURL = [[NSBundle mainBundle]
            URLForResource:[@"haptics/"
                               stringByAppendingString:
                                   nsFilename.stringByDeletingPathExtension]
             withExtension:nsFilename.pathExtension];
      }

      if (fileURL == nil) {
        NSLog(@"Error: Could not find haptic pattern file: %@", nsFilename);
        return false;
      }

      NSError *error = nil;

      // Read the AHAP file content - this can be done off main thread
      NSData *fileData = [NSData dataWithContentsOfURL:fileURL
                                               options:0
                                                 error:&error];
      if (error != nil || fileData == nil) {
        NSLog(@"Error loading haptic pattern file: %@",
              error.localizedDescription);
        return false;
      }

      // Parse the AHAP JSON - this can be done off main thread
      NSDictionary *patternDict =
          [NSJSONSerialization JSONObjectWithData:fileData
                                          options:0
                                            error:&error];
      if (error != nil || patternDict == nil) {
        NSLog(@"Error parsing haptic pattern file: %@",
              error.localizedDescription);
        return false;
      }

      // Get our reusable engine
      CHHapticEngine *engine = (__bridge CHHapticEngine *)_hapticEngine;

      // Dispatch to main thread for UIKit/CoreHaptics operations
      if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          playCustomPattern(patternDict, engine);
        });
      } else {
        playCustomPattern(patternDict, engine);
      }

      // Return true immediately - haptic plays asynchronously
      // This is the correct behavior: haptics should not block
      return true;
    }

    // Fallback for iOS < 13: Use a notification feedback as a simpler
    // alternative
    if (_customGenerator != nullptr) {
      triggerFeedback<UINotificationFeedbackGenerator>(
          _customGenerator, ^(UINotificationFeedbackGenerator *gen) {
            [gen notificationOccurred:UINotificationFeedbackTypeSuccess];
          });
      return true;
    }

    return false;
  }

  // Helper method to play custom patterns (must be called on main thread)
  void playCustomPattern(NSDictionary *patternDict, CHHapticEngine *engine) {
    NSError *error = nil;

    // Ensure engine is running (it auto-stops when idle to save power)
    // startAndReturnError is safe to call even if already running
    [engine startAndReturnError:&error];
    if (error != nil) {
      NSLog(@"Error starting haptic engine: %@", error.localizedDescription);
      return;
    }

    // Create the pattern
    CHHapticPattern *pattern =
        [[CHHapticPattern alloc] initWithDictionary:patternDict error:&error];
    if (error != nil || pattern == nil) {
      NSLog(@"Error creating haptic pattern: %@", error.localizedDescription);
      return;
    }

    // Create a player with the pattern
    id<CHHapticPatternPlayer> player = [engine createPlayerWithPattern:pattern
                                                                 error:&error];
    if (error != nil || player == nil) {
      NSLog(@"Error creating haptic pattern player: %@",
            error.localizedDescription);
      return;
    }

    // Start playing the pattern
    [player startAtTime:0 error:&error];
    if (error != nil) {
      NSLog(@"Error playing haptic pattern: %@", error.localizedDescription);
      return;
    }

    // Note: The player and pattern will be retained by the engine during
    // playback and automatically released when done. No manual cleanup needed.
  }
};

// Implementation of the public API methods for iOS
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
  if (!_initialized || !isSupported())
    return;
  _impl->triggerLight();
}

void HapticFeedback::triggerMedium() {
  if (!_initialized || !isSupported())
    return;
  _impl->triggerMedium();
}

void HapticFeedback::triggerHeavy() {
  if (!_initialized || !isSupported())
    return;
  _impl->triggerHeavy();
}

void HapticFeedback::triggerSelection() {
  if (!_initialized || !isSupported())
    return;
  _impl->triggerSelection();
}

bool HapticFeedback::triggerCustom(const std::string &filename) {
  if (!_initialized || !isSupported())
    return false;
  return _impl->triggerCustom(filename);
}

void HapticFeedback::dispose() {
  _impl = nullptr;
  _initialized = false;
}

#endif // TARGET_OS_IPHONE
