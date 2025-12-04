//
//  CUHapticsApple.mm
//  Cornell University Game Library (CUGL)
//
//  This module provides the iOS implementation of the HapticFeedback class.
//
//  Author: Luke Leh (ll594)
//  Version: 1.1, 5/13/25
//

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
bool HapticFeedback::triggerCustom(const std::string &) { return false; }
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
                (__bridge_retained void *)[[UISelectionFeedbackGenerator alloc]
                    init];

            // Custom pattern generator (iOS 13+)
            if (@available(iOS 13.0, *)) {
                _customGenerator = (__bridge_retained void *)
                    [[UINotificationFeedbackGenerator alloc] init];
            } else {
                _customGenerator = nullptr;
            }
        } else {
            _lightGenerator = nullptr;
            _mediumGenerator = nullptr;
            _heavyGenerator = nullptr;
            _selectionGenerator = nullptr;
            _customGenerator = nullptr;
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
    }

    bool isSupported() {
        if (@available(iOS 10.0, *)) {
            return YES;
        }
        return NO;
    }

    void triggerLight() {
        if (_lightGenerator == nullptr)
            return;

        UIImpactFeedbackGenerator *generator =
            (__bridge UIImpactFeedbackGenerator *)_lightGenerator;

        // Always dispatch to main thread for UIKit operations
        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [generator prepare];
              [generator impactOccurred];
            });
        } else {
            // Already on main thread, execute directly
            [generator prepare];
            [generator impactOccurred];
        }
    }

    void triggerMedium() {
        if (_mediumGenerator == nullptr)
            return;

        UIImpactFeedbackGenerator *generator =
            (__bridge UIImpactFeedbackGenerator *)_mediumGenerator;

        // Always dispatch to main thread for UIKit operations
        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [generator prepare];
              [generator impactOccurred];
            });
        } else {
            // Already on main thread, execute directly
            [generator prepare];
            [generator impactOccurred];
        }
    }

    void triggerHeavy() {
        if (_heavyGenerator == nullptr)
            return;

        UIImpactFeedbackGenerator *generator =
            (__bridge UIImpactFeedbackGenerator *)_heavyGenerator;

        // Always dispatch to main thread for UIKit operations
        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [generator prepare];
              [generator impactOccurred];
            });
        } else {
            // Already on main thread, execute directly
            [generator prepare];
            [generator impactOccurred];
        }
    }

    void triggerSelection() {
        if (_selectionGenerator == nullptr)
            return;

        UISelectionFeedbackGenerator *generator =
            (__bridge UISelectionFeedbackGenerator *)_selectionGenerator;

        // Always dispatch to main thread for UIKit operations
        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [generator prepare];
              [generator selectionChanged];
            });
        } else {
            // Already on main thread, execute directly
            [generator prepare];
            [generator selectionChanged];
        }
    }

    bool triggerCustom(const std::string &filename) {
        // Custom haptic patterns require iOS 13+
        if (_customGenerator == nullptr)
            return false;

        if (@available(iOS 13.0, *)) {
            // Create an NSString from the C++ string
            NSString *nsFilename =
                [NSString stringWithUTF8String:filename.c_str()];

            // Try to find the file in the main bundle
            NSURL *fileURL = [[NSBundle mainBundle]
                URLForResource:nsFilename.stringByDeletingPathExtension
                 withExtension:nsFilename.pathExtension];

            // If not found, try in the haptics folder
            if (fileURL == nil) {
                fileURL = [[NSBundle mainBundle]
                    URLForResource:[@"haptics/"
                                       stringByAppendingString:
                                           nsFilename
                                               .stringByDeletingPathExtension]
                     withExtension:nsFilename.pathExtension];
            }

            NSError *error = nil;

            // Read the AHAP file content - this can be done off main thread
            NSData *fileData = [NSData dataWithContentsOfURL:fileURL
                                                     options:0
                                                       error:&error];
            if (error != nil) {
                NSLog(@"Error loading haptic pattern file: %@",
                      error.localizedDescription);
                return false;
            }

            // Parse the AHAP JSON - this can be done off main thread
            NSDictionary *patternDict =
                [NSJSONSerialization JSONObjectWithData:fileData
                                                options:0
                                                  error:&error];
            if (error != nil) {
                NSLog(@"Error parsing haptic pattern file: %@",
                      error.localizedDescription);
                return false;
            }

            // Need to run CoreHaptics on the main thread
            __block bool success = true;

            if (![NSThread isMainThread]) {
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

                dispatch_async(dispatch_get_main_queue(), ^{
                  NSError *localError = nil;

                  // Create and play the pattern
                  CHHapticPattern *pattern =
                      [[CHHapticPattern alloc] initWithDictionary:patternDict
                                                            error:&localError];
                  if (localError != nil) {
                      NSLog(@"Error creating haptic pattern: %@",
                            localError.localizedDescription);
                      success = false;
                      dispatch_semaphore_signal(semaphore);
                      return;
                  }

                  // Get the haptic engine
                  NSError *engineError = nil;
                  CHHapticEngine *engine =
                      [[CHHapticEngine alloc] initAndReturnError:&engineError];
                  if (engineError != nil) {
                      NSLog(@"Error creating haptic engine: %@",
                            engineError.localizedDescription);
                      success = false;
                      dispatch_semaphore_signal(semaphore);
                      return;
                  }

                  // Start the engine
                  [engine startAndReturnError:&localError];
                  if (localError != nil) {
                      NSLog(@"Error starting haptic engine: %@",
                            localError.localizedDescription);
                      success = false;
                      dispatch_semaphore_signal(semaphore);
                      return;
                  }

                  // Create a player with the pattern
                  id<CHHapticPatternPlayer> player =
                      [engine createPlayerWithPattern:pattern
                                                error:&localError];
                  if (localError != nil) {
                      NSLog(@"Error creating haptic pattern player: %@",
                            localError.localizedDescription);
                      success = false;
                      dispatch_semaphore_signal(semaphore);
                      return;
                  }

                  // Start playing the pattern
                  [player startAtTime:0 error:&localError];
                  if (localError != nil) {
                      NSLog(@"Error playing haptic pattern: %@",
                            localError.localizedDescription);
                      success = false;
                  }

                  dispatch_semaphore_signal(semaphore);
                });

                // Wait for completion but with a timeout to prevent blocking
                // indefinitely
                dispatch_time_t timeout =
                    dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
                dispatch_semaphore_wait(semaphore, timeout);
            } else {
                // Already on main thread
                NSError *localError = nil;

                // Create and play the pattern
                CHHapticPattern *pattern =
                    [[CHHapticPattern alloc] initWithDictionary:patternDict
                                                          error:&localError];
                if (localError != nil) {
                    NSLog(@"Error creating haptic pattern: %@",
                          localError.localizedDescription);
                    return false;
                }

                // Get the haptic engine
                NSError *engineError = nil;
                CHHapticEngine *engine =
                    [[CHHapticEngine alloc] initAndReturnError:&engineError];
                if (engineError != nil) {
                    NSLog(@"Error creating haptic engine: %@",
                          engineError.localizedDescription);
                    return false;
                }

                // Start the engine
                [engine startAndReturnError:&localError];
                if (localError != nil) {
                    NSLog(@"Error starting haptic engine: %@",
                          localError.localizedDescription);
                    return false;
                }

                // Create a player with the pattern
                id<CHHapticPatternPlayer> player =
                    [engine createPlayerWithPattern:pattern error:&localError];
                if (localError != nil) {
                    NSLog(@"Error creating haptic pattern player: %@",
                          localError.localizedDescription);
                    return false;
                }

                // Start playing the pattern
                [player startAtTime:0 error:&localError];
                if (localError != nil) {
                    NSLog(@"Error playing haptic pattern: %@",
                          localError.localizedDescription);
                    return false;
                }
            }

            return success;
        }

        // Fallback for iOS < 13: Use a notification feedback as a simpler
        // alternative
        UINotificationFeedbackGenerator *generator =
            (__bridge UINotificationFeedbackGenerator *)_customGenerator;

        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [generator prepare];
              [generator
                  notificationOccurred:UINotificationFeedbackTypeSuccess];
            });
        } else {
            [generator prepare];
            [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
        }

        return true;
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
