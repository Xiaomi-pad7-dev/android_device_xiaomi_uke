#
# Copyright (C) 2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/uke

AUDIO_HAL_DIR := hardware/qcom-caf/sm8650/audio/primary-hal

PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

$(call inherit-product-if-exists, hardware/qcom-caf/common/common.mk)

$(call inherit-product, frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk)

$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)

$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

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

PRODUCT_PACKAGES += \
    android.hardware.audio.service \
    android.hardware.audio@7.1-impl \
    android.hardware.audio.effect@7.0-impl \
    android.hardware.soundtrigger@2.3-impl \
    android.media.audio.common.types-V4-cpp \
    audio.primary.default \
    audio.primary.pineapple \
    audio.r_submix.default \
    audio.usb.default \
    audioadsprpcd \
    libagm \
    libagm_compress_plugin \
    libagm_mixer_plugin \
    libagm_pcm_plugin \
    libagmclient \
    libaudiochargerlistener \
    libbatterylistener \
    libcustomva_intf \
    libfmpal \
    libhfp_pal \
    libhotword_intf \
    libpalclient \
    libqcompostprocbundle \
    libqcomvisualizer \
    libqcomvoiceprocessing \
    libsndcardparser \
    libvolumelistener \
    lib_bt_aptx \
    lib_bt_ble \
    lib_bt_bundle \
    vendor.qti.hardware.AGMIPC@1.0-impl \
    vendor.qti.hardware.pal@1.0-impl

PRODUCT_PRODUCT_PROPERTIES += \
    ro.bluetooth.leaudio.supported=false \
    ro.bluetooth.leaudio_offload.supported=false \
    ro.bluetooth.leaudio_broadcaster.supported=false \
    bluetooth.profile.bap.unicast.client.enabled=false \
    bluetooth.profile.bap.broadcast.source.enabled=false \
    bluetooth.profile.bap.broadcast.assist.enabled=false \
    bluetooth.profile.csip.set_coordinator.enabled=false \
    bluetooth.profile.hap.client.enabled=false \
    bluetooth.profile.vcp.controller.enabled=false \
    bluetooth.profile.mcp.server.enabled=false \
    bluetooth.profile.ccp.server.enabled=false \
    persist.bluetooth.leaudio.disabled=true

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_cliffs/audio_effects.xml \
    $(LOCAL_PATH)/configs/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_cliffs/audio_policy_configuration.xml \
    $(LOCAL_PATH)/configs/audio/resourcemanager_cliffs_mtp.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_cliffs/resourcemanager_cliffs_mtp.xml \
    vendor/xiaomi/uke/proprietary/odm/etc/acdbdata/Forte/Forte_acdb_cal.acdb:$(TARGET_COPY_OUT_VENDOR)/etc/acdbdata/cliffs_mtp/Forte_acdb_cal.acdb \
    vendor/xiaomi/uke/proprietary/odm/etc/acdbdata/Forte/Forte_workspaceFileXml.qwsp:$(TARGET_COPY_OUT_VENDOR)/etc/acdbdata/cliffs_mtp/Forte_workspaceFileXml.qwsp \
    vendor/xiaomi/uke/proprietary/odm/etc/audio/sku_cliffs/adsp_sleep_monitor.conf:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_cliffs/adsp_sleep_monitor.conf \
    vendor/xiaomi/uke/proprietary/odm/etc/audio/sku_cliffs/mixer_paths_cliffs_mtp.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_cliffs/mixer_paths_cliffs_mtp.xml \
    vendor/xiaomi/uke/proprietary/odm/etc/audio/sku_cliffs/mixer_paths_overlay_dynamic.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_cliffs/mixer_paths_overlay_dynamic.xml \
    vendor/xiaomi/uke/proprietary/odm/etc/audio/sku_cliffs/mixer_paths_overlay_static.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_cliffs/mixer_paths_overlay_static.xml

