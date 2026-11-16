//
// Copyright (C) 2023-2026 The LineageOS Project
//
// SPDX-License-Identifier: Apache-2.0
//

#include "Lights.h"

#include <android-base/file.h>
#include <android-base/logging.h>

#include <array>
#include <string>

namespace {

const std::string kLedPath = "/sys/class/leds/";
const std::string kBreathNode = "/breath";
const std::string kBrightnessNode = "/brightness";

// Order matches the 0x00RRGGBB layout of HwLightState::color.
const std::array<std::string, 3> kLeds = {"red", "green", "blue"};

const std::vector<LightType> kSupportedLights = {
        LightType::NOTIFICATIONS,
        LightType::ATTENTION,
        LightType::BATTERY,
};

void writeNode(const std::string& path, uint32_t value) {
    if (!android::base::WriteStringToFile(std::to_string(value), path)) {
        PLOG(WARNING) << "Failed to write " << value << " to " << path;
    }
}

bool isLit(const HwLightState& state) {
    return (state.color & 0x00ffffff) != 0;
}

bool isBlinking(const HwLightState& state) {
    return state.flashMode != FlashMode::NONE && state.flashOnMs > 0 && state.flashOffMs > 0;
}

}  // anonymous namespace

namespace aidl {
namespace android {
namespace hardware {
namespace light {

void Lights::updateLed() {
    // Notifications win over attention, which wins over the battery state.
    const HwLightState& state =
            isLit(mNotification) ? mNotification : isLit(mAttention) ? mAttention : mBattery;

    uint32_t alpha = (state.color >> 24) & 0xff;
    if (alpha == 0) {
        alpha = 0xff;
    }

    const bool blink = isBlinking(state);

    for (size_t i = 0; i < kLeds.size(); i++) {
        const std::string led = kLedPath + kLeds[i];
        const uint32_t level = ((state.color >> (16 - 8 * i)) & 0xff) * alpha / 0xff;

        // The PMIC only offers a fixed breathing pattern for blinking. Always
        // leave it first so a new brightness or pattern starts from a known state.
        writeNode(led + kBreathNode, 0);

        if (blink && level != 0) {
            writeNode(led + kBreathNode, 1);
        } else {
            writeNode(led + kBrightnessNode, level);
        }
    }
}

ndk::ScopedAStatus Lights::setLightState(int id, const HwLightState& state) {
    std::lock_guard<std::mutex> lock(mLock);

    switch (static_cast<LightType>(id)) {
        case LightType::NOTIFICATIONS:
            mNotification = state;
            break;
        case LightType::ATTENTION:
            mAttention = state;
            break;
        case LightType::BATTERY:
            mBattery = state;
            break;
        default:
            return ndk::ScopedAStatus::fromExceptionCode(EX_UNSUPPORTED_OPERATION);
    }

    updateLed();

    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus Lights::getLights(std::vector<HwLight>* lights) {
    int ordinal = 0;

    for (const LightType& type : kSupportedLights) {
        HwLight hwLight;
        hwLight.id = static_cast<int>(type);
        hwLight.type = type;
        hwLight.ordinal = ordinal++;
        lights->push_back(hwLight);
    }

    return ndk::ScopedAStatus::ok();
}

}  // namespace light
}  // namespace hardware
}  // namespace android
}  // namespace aidl
