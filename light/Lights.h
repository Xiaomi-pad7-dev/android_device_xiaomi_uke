//
// Copyright (C) 2023-2026 The LineageOS Project
//
// SPDX-License-Identifier: Apache-2.0
//

#pragma once

#include <aidl/android/hardware/light/BnLights.h>
#include <mutex>
#include <vector>

using ::aidl::android::hardware::light::BnLights;
using ::aidl::android::hardware::light::FlashMode;
using ::aidl::android::hardware::light::HwLight;
using ::aidl::android::hardware::light::HwLightState;
using ::aidl::android::hardware::light::LightType;

namespace aidl {
namespace android {
namespace hardware {
namespace light {

class Lights : public BnLights {
  public:
    ndk::ScopedAStatus setLightState(int id, const HwLightState& state) override;
    ndk::ScopedAStatus getLights(std::vector<HwLight>* types) override;

  private:
    void updateLed();

    std::mutex mLock;
    HwLightState mNotification{};
    HwLightState mAttention{};
    HwLightState mBattery{};
};

}  // namespace light
}  // namespace hardware
}  // namespace android
}  // namespace aidl