PRODUCT_COPY_FILES += \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.audio.pro.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.pro.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.sip.voip.xml

PRODUCT_PACKAGES += \
    android.hardware.bluetooth.audio-impl-qti.so_symlink

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml

PRODUCT_PACKAGES += \
    android.hardware.boot-service.qti \
    android.hardware.boot-service.qti.recovery

PRODUCT_PACKAGES += \
    android.hardware.camera.device-V1-ndk.vendor \
    android.hardware.camera.metadata-V2-ndk.vendor

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.camera.concurrent.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.concurrent.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.full.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.full.xml \
    frameworks/native/data/etc/android.hardware.camera.raw.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.raw.xml

PRODUCT_PACKAGES += \
    android.hardware.graphics.composer3-V2-ndk.vendor \
    android.hardware.graphics.mapper@4.0-impl-qti-display \
    init.qti.display_boot.rc \
    init.qti.display_boot.sh \
    vendor.qti.hardware.display.allocator-service \
    vendor.qti.hardware.display.composer-service.rc \
    vendor.qti.hardware.display.composer-service.xml \
    vendor.qti.hardware.display.composer3-V1-ndk.vendor \
    vendor.qti.hardware.display.demura-service

PRODUCT_PACKAGES += \
    android.hardware.drm-service.clearkey \
    libdrm.vendor

PRODUCT_USE_DYNAMIC_PARTITIONS := true

