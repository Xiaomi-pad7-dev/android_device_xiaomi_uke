#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: 2025 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from os import path

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixup_remove,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)
from extract_utils.module import ProprietaryFile


namespace_imports = [
    'device/xiaomi/uke',
    'hardware/qcom-caf/sm8650',
    'hardware/qcom-caf/wlan',
    'hardware/xiaomi',
    'vendor/qcom/opensource/commonsys/display',
    'vendor/qcom/opensource/commonsys-intf/display',
    'vendor/qcom/opensource/dataservices',
]

lib_fixups: lib_fixups_user_type = {
    (
        'android.hardware.camera.device-V1-ndk',
        'android.hardware.camera.metadata-V2-ndk',
        'android.hardware.graphics.composer3-V2-ndk',
        'vendor.qti.hardware.display.composer3-V1-ndk',
        'libheif',
    ): lib_fixup_remove,
}

blob_fixups: blob_fixups_user_type = {
    'system/framework/WfdCommon.jar': blob_fixup()
        .apktool_patch('blob-patches/WfdCommon.patch'),
    (
        'odm/etc/camera/enhance_motiontuning.xml',
        'odm/etc/camera/motiontuning.xml',
        'odm/etc/camera/night_motiontuning.xml'
    ): blob_fixup()
        .regex_replace('xml=version', 'xml version'),
    (
        'odm/lib64/libAncHumanVideoBokehV4.so',
        'odm/lib64/libMiEmojiEffect.so',
        'odm/lib64/libTrueSight.so',
        'odm/lib64/libalLDC.so',
        'odm/lib64/libanc_single_rt_bokeh.so',
        'vendor/lib64/libMiPhotoFilter.so',
        'vendor/lib64/libMiVideoFilter.so',
        'vendor/lib64/libmorpho_ubwc.so',
    ): blob_fixup()
        .clear_symbol_version('AHardwareBuffer_allocate')
        .clear_symbol_version('AHardwareBuffer_describe')
        .clear_symbol_version('AHardwareBuffer_isSupported')
        .clear_symbol_version('AHardwareBuffer_lock')
        .clear_symbol_version('AHardwareBuffer_lockPlanes')
        .clear_symbol_version('AHardwareBuffer_release')
        .clear_symbol_version('AHardwareBuffer_unlock'),
    # Blobs linking the removed allocator-V1 AIDL interface are normalised to V2.
    (
        'odm/lib64/camera/com.qti.actuator.o82_ofilm_ov13b10_cn3927v_wide_i_actuator.so',
        'odm/lib64/camera/com.qti.eeprom.o82_aac_ov08d10_gt24p64e_front_i_eeprom.so',
        'odm/lib64/camera/com.qti.eeprom.o82_ofilm_ov13b10_bl24sa64_wide_i_eeprom.so',
        'odm/lib64/camera/com.qti.sensor.o82_aac_ov08d10_front_i.so',
        'odm/lib64/camera/com.qti.sensor.o82_ofilm_ov13b10_wide_i.so',
        'odm/lib64/camera/components/com.jigan.node.videobokeh.so',
        'odm/lib64/camera/components/com.mi.node.aiasd.so',
        'odm/lib64/camera/components/com.mi.node.rearvideo.so',
        'odm/lib64/camera/components/com.mi.node.videonight.so',
        'odm/lib64/camera/libchxlogicalcameratable.so',
        'vendor/lib64/camera/components/com.mi.node.dlengine.so',
        'vendor/lib64/camera/components/com.mi.node.mawsaliency.so',
        'vendor/lib64/camera/components/com.mi.node.videobokeh.so',
        'vendor/lib64/camera/components/com.mi.node.videofilter.so',
        'vendor/lib64/camera/components/com.qti.hwcfg.bps.so',
        'vendor/lib64/camera/components/com.qti.hwcfg.ife.so',
        'vendor/lib64/camera/components/com.qti.hwcfg.ipe.so',
        'vendor/lib64/camera/components/com.qti.node.aon.so',
        'vendor/lib64/camera/components/com.qti.node.depth.so',
        'vendor/lib64/camera/components/com.qti.node.depthprovider.so',
        'vendor/lib64/camera/components/com.qti.node.dewarp.so',
        'vendor/lib64/camera/components/com.qti.node.eisv2.so',
        'vendor/lib64/camera/components/com.qti.node.eisv3.so',
        'vendor/lib64/camera/components/com.qti.node.evadepth.so',
        'vendor/lib64/camera/components/com.qti.node.gme.so',
        'vendor/lib64/camera/components/com.qti.node.gyrornn.so',
        'vendor/lib64/camera/components/com.qti.node.hdr10pgen.so',
        'vendor/lib64/camera/components/com.qti.node.hdr10phist.so',
        'vendor/lib64/camera/components/com.qti.node.itofpreprocess.so',
        'vendor/lib64/camera/components/com.qti.node.ml.so',
        'vendor/lib64/camera/components/com.qti.node.mlinference.so',
        'vendor/lib64/camera/components/com.qti.node.pixelstats.so',
        'vendor/lib64/camera/components/com.qti.node.seg.so',
        'vendor/lib64/camera/components/com.qti.node.swec.so',
        'vendor/lib64/camera/components/com.qti.node.swregistration.so',
        'vendor/lib64/camera/components/com.qti.stats.cnndriver.so',
        'vendor/lib64/camera/components/libcamxevainterface.so',
        'vendor/lib64/camera/components/libdepthmapwrapper_itof.so',
        'vendor/lib64/camera/components/libdepthmapwrapper_secure.so',
        'vendor/lib64/com.qti.camx.chiiqutils.so',
        'vendor/lib64/com.qti.chiusecaseselector.so',
        'vendor/lib64/com.qti.feature2.afbrckt.so',
        'vendor/lib64/com.qti.feature2.anchorsync.so',
        'vendor/lib64/com.qti.feature2.demux.so',
        'vendor/lib64/com.qti.feature2.derivedoffline.so',
        'vendor/lib64/com.qti.feature2.fusion.so',
        'vendor/lib64/com.qti.feature2.generic.so',
        'vendor/lib64/com.qti.feature2.gs.sm8650.so',
        'vendor/lib64/com.qti.feature2.hdr.so',
        'vendor/lib64/com.qti.feature2.mcreprocrt.so',
        'vendor/lib64/com.qti.feature2.memcpy.so',
        'vendor/lib64/com.qti.feature2.metadataserializer.so',
        'vendor/lib64/com.qti.feature2.mfsr.so',
        'vendor/lib64/com.qti.feature2.ml.so',
        'vendor/lib64/com.qti.feature2.mux.so',
        'vendor/lib64/com.qti.feature2.offlinestatsregeneration.so',
        'vendor/lib64/com.qti.feature2.qcfa.so',
        'vendor/lib64/com.qti.feature2.rawhdr.so',
        'vendor/lib64/com.qti.feature2.realtimeserializer.so',
        'vendor/lib64/com.qti.feature2.rt.so',
        'vendor/lib64/com.qti.feature2.rtmcx.so',
        'vendor/lib64/com.qti.feature2.serializer.so',
        'vendor/lib64/com.qti.feature2.statsregeneration.so',
        'vendor/lib64/com.qti.feature2.stub.so',
        'vendor/lib64/com.qti.feature2.swmf.so',
        'vendor/lib64/com.qti.qseeutils.so',
        'vendor/lib64/com.qualcomm.mcx.distortionmapper.so',
        'vendor/lib64/com.qualcomm.mcx.linearmapper.so',
        'vendor/lib64/com.qualcomm.mcx.nonlinearmapper.so',
        'vendor/lib64/com.qualcomm.mcx.policy.mfl.so',
        'vendor/lib64/com.qualcomm.qti.mcx.usecase.extension.so',
        'vendor/lib64/com.xiaomi.immunesystem.hook.camx.so',
        'vendor/lib64/com.xiaomi.immunesystem.hook.chi.so',
        'vendor/lib64/hw/camera.qcom.sm8650.so',
        'vendor/lib64/hw/camera.qcom.so',
        'vendor/lib64/hw/com.qti.chi.offline.so',
        'vendor/lib64/hw/com.qti.chi.override.so',
        'vendor/lib64/libcamerapostproc.so',
        'vendor/lib64/libcamxhwnodecontext.so',
        'vendor/lib64/libcamxifestriping.so',
        'vendor/lib64/libcamximageformatutils.so',
        'vendor/lib64/libcamxncsdatafactory.so',
        'vendor/lib64/libchifeature2.so',
        'vendor/lib64/libcom.xiaomi.mawutilsold.so',
        'vendor/lib64/libcom.xiaomi.qimagebuffer.so',
        'vendor/lib64/libcommonchiutils.so',
        'vendor/lib64/libfastmessage.so',
        'vendor/lib64/libhme.so',
        'vendor/lib64/libipebpsstriping.so',
        'vendor/lib64/libipebpsstriping170.so',
        'vendor/lib64/libipebpsstriping480.so',
        'vendor/lib64/libisphwsetting.so',
        'vendor/lib64/libjpege.so',
        'vendor/lib64/libmctfengine_stub.so',
        'vendor/lib64/libmfec.so',
        'vendor/lib64/libmmcamera_bestats.so',
        'vendor/lib64/libmmcamera_cac.so',
        'vendor/lib64/libmmcamera_lscv35.so',
        'vendor/lib64/libmmcamera_pdpc.so',
        'vendor/lib64/libopestriping.so',
        'vendor/lib64/libpostprocinfo.so',
        'vendor/lib64/libsimulation.so',
        'vendor/lib64/libubifocus.so',
        'vendor/lib64/vendor.qti.hardware.camera.aon-service-impl.so',
        'vendor/lib64/vendor.qti.hardware.camera.offlinecamera-service-impl.so',
        'vendor/lib64/vendor.qti.hardware.camera.postproc@1.0-service-impl.so',
    ): blob_fixup()
        .replace_needed('android.hardware.graphics.allocator-V1-ndk.so', 'android.hardware.graphics.allocator-V2-ndk.so'),
    (
        'odm/lib64/libaudioroute_ext.so',
        'vendor/lib64/libagm.so',
        'vendor/lib64/libar-pal.so',
        'vendor/lib64/libkaraokepal.so',
        'vendor/lib64/libmcs.so',
    ): blob_fixup()
        .replace_needed('libaudioroute.so', 'libaudioroute-v34.so'),
    # Point the blob at Soong's module name; device.mk installs the matching symlink.
    'vendor/lib64/libwfdhdcpservice_proprietary.so': blob_fixup()
        .replace_needed('libclang_rt.ubsan_standalone-aarch64-android.so', 'libclang_rt.ubsan_standalone.so'),
    # AIDL versions are additive, so the blob is moved from types-V4 to the V5 lib.
    'system_ext/lib64/libwfdservice.so': blob_fixup()
        .replace_needed('android.media.audio.common.types-V4-cpp.so', 'android.media.audio.common.types-V5-cpp.so'),
    # Compat shims supply symbols the platform stopped exporting.
    (
        'vendor/bin/qcc-vendor',
        'vendor/bin/xtra-daemon',
        'vendor/lib64/libcne.so',
        'vendor/lib64/libqcc_sdk.so',
    ): blob_fixup()
        .add_needed('libbinder_shim.so'),
    (
        'vendor/lib64/vendor.libdpmframework.so',
    ): blob_fixup()
        .add_needed('libbinder_shim.so')
        .add_needed('libhidlbase_shim.so'),
    (
        'vendor/lib64/libqcodec2_core.so',
    ): blob_fixup()
        .add_needed('libcodec2_shim.so'),
    (
        'vendor/lib64/libmicamera_hal_core.so',
    ): blob_fixup()
        .add_needed('libui_shim.so'),
    (
        'vendor/lib64/hw/camera.qcom.so',
        'vendor/lib64/hw/com.qti.chi.override.so',
        'vendor/lib64/libcameraopt.so',
        'vendor/lib64/libcamxcommonutils.so',
        'vendor/lib64/libchifeature2.so',
        'vendor/lib64/libmialgoengine.so',
    ): blob_fixup()
        .add_needed('libprocessgroup_shim.so'),
    # The vendor libtensorflowlite_c provides the XNNPack delegates these blobs need.
    (
        'vendor/lib64/libVoiceSdk.so',
        'vendor/lib64/libcapiv2uvvendor.so',
        'vendor/lib64/liblistensoundmodel2vendor.so',
    ): blob_fixup()
        .replace_needed('libtensorflowlite_c.so', 'libtensorflowlite_c_vendor.so'),
    (
        'vendor/lib64/vendor.xiaomi.hardware.camera.injection-V1-ndk.so',
        'vendor/lib64/vendor.xiaomi.hardware.camera.injection-client.so',
        'vendor/lib64/vendor.xiaomi.hardware.camera.injection-service.so',
    ): blob_fixup()
        .replace_needed('android.hardware.camera.device-V1-ndk.so', 'android.hardware.camera.device-V2-ndk.so'),
    (
        'odm/lib64/camera/plugins/com.xiaomi.plugin.gainmap.so',
        'odm/lib64/camera/plugins/com.xiaomi.plugin.jpegrAggr.so',
    ): blob_fixup()
        .replace_needed(
            'libultrahdr.so',
            'libultrahdr_prebuilt.so',
        ),
    'vendor/lib64/libultrahdr_prebuilt.so': blob_fixup()
        .replace_needed(
            'libjpegdecoder.so',
            'libjpegdecoder_prebuilt.so',
        )
        .replace_needed(
            'libjpegencoder.so',
            'libjpegencoder_prebuilt.so',
        ),
    'system_ext/lib64/vendor.qti.hardware.qccsyshal@1.2-halimpl.so': blob_fixup()
        .replace_needed('libprotobuf-cpp-full.so', 'libprotobuf-cpp-full-21.7.so'),
    (
        'odm/bin/hw/vendor.xiaomi.sensor.citsensorservice.aidl',
        'odm/lib64/hw/displayfeature.default.so',
        'vendor/bin/hw/vendor.qti.camera.provider-service_64',
        'vendor/bin/hw/vendor.qti.hardware.display.composer-service',
        'vendor/lib64/libaudiocloudctrl.so',
        'vendor/lib64/libdpps.so',
        'vendor/lib64/libmicamera_aidl_provider.so',
        'vendor/lib64/libsnapdragoncolor-manager.so',
    ): blob_fixup()
        .replace_needed('libtinyxml2.so', 'libtinyxml2_1.so'),
    'vendor/lib64/com.qti.feature2.anchorsync.so': blob_fixup()
        .replace_needed('android.hardware.graphics.allocator-V1-ndk.so', 'android.hardware.graphics.allocator-V2-ndk.so')
        .replace_needed('libtinyxml2.so', 'libtinyxml2_1.so'),
    'vendor/etc/clstc_config_library.xml': blob_fixup()
        .regex_replace(r'<library>\s*<name>libdolbyclstc[\s\S]*?</library>', ''),
    'vendor/etc/vintf/manifest/c2_manifest_vendor.xml': blob_fixup()
        .regex_replace('.+DOLBY.+\n', ''),
}

module = ExtractUtilsModule(
    'uke',
    'xiaomi',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
    add_firmware_proprietary_file=True,
    proprietary_files=[
        ProprietaryFile(
            path.join(path.dirname(path.abspath(__file__)), 'proprietary-audio.txt'),
        ),
    ],
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
