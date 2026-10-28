#
# Copyright (C) 2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/uke

BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

AB_OTA_UPDATER := true
AB_OTA_PARTITIONS := \
    boot \
    dtbo \
    init_boot \
    odm \
    product \
    recovery \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

BOARD_SHIPPING_API_LEVEL := 34

TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-7a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo300

AUDIO_HAL_DIR := hardware/qcom-caf/sm8650/audio/primary-hal

AUDIO_FEATURE_ENABLED_AGM_HIDL := true
AUDIO_FEATURE_ENABLED_DLKM := true
AUDIO_FEATURE_ENABLED_DTS_EAGLE := false
AUDIO_FEATURE_ENABLED_GEF_SUPPORT := true
AUDIO_FEATURE_ENABLED_HW_ACCELERATED_EFFECTS := false
AUDIO_FEATURE_ENABLED_INSTANCE_ID := true
AUDIO_FEATURE_ENABLED_KEEP_ALIVE := true
AUDIO_FEATURE_ENABLED_PAL_HIDL := true
AUDIO_FEATURE_ENABLED_PROXY_DEVICE := true
AUDIO_FEATURE_ENABLED_SVA_MULTI_STAGE := true
BOARD_SUPPORTS_SOUND_TRIGGER := true
BOARD_USES_ALSA_AUDIO := true

TARGET_NO_BOOTLOADER := true
TARGET_BOOTLOADER_BOARD_NAME := uke

TARGET_SCREEN_DENSITY := 345

TARGET_FS_CONFIG_GEN := $(DEVICE_PATH)/configs/config.fs

BOARD_USES_QCOM_HARDWARE := true

BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096

BOARD_KERNEL_CMDLINE := \
    swinfo.fingerprint=uke:$(LINEAGE_VERSION) \
    mtdoops.fingerprint=uke:$(LINEAGE_VERSION)

BOARD_BOOTCONFIG := \
    androidboot.console=0 \
    androidboot.hardware=qcom \
    androidboot.load_modules_parallel=true \
    androidboot.memcg=1 \
    androidboot.vendor.qspa=true \
    androidboot.usbcontroller=a600000.dwc3 \
    androidboot.hypervisor.protected_vm.supported=false \
    log_buf_len=256K \
    swiotlb=noforce \
    loop.max_part=7 \
    pcie_ports=compat \
    irqaffinity=0-2 \
    sysctl.kernel.sched_pelt_multiplier=4 \
    cpufreq.default_governor=performance \
    kasan=off \
    cgroup.memory=nokmem,nosocket \
    disable_dma32=on \
    kernel.panic_on_rcu_stall=1 \
    fw_devlink.strict=1 \
    service_locator.enable=1 \
    rcupdate.rcu_expedited=1 \
    rcu_nocbs=0-7 \
    no-steal-acc \
    printk.console_no_auto_verbose=0 \
    can.stats_timer=0 \
    video=vfb:640x400,bpp=32,memsize=3072000 \
    firmware_class.path=/vendor/firmware_mnt/image,/vendor/firmware_mnt/image/kiwi,/vendor/vm-system/oemvm/boot,/vendor/vm-system/trustedvm/boot,/vendor/firmware,/vendor/firmware/wlan/qca_cld/kiwi_v2

BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_RAMDISK_USE_LZ4 := true

BOARD_BOOT_HEADER_VERSION := 4
BOARD_INIT_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_INIT_ARGS += --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)

BOARD_KERNEL_IMAGE_NAME := Image
BOARD_USES_GENERIC_KERNEL_IMAGE := true

TARGET_KERNEL_VERSION := 6.1
TARGET_KERNEL_SOURCE := kernel/xiaomi/sm8635
TARGET_KERNEL_CONFIG := \
    gki_defconfig \
    vendor/pineapple_GKI.config
TARGET_KERNEL_CONFIG_EXT := \
    $(DEVICE_PATH)/configs/kernel/uke_GKI.config \
    $(DEVICE_PATH)/configs/kernel/uke_consolidate.config \
    $(DEVICE_PATH)/configs/kernel/uke_recovered.config
TARGET_KERNEL_CLANG_COMPILE := true
# Do not pass TARGET_PRODUCT here: the audio Kbuilds gate per-device config
# with $(word 2,$(subst _, ,$(TARGET_PRODUCT))) and a bare "uke" has no second
# token, which silently compiles out -DCONFIG_TARGET_PRODUCT_UKE (no speaker
# dailink, audio falls back to msm-stub-codec).
TARGET_KERNEL_ADDITIONAL_FLAGS := LLVM=1 LLVM_IAS=1

TARGET_NEEDS_DTBOIMAGE := true
BOARD_USES_QCOM_MERGE_DTBS_SCRIPT := true
# Only merge the Cliffs board DTBs into vendor_boot; merging every DTB in the
# kernel tree overflows the 96 MiB vendor_boot partition.
TARGET_MERGE_DTBS_WILDCARD := cliffs*
TARGET_MERGE_DTBOS_WILDCARD := uke-*

TARGET_KERNEL_EXT_MODULE_ROOT := kernel/xiaomi/sm8635-modules
BUILD_BROKEN_SRC_DIR_RW_ALLOWLIST := $(abspath $(TARGET_KERNEL_EXT_MODULE_ROOT))
TARGET_KERNEL_EXT_MODULES := \
    qcom/opensource/mmrm-driver \
    qcom/opensource/mm-drivers/hw_fence \
    qcom/opensource/mm-drivers/msm_ext_display \
    qcom/opensource/mm-drivers/sync_fence \
    qcom/opensource/synx-kernel \
    qcom/opensource/securemsm-kernel \
    qcom/opensource/display-drivers/msm \
    qcom/opensource/graphics-kernel \
    qcom/opensource/video-driver \
    qcom/opensource/dsp-kernel \
    qcom/opensource/eva-kernel \
    qcom/opensource/camera-kernel \
    qcom/opensource/spu-kernel \
    qcom/opensource/audio-kernel \
    qcom/opensource/mm-sys-kernel/ubwcp \
    qcom/opensource/datarmnet-ext/mem \
    qcom/opensource/dataipa/drivers/platform/msm \
    qcom/opensource/datarmnet/core \
    qcom/opensource/datarmnet-ext/sch \
    qcom/opensource/datarmnet-ext/wlan \
    qcom/opensource/datarmnet-ext/shs \
    qcom/opensource/datarmnet-ext/perf \
    qcom/opensource/datarmnet-ext/perf_tether \
    qcom/opensource/datarmnet-ext/offload \
    qcom/opensource/datarmnet-ext/aps \
    qcom/opensource/wlan/platform \
    qcom/opensource/wlan/qca6750 \
    qcom/opensource/bt-kernel \
    qcom/opensource/touch-drivers \
    nxp/opensource/driver

first_stage_modules := $(strip $(shell cat $(TARGET_KERNEL_SOURCE)/modules.list.msm.pineapple $(DEVICE_PATH)/modules/modules.list.first_stage 2>/dev/null))
second_stage_modules := $(strip $(shell cat $(DEVICE_PATH)/modules/modules.list.second_stage))
vendor_dlkm_modules := $(strip $(shell cat $(DEVICE_PATH)/modules/modules.list.vendor_dlkm))
system_dlkm_modules := $(strip $(shell sed 's/#.*$$//;/^$$/d;s|.*/||' $(DEVICE_PATH)/modules/modules.list.system_dlkm))

BOARD_SYSTEM_KERNEL_MODULES_LOAD := $(system_dlkm_modules)
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(first_stage_modules)
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(first_stage_modules) $(second_stage_modules)
BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(TARGET_KERNEL_SOURCE)/modules.vendor_blocklist.msm.pineapple
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_BLOCKLIST_FILE := $(BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE)
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(second_stage_modules) $(vendor_dlkm_modules)

BOOT_KERNEL_MODULES := $(first_stage_modules) $(second_stage_modules)
SYSTEM_KERNEL_MODULES := $(BOARD_SYSTEM_KERNEL_MODULES_LOAD)

BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_DTBOIMG_PARTITION_SIZE := 20971520
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600
BOARD_SUPER_PARTITION_SIZE := 11274289152
BOARD_FLASH_BLOCK_SIZE := 262144

BOARD_USES_METADATA_PARTITION := true

