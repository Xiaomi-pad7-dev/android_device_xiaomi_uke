#
# Copyright (C) 2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_tablet_wifionly.mk)

# Inherit from uke device
$(call inherit-product, device/xiaomi/uke/device.mk)

PRODUCT_NAME := lineage_uke
PRODUCT_DEVICE := uke
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := 2410CRP4CG

PRODUCT_SYSTEM_NAME := uke_global
PRODUCT_SYSTEM_DEVICE := uke

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="uke_global-user 16 BP2A.250605.031.A3 OS3.0.303.0.WOZMIXM release-keys" \
    BuildFingerprint=Xiaomi/uke_global/uke:16/BP2A.250605.031.A3/OS3.0.303.0.WOZMIXM:user/release-keys \
    DeviceName=$(PRODUCT_SYSTEM_DEVICE) \
    DeviceProduct=$(PRODUCT_SYSTEM_NAME)

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi
