#
# Copyright (C) 2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/uke

# Generic ramdisk allow list
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)

# Project ID Quota
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Virtual A/B
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)

# Dalvik vm configs
$(call inherit-product, frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk)

# pKVM
$(call inherit-product, packages/modules/Virtualization/apex/product_packages.mk)

# Qualcomm
$(call inherit-product, hardware/qcom-caf/common/common.mk)

# A/B
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=ext4 \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script

# API
BOARD_SHIPPING_API_LEVEL := 34
PRODUCT_SHIPPING_API_LEVEL := $(BOARD_SHIPPING_API_LEVEL)

# Audio
AUDIO_HAL_DIR := hardware/qcom-caf/sm8650/audio/primary-hal

PRODUCT_PACKAGES += \
    android.hardware.audio.effect@7.0-impl \
    android.hardware.audio.service \
    android.hardware.audio@7.1-impl \
    android.hardware.soundtrigger@2.3-impl \
    android.media.audio.common.types-V4-cpp \
    audio.primary.default \
    audio.r_submix.default \
    audio.usbv2.default

PRODUCT_PACKAGES += \
    audioadsprpcd \
    lib_bt_aptx \
    lib_bt_ble \
    lib_bt_bundle \
    libagm_compress_plugin \
    libagm_mixer_plugin \
    libagm_pcm_plugin \
    libaudiochargerlistener \
    libbatterylistener \
    libcustomva_intf \
    libfmpal \
    libhfp_pal \
    libhotword_intf \
    libqcompostprocbundle \
    libqcomvisualizer \
    libqcomvoiceprocessing \
    libsndcardparser \
    libvolumelistener

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/audio/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_cliffs/audio_effects.xml \
    $(DEVICE_PATH)/configs/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_cliffs/audio_policy_configuration.xml \
    $(DEVICE_PATH)/configs/audio/usbv2_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usbv2_audio_policy_configuration.xml

# Stock tcmd.policy (Android 16) + lseek(2), which the Android 17 system
# libraries used by this prebuilt call at startup. Without it init kills tcmd
# with SIGSYS and the repeated "updatable component" crashes reboot the device.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/seccomp_policy/tcmd.policy:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/seccomp_policy/tcmd.policy

PRODUCT_COPY_FILES += \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.audio.pro.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.pro.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.sip.voip.xml

# Bluetooth
PRODUCT_PACKAGES += \
    android.hardware.bluetooth.audio-impl \
    audio.bluetooth.default

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml

# Boot control
PRODUCT_PACKAGES += \
    android.hardware.boot-service.qti \
    android.hardware.boot-service.qti.recovery

# Camera
PRODUCT_PACKAGES += \
    android.hardware.camera.device-V1-ndk.vendor \
    android.hardware.camera.metadata-V2-ndk.vendor

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.camera.concurrent.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.concurrent.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.full.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.full.xml \
    frameworks/native/data/etc/android.hardware.camera.raw.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.raw.xml

# Characteristics
PRODUCT_CHARACTERISTICS := nosdcard,tablet

# Display
PRODUCT_PACKAGES += \
    android.hardware.graphics.mapper@4.0-impl-qti-display \
    vendor.qti.hardware.display.allocator-service \
    vendor.qti.hardware.display.demura-service

PRODUCT_PACKAGES += \
    android.hardware.graphics.composer3-V2-ndk.vendor \
    vendor.qti.hardware.display.composer-service.rc \
    vendor.qti.hardware.display.composer-service.xml \
    vendor.qti.hardware.display.composer3-V1-ndk.vendor

PRODUCT_PACKAGES += \
    init.qti.display_boot.rc \
    init.qti.display_boot.sh

PRODUCT_PACKAGES += \
    libhistogram \
    libqdMetaData \
    vendor.qti.hardware.display.config-V11-ndk.vendor \
    vendor.qti.hardware.display.config-V5-ndk \
    vendor.qti.hardware.display.config-V5-ndk.vendor

# DRM
PRODUCT_PACKAGES += \
    android.hardware.drm-service.clearkey \
    libdrm.vendor

# Fastbootd
PRODUCT_PACKAGES += \
    fastbootd

# GNSS
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/gps/gps.conf:$(TARGET_COPY_OUT_VENDOR)/etc/gps.conf \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_ODM)/etc/permissions/android.hardware.location.gps.xml

# Graphics
PRODUCT_PACKAGES += \
    gralloc.default

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute-0.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level-1.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version-1_1.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_3.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version-1_3.xml \
    frameworks/native/data/etc/android.software.opengles.deqp.level-2023-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-2023-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml

# Health
PRODUCT_PACKAGES += \
    android.hardware.health-service.qti \
    android.hardware.health-service.qti_recovery

# Hypsys
PRODUCT_PACKAGES += \
    xiaomi.system.hypsys.common-service

# Init
PRODUCT_PACKAGES += \
    charger_fw_fstab.qti \
    fstab.qcom

PRODUCT_PACKAGES += \
    ueventd-odm.rc \
    ueventd.qcom.rc

PRODUCT_PACKAGES += \
    init.qcom.rc \
    init.recovery.qcom.rc \
    init.target.rc \
    init.uke.rc

PRODUCT_PACKAGES += \
    init.class_main.sh \
    init.kernel.post_boot-cliffs.sh \
    init.kernel.post_boot-cliffs_2_2_1.sh \
    init.kernel.post_boot-cliffs_2_3_0.sh \
    init.kernel.post_boot-cliffs_3_3_1.sh \
    init.kernel.post_boot-cliffs_default_3_4_1.sh \
    init.kernel.post_boot-memory.sh \
    init.kernel.post_boot.sh \
    init.qcom.early_boot.sh \
    init.qcom.post_boot.sh \
    init.qcom.sh \
    kbd_leds.sh \
    xiaomi_kbd_service.sh

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.qcom

# Input
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/idc/NVTCapacitivePenM80p-merged.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/NVTCapacitivePenM80p-merged.idc \
    $(DEVICE_PATH)/configs/idc/NVTCapacitivePenM80p.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/NVTCapacitivePenM80p.idc \
    $(DEVICE_PATH)/configs/idc/NVTCapacitivePenP81c-merged.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/NVTCapacitivePenP81c-merged.idc \
    $(DEVICE_PATH)/configs/idc/NVTCapacitivePenP81c.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/NVTCapacitivePenP81c.idc \
    $(DEVICE_PATH)/configs/idc/NVTCapacitiveTouchScreen.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/NVTCapacitiveTouchScreen.idc \
    $(DEVICE_PATH)/configs/keylayout/NVTCapacitiveTouchScreen.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/NVTCapacitiveTouchScreen.kl \
    $(DEVICE_PATH)/configs/keychars/Vendor_0022_Product_3280.kcm:$(TARGET_COPY_OUT_VENDOR)/usr/keychars/Vendor_0022_Product_3280.kcm \
    $(DEVICE_PATH)/configs/keylayout/Vendor_0022_Product_3280.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/Vendor_0022_Product_3280.kl \
    $(DEVICE_PATH)/configs/keychars/Vendor_0022_Product_3281.kcm:$(TARGET_COPY_OUT_VENDOR)/usr/keychars/Vendor_0022_Product_3281.kcm \
    $(DEVICE_PATH)/configs/keylayout/Vendor_0022_Product_3281.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/Vendor_0022_Product_3281.kl \
    $(DEVICE_PATH)/configs/keychars/Vendor_0022_Product_4d80.kcm:$(TARGET_COPY_OUT_VENDOR)/usr/keychars/Vendor_0022_Product_4d80.kcm \
    $(DEVICE_PATH)/configs/keylayout/Vendor_0022_Product_4d80.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/Vendor_0022_Product_4d80.kl \
    $(DEVICE_PATH)/configs/keychars/Vendor_0022_Product_4d81.kcm:$(TARGET_COPY_OUT_VENDOR)/usr/keychars/Vendor_0022_Product_4d81.kcm \
    $(DEVICE_PATH)/configs/keylayout/Vendor_0022_Product_4d81.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/Vendor_0022_Product_4d81.kl \
    $(DEVICE_PATH)/configs/keylayout/Vendor_0022_Product_5080.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/Vendor_0022_Product_5080.kl \
    $(DEVICE_PATH)/configs/keychars/Vendor_0022_Product_5081.kcm:$(TARGET_COPY_OUT_VENDOR)/usr/keychars/Vendor_0022_Product_5081.kcm \
    $(DEVICE_PATH)/configs/keylayout/Vendor_0022_Product_5081.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/Vendor_0022_Product_5081.kl \
    $(DEVICE_PATH)/configs/keylayout/Xiaomi_Focus_Pen_Pro.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/Xiaomi_Focus_Pen_Pro.kl

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/idc/Vendor_15d9_Product_00a3.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/Vendor_15d9_Product_00a3.idc

# IPACM
PRODUCT_PACKAGES += \
    ipacm \
    IPACM_cfg.xml \
    IPACM_Filter_cfg.xml