BOARD_XIAOMI_DYNAMIC_PARTITIONS_PARTITION_LIST := odm product system system_dlkm system_ext vendor vendor_dlkm
BOARD_XIAOMI_DYNAMIC_PARTITIONS_SIZE := 11270051072
BOARD_SUPER_PARTITION_GROUPS := xiaomi_dynamic_partitions

$(foreach p, $(call to-upper, $(BOARD_XIAOMI_DYNAMIC_PARTITIONS_PARTITION_LIST)), \
    $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := ext4) \
    $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))

BOARD_PRODUCTIMAGE_MINIMAL_PARTITION_RESERVED_SIZE := false
-include vendor/lineage/config/BoardConfigReservedSize.mk
BOARD_PRODUCTIMAGE_PARTITION_RESERVED_SIZE ?= 104857600
BOARD_SYSTEMIMAGE_PARTITION_RESERVED_SIZE ?= 104857600
BOARD_SYSTEM_EXTIMAGE_PARTITION_RESERVED_SIZE ?= 104857600
BOARD_SYSTEM_DLKMIMAGE_PARTITION_RESERVED_SIZE ?= 33554432
BOARD_VENDORIMAGE_PARTITION_RESERVED_SIZE ?= 104857600
BOARD_VENDOR_DLKMIMAGE_PARTITION_RESERVED_SIZE ?= 33554432
BOARD_ODMIMAGE_PARTITION_RESERVED_SIZE ?= 33554432

TARGET_BOARD_PLATFORM := pineapple

WITH_DEXPREOPT_ART_BOOT_IMG_ONLY := true

TARGET_ODM_PROP += $(DEVICE_PATH)/props/odm.prop
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/props/product.prop
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/props/system.prop
TARGET_SYSTEM_EXT_PROP += $(DEVICE_PATH)/props/system_ext.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/props/vendor.prop

BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.qcom
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

include device/qcom/sepolicy_vndr/SEPolicy.mk
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/private
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/public

BOOT_SECURITY_PATCH := 2026-01-01
VENDOR_SECURITY_PATCH := $(BOOT_SECURITY_PATCH)

BOARD_AVB_ENABLE := true

BOARD_AVB_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_BOOT_ALGORITHM := SHA256_RSA2048
BOARD_AVB_BOOT_ROLLBACK_INDEX := 1769904000
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION := 3
BOARD_AVB_BOOT_ADD_HASH_FOOTER_ARGS += \
    --rollback_index 1769904000 \
    --rollback_index_location 3

BOARD_AVB_VBMETA_SYSTEM := product system system_ext
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := 1
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA2048
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 1
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1
BOARD_AVB_RECOVERY_ADD_HASH_FOOTER_ARGS += \
    --rollback_index 1 \
    --rollback_index_location 1

DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    $(DEVICE_PATH)/configs/vintf/framework_compatibility_matrix.xml \
    hardware/qcom-caf/common/vendor_framework_compatibility_matrix.xml \
    hardware/xiaomi/vintf/xiaomi_framework_compatibility_matrix.xml

DEVICE_FRAMEWORK_MANIFEST_FILE := $(DEVICE_PATH)/configs/vintf/framework_manifest.xml
DEVICE_MATRIX_FILE := hardware/qcom-caf/common/compatibility_matrix.xml
DEVICE_MANIFEST_FILE := \
    $(AUDIO_HAL_DIR)/configs/common/manifest_non_qmaa_extn.xml \
    $(DEVICE_PATH)/configs/vintf/manifest.xml

BOARD_WLAN_DEVICE := qcwcn
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_WPA_SUPPLICANT_PRIVATE_LIB_EVENT := "ON"
WIFI_DRIVER_STATE_CTRL_PARAM := "/dev/wlan"
WIFI_DRIVER_STATE_OFF := "OFF"
WIFI_DRIVER_STATE_ON := "ON"
WIFI_FEATURE_HOSTAPD_11AX := true
WIFI_HIDL_FEATURE_AWARE := true
WIFI_HIDL_FEATURE_DUAL_INTERFACE := true
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true
WPA_SUPPLICANT_VERSION := VER_0_8_X

include vendor/xiaomi/uke/BoardConfigVendor.mk
