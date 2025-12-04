//
//  CUHaptics.h
//
//  This class provides cross-platform haptic feedback support.
//
//  Author: Luke Leh (ll594)
//  Version: 1.1, 5/13/25
//

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
    /** Private implementation class (PIMPL idiom) */
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
    static bool triggerCustom(const std::string& filename);
    
    /** Cleans up haptic feedback resources. */
    static void dispose();
};

}

#endif /* __CU_HAPTICS_H__ */