# IR
PRODUCT_PACKAGES += \
    android.hardware.ir-service.lineage

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.consumerir.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.consumerir.xml

# Keystore
PRODUCT_PACKAGES += \
    android.hardware.hardware_keystore.xml

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.keystore.app_attest_key.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.keystore.app_attest_key.xml \
    frameworks/native/data/etc/android.software.device_id_attestation.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_id_attestation.xml

# Lights
PRODUCT_PACKAGES += \
    android.hardware.lights-service.xiaomi

# Lineage Health
PRODUCT_PACKAGES += \
    vendor.lineage.health-service.default

$(call soong_config_set,lineage_health,charging_control_charging_disabled,1)
$(call soong_config_set,lineage_health,charging_control_charging_enabled,0)
$(call soong_config_set,lineage_health,charging_control_charging_path,/sys/class/qcom-battery/night_charging)
$(call soong_config_set_bool,lineage_health,charging_control_supports_bypass,false)

# Media
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/media/media_cliffs_v0/video_system_specs.json:$(TARGET_COPY_OUT_VENDOR)/etc/media_cliffs_v0/video_system_specs.json \
    $(DEVICE_PATH)/configs/media/media_cliffs_v1/video_system_specs.json:$(TARGET_COPY_OUT_VENDOR)/etc/media_cliffs_v1/video_system_specs.json \
    $(DEVICE_PATH)/configs/media/media_codecs_cliffs_v0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_cliffs_v0.xml \
    $(DEVICE_PATH)/configs/media/media_codecs_cliffs_v1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_cliffs_v1.xml \
    $(DEVICE_PATH)/configs/media/media_codecs_mi_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_mi_c2_audio.xml \
    $(DEVICE_PATH)/configs/media/media_codecs_performance_cliffs_v0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_performance_cliffs_v0.xml \
    $(DEVICE_PATH)/configs/media/media_codecs_performance_cliffs_v1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_performance_cliffs_v1.xml \
    $(DEVICE_PATH)/configs/media/media_profiles_cliffs_v0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_cliffs_v0.xml \
    $(DEVICE_PATH)/configs/media/media_profiles_cliffs_v1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_cliffs_v1.xml

PRODUCT_COPY_FILES += \
    $(AUDIO_HAL_DIR)/configs/common/codec2/media_codecs_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_c2_audio.xml \
    $(AUDIO_HAL_DIR)/configs/common/codec2/service/1.0/c2audio.vendor.base-arm64.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/c2audio.vendor.base-arm64.policy \
    $(AUDIO_HAL_DIR)/configs/common/codec2/service/1.0/c2audio.vendor.ext-arm64.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/c2audio.vendor.ext-arm64.policy

# Memtrack
PRODUCT_PACKAGES += \
    vendor.qti.hardware.memtrack-service

# Overlays
PRODUCT_PACKAGES += \
    BluetoothOverlayUke \
    FrameworkOverlayUke \
    LineageSDKOverlayUke \
    NcmTetheringOverlay \
    SettingsOverlayUke \
    SettingsProviderOverlayUke \
    SystemUIOverlayUke \
    WifiOverlayUke

# Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

PRODUCT_PACKAGES += \
    vendor_bt_firmware_mountpoint \
    vendor_dsp_mountpoint \
    vendor_firmware_mnt_mountpoint

# Power
PRODUCT_PACKAGES += \
    android.hardware.power-service.lineage-libperfmgr \
    libqti-perfd-client

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/power/powerhint.json:$(TARGET_COPY_OUT_VENDOR)/etc/powerhint.json

$(call soong_config_set,power_libperfmgr,mode_extension_lib,//$(DEVICE_PATH)/power:libpowermode-ext-xiaomi)

# QSPA
PRODUCT_PACKAGES += \
    vendor.qti.qspa-service

# Recovery
$(call soong_config_set_bool,recovery,target_recovery_uses_qti_drm,true)

# RenderScript
PRODUCT_PACKAGES += \
    android.hardware.renderscript@1.0-impl

# RFS
PRODUCT_PACKAGES += \
    rfs_msm_mpss_readonly_mbnconfig_symlink

# Sensors
PRODUCT_PACKAGES += \
    android.hardware.sensors-service.xiaomi-multihal \
    sensors.dynamic_sensor_hal

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_cliffs/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_cliffs/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.dynamic.head_tracker.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_cliffs/android.hardware.sensor.dynamic.head_tracker.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_cliffs/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_cliffs/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_cliffs/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_cliffs/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_cliffs/android.hardware.sensor.stepdetector.xml

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH) \
    hardware/google/interfaces \
    hardware/google/pixel/power-libperfmgr \
    hardware/lineage/interfaces/power-libperfmgr \
    hardware/qcom-caf/common/libqti-perfd-client \
    hardware/xiaomi \
    vendor/qcom/opensource/usb/etc