PRODUCT_PACKAGES += \
    fastbootd

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/charger_fstab.qti:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/etc/charger_fstab.qti \
    $(LOCAL_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.qcom \
    $(LOCAL_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.qcom

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/gps/gps.conf:$(TARGET_COPY_OUT_VENDOR)/etc/gps.conf \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_ODM)/etc/permissions/android.hardware.location.gps.xml

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

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/tablet_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/tablet_core_hardware.xml

PRODUCT_PACKAGES += \
    android.hardware.health-service.qti \
    android.hardware.health-service.qti_recovery

PRODUCT_PACKAGES += \
    xiaomi.system.hypsys.common-service

PRODUCT_PACKAGES += \
    init.recovery.qcom.rc \
    init.uke.rc

PRODUCT_PACKAGES += \
    IPACM_Filter_cfg.xml \
    IPACM_cfg.xml \
    ipacm

PRODUCT_PACKAGES += \
    android.hardware.ir-service.example

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.consumerir.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.consumerir.xml

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/keyboard/Vendor_15d9_Product_00a3.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/Vendor_15d9_Product_00a3.idc

PRODUCT_PACKAGES += \
    android.hardware.lights-service.xiaomi

PRODUCT_COPY_FILES += \
    $(AUDIO_HAL_DIR)/configs/common/codec2/media_codecs_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_c2_audio.xml \
    $(AUDIO_HAL_DIR)/configs/common/codec2/service/1.0/c2audio.vendor.base-arm64.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/c2audio.vendor.base-arm64.policy \
    $(AUDIO_HAL_DIR)/configs/common/codec2/service/1.0/c2audio.vendor.ext-arm64.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/c2audio.vendor.ext-arm64.policy

PRODUCT_PACKAGES += \
    vendor.qti.hardware.memtrack-service

PRODUCT_PACKAGES += \
    BluetoothResOverlayUke \
    DeviceAsWebcamOverlay \
    FrameworkResOverlayUke \
    FrameworksResUke \
    NcmTetheringOverlay \
    SettingsOverlayUke \
    SettingsProviderResUke \
    SystemUIOverlayUke \
    WifiResCommon_Sys \
    WifiResCommonMainline_Sys \
    WifiResMainlineTarget_spf \
    WifiResTarget_sm8635

PRODUCT_PACKAGES += \
    vendor_bt_firmware_mountpoint \
    vendor_dsp_mountpoint \
    vendor_firmware_mnt_mountpoint

PRODUCT_PACKAGES += \
    android.hardware.power-service-qti

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/power/powerhint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/powerhint.xml

$(call soong_config_set,qtipower,mode_ext_lib,//$(LOCAL_PATH):libpowermode-ext-xiaomi)

PRODUCT_CHARACTERISTICS := nosdcard,tablet

PRODUCT_PACKAGES += \
    vendor.qti.qspa-service

PRODUCT_PACKAGES += \
    rfs_msm_mpss_readonly_mbnconfig_symlink

$(call soong_config_set_bool,recovery,target_recovery_uses_qti_drm,true)

PRODUCT_PACKAGES += \
    android.hardware.renderscript@1.0-impl

PRODUCT_PACKAGES += \
    android.hardware.hardware_keystore.xml

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.keystore.app_attest_key.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.keystore.app_attest_key.xml \
    frameworks/native/data/etc/android.software.device_id_attestation.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_id_attestation.xml \
    frameworks/native/data/etc/android.software.verified_boot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.verified_boot.xml

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

PRODUCT_SHIPPING_API_LEVEL := 34

PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH) \
    hardware/xiaomi \
    vendor/qcom/opensource/usb/etc

PRODUCT_PACKAGES += \
    android.hardware.thermal-service.qti

PRODUCT_COPY_FILES += \
    vendor/xiaomi/uke/proprietary/odm/firmware/novatek_nt36532_o82_fw_csot.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/novatek_nt36532_o82_fw_csot.bin \
    vendor/xiaomi/uke/proprietary/odm/firmware/novatek_nt36532_o82_fw_tm.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/novatek_nt36532_o82_fw_tm.bin \
    vendor/xiaomi/uke/proprietary/odm/firmware/novatek_nt36532_o82_mp_csot.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/novatek_nt36532_o82_mp_csot.bin \
    vendor/xiaomi/uke/proprietary/odm/firmware/novatek_nt36532_o82_mp_tm.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/novatek_nt36532_o82_mp_tm.bin

PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES += \
    android.hardware.usb-service.qti \
    android.hardware.usb.gadget-service.qti \
    usb_compositions.conf

PRODUCT_PACKAGES += \
    init.qcom.usb.sh \
    init.qcom.usb.rc

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml

PRODUCT_PACKAGES += \
    vndservice \
    vndservicemanager

PRODUCT_PACKAGES += \
    android.hardware.wifi-service \
    hostapd \
    libwifi-hal-ctrl \
    libwifi-hal-qcom \
    wpa_supplicant \
    wpa_supplicant.conf

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/wifi/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.wifi.aware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.aware.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.passpoint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.passpoint.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml

PRODUCT_PACKAGES += \
    firmware_wlanmdsp.otaupdate_symlink \
    firmware_wlan_mac.kiwi_v2.bin_symlink \
    firmware_wlan_mac.qca6750.bin_symlink \
    firmware_WCNSS_qcom_cfg.kiwi_v2.ini_symlink \
    firmware_WCNSS_qcom_cfg.qca6750.ini_symlink

PRODUCT_PACKAGES += \
    libclang_rt.ubsan_standalone.so_symlink

$(call inherit-product, vendor/xiaomi/uke/uke-vendor.mk)
$(call inherit-product, $(DEVICE_PATH)/vendor_libs.mk)

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/keyboard/NVTCapacitivePenM80p.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/NVTCapacitivePenM80p.idc \
    $(LOCAL_PATH)/keyboard/NVTCapacitivePenM80p-merged.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/NVTCapacitivePenM80p-merged.idc \
    $(LOCAL_PATH)/keyboard/NVTCapacitivePenP81c.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/NVTCapacitivePenP81c.idc \
    $(LOCAL_PATH)/keyboard/NVTCapacitivePenP81c-merged.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/NVTCapacitivePenP81c-merged.idc


# Stylus
PRODUCT_PACKAGES += \
    XiaomiStylus
