#
# Copyright (C) 2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, vendor/lineage/config/common_full_tablet_wifionly.mk)
$(call inherit-product, device/xiaomi/uke/device.mk)

PRODUCT_NAME := lineage_uke
PRODUCT_DEVICE := uke
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := 2410CRP4CG

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="missi-user 16 BP2A.250605.031.A3 OS3.0.8.0.WOZMIXM release-keys" \
    BuildFingerprint=Xiaomi/uke_global/uke:16/BP2A.250605.031.A3/OS3.0.8.0.WOZMIXM:user/release-keys

LINEAGE_MAINTAINER := Thanick49

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

$(call soong_config_set,lineage_health,charging_control_charging_disabled,1)
$(call soong_config_set,lineage_health,charging_control_charging_enabled,0)
$(call soong_config_set,lineage_health,charging_control_charging_path,/sys/class/qcom-battery/night_charging)
$(call soong_config_set_bool,lineage_health,charging_control_supports_bypass,false)

PRODUCT_PACKAGES += \
    vendor.lineage.health-service.default \
    LineageSDKOverlayUke