# Pen
PRODUCT_PACKAGES += \
    XiaomiPen

# Thermal
PRODUCT_PACKAGES += \
    android.hardware.thermal-service.qti

# Touchscreen
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/tablet_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/tablet_core_hardware.xml \
    vendor/xiaomi/uke/proprietary/odm/firmware/novatek_nt36532_o82_fw_csot.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/novatek_nt36532_o82_fw_csot.bin \
    vendor/xiaomi/uke/proprietary/odm/firmware/novatek_nt36532_o82_fw_tm.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/novatek_nt36532_o82_fw_tm.bin \
    vendor/xiaomi/uke/proprietary/odm/firmware/novatek_nt36532_o82_mp_csot.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/novatek_nt36532_o82_mp_csot.bin \
    vendor/xiaomi/uke/proprietary/odm/firmware/novatek_nt36532_o82_mp_tm.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/novatek_nt36532_o82_mp_tm.bin

# Update engine
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

# USB
PRODUCT_PACKAGES += \
    android.hardware.usb-service.qti \
    android.hardware.usb.gadget-service.qti \
    usb_compositions.conf

PRODUCT_PACKAGES += \
    init.qcom.usb.rc \
    init.qcom.usb.sh

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml

# Vendor libraries
PRODUCT_PACKAGES += \
    android.hidl.base@1.0 \
    libdisplayconfig.system.qti \
    libnetutils.vendor

PRODUCT_PACKAGES += \
    android.frameworks.cameraservice.common-V1-ndk.vendor \
    android.frameworks.cameraservice.device-V3-ndk.vendor \
    android.frameworks.cameraservice.service-V3-ndk.vendor \
    android.frameworks.sensorservice-V1-ndk.vendor \
    android.frameworks.sensorservice@1.0.vendor \
    android.hardware.audio.common-V2-ndk.vendor \
    android.hardware.audio.common@5.0.vendor \
    android.hardware.biometrics.common-V2-ndk.vendor \
    android.hardware.biometrics.face-V2-ndk.vendor \
    android.hardware.bluetooth.audio-V3-ndk.vendor \
    android.hardware.bluetooth.audio@2.0.vendor \
    android.hardware.bluetooth.audio@2.1.vendor \
    android.hardware.bluetooth@1.0.vendor \
    android.hardware.bluetooth@1.1.vendor \
    android.hardware.camera.device-V2-ndk.vendor \
    android.hardware.camera.provider-V2-ndk.vendor \
    android.hardware.drm-V1-ndk.vendor \
    android.hardware.gatekeeper-V1-ndk.vendor \
    android.hardware.gnss-V3-ndk.vendor \
    android.hardware.graphics.bufferqueue@1.0.vendor \
    android.hardware.graphics.bufferqueue@2.0.vendor \
    android.hardware.health@1.0.vendor \
    android.hardware.health@2.0.vendor \
    android.hardware.health@2.1.vendor \
    android.hardware.keymaster-V3-ndk.vendor \
    android.hardware.keymaster@3.0.vendor \
    android.hardware.keymaster@4.0.vendor \
    android.hardware.keymaster@4.1.vendor \
    android.hardware.media.bufferpool2-V2-ndk.vendor \
    android.hardware.media.bufferpool@2.0.vendor \
    android.hardware.media.c2@1.0.vendor \
    android.hardware.media.c2@1.1.vendor \
    android.hardware.media.c2@1.2.vendor \
    android.hardware.media.omx@1.0.vendor \
    android.hardware.media@1.0.vendor \
    android.hardware.radio-V2-ndk.vendor \
    android.hardware.radio.data-V2-ndk.vendor \
    android.hardware.radio.network-V2-ndk.vendor \
    android.hardware.security.keymint-V3-ndk.vendor \
    android.hardware.security.keymint-V5-ndk.vendor \
    android.hardware.security.rkp-V3-ndk.vendor \
    android.hardware.security.sharedsecret-V1-ndk.vendor \
    android.hardware.thermal-V1-ndk.vendor \
    android.hardware.thermal@1.0.vendor \
    android.hardware.thermal@2.0.vendor \
    android.hardware.wifi.hostapd-V1-ndk.vendor \
    android.hardware.wifi.supplicant-V1-ndk.vendor \
    android.media.audio.common.types-V2-ndk.vendor \
    android.system.net.netd-V1-ndk.vendor \
    com.dsi.ant@1.0.vendor \
    libandroid_runtime_lazy.vendor \
    libaudioroute-v34 \
    libavservices_minijail.vendor \
    libbinder_shim.vendor \
    libcamera2ndk_vendor \
    libcap.vendor \
    libclang_rt.ubsan_standalone.vendor \
    libcodec2.vendor \
    libcodec2_hal_common.vendor \
    libcodec2_hidl@1.0.vendor \
    libcodec2_hidl@1.1.vendor \
    libcodec2_hidl@1.2.vendor \
    libcodec2_hidl_plugin \
    libcodec2_shim \
    libcodec2_soft_common.vendor \
    libcodec2_vndk.vendor \
    libcurl.vendor \
    libexif.vendor \
    libgatekeeper.vendor \
    libhidlbase_shim \
    libhidltransport.vendor \
    libhwbinder.vendor \
    libimage_io.vendor \
    libjpeg.vendor \
    libjson \
    libjsoncpp.vendor \
    libkeymaster_messages.vendor \
    libminijail.vendor \
    libpiex.vendor \
    libprocessgroup_shim \
    libprotobuf-cpp-full-21.7.vendor \
    libprotobuf-cpp-lite-21.7.vendor \
    libpsi.vendor \
    libqti_vndfwk_detect.vendor \
    librmnetctl \
    libsensorndkbridge \
    libsfplugin_ccodec_utils.vendor \
    libsqlite.vendor \
    libstagefright_aidl_bufferpool2.vendor \
    libstagefright_bufferpool@2.0.1.vendor \
    libtextclassifier_hash.vendor \
    libtflite.vendor \
    libui_shim.vendor \
    libusbhost.vendor \
    libwfdaac_vendor \
    libwpa_client \
    libyuv.vendor \
    vendor.display.config@1.0.vendor \
    vendor.qti.hardware.bluetooth.audio-V1-ndk.vendor \
    vendor.qti.hardware.bluetooth_audio@2.0.vendor \
    vendor.qti.hardware.bluetooth_audio@2.1.vendor \
    vendor.qti.hardware.btconfigstore@1.0.vendor \
    vendor.qti.hardware.btconfigstore@2.0.vendor \
    vendor.qti.hardware.camera.aon-V1-ndk.vendor \
    vendor.qti.hardware.camera.offlinecamera-V1-ndk.vendor \
    vendor.qti.hardware.camera.postproc@1.0.vendor \
    vendor.qti.hardware.capabilityconfigstore@1.0.vendor \
    vendor.qti.hardware.display.allocator@3.0.vendor \
    vendor.qti.hardware.display.allocator@4.0.vendor \
    vendor.qti.hardware.display.color-V1-ndk.vendor \
    vendor.qti.hardware.display.config-V2-ndk.vendor \
    vendor.qti.hardware.display.config-V7-ndk.vendor \
    vendor.qti.hardware.display.mapper@2.0.vendor \
    vendor.qti.hardware.display.postproc-V1-ndk.vendor \
    vendor.qti.hardware.servicetracker@1.0.vendor \
    vendor.qti.hardware.servicetracker@1.1.vendor \
    vendor.qti.hardware.servicetrackeraidl-V1-ndk.vendor \
    vendor.qti.hardware.systemhelper@1.0.vendor \
    vendor.xiaomi.hardware.displayfeature@1.0.vendor

# Vendor service manager
PRODUCT_PACKAGES += \
    vndservice \
    vndservicemanager

# Verified boot
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.verified_boot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.verified_boot.xml

# WiFi
PRODUCT_PACKAGES += \
    android.hardware.wifi-service \
    hostapd \
    libwifi-hal-ctrl \
    libwifi-hal-qcom \
    wpa_supplicant \
    wpa_supplicant.conf

PRODUCT_PACKAGES += \
    firmware_WCNSS_qcom_cfg.kiwi_v2.ini_symlink \
    firmware_WCNSS_qcom_cfg.qca6750.ini_symlink \
    firmware_wlan_mac.kiwi_v2.bin_symlink \
    firmware_wlan_mac.qca6750.bin_symlink \
    firmware_wlanmdsp.otaupdate_symlink \
    libclang_rt.ubsan_standalone.so_symlink

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/wifi/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.wifi.aware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.aware.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.passpoint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.passpoint.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml

# Vendor
$(call inherit-product, vendor/xiaomi/uke/uke-vendor.mk)
