//
// SPDX-FileCopyrightText: 2026 JohnnyFFM
// SPDX-FileCopyrightText: 2026 The LineageOS Project
// SPDX-License-Identifier: MIT
//
///////////////////////////////////////////////////////////////////////////////
// THIS FILE IS IMMUTABLE. DO NOT EDIT IN ANY CASE.                          //
///////////////////////////////////////////////////////////////////////////////

// This file is a snapshot of an AIDL file. Do not edit it manually. There are
// two cases:
// 1). this is a frozen version file - do not edit this in any case.
// 2). this is a 'current' file. If you make a backwards compatible change to
//     the interface (from the latest frozen version), the build system will
//     prompt you to update this file with `m <name>-update-api`.
//
// You must not make a backward incompatible change to any AIDL file built
// with the aidl_interface module type with versions property set. The module
// type is used to build AIDL files in a way that they can be used across
// independently updatable components of the system. If a device is shipped
// with such a backward incompatible change, it has a high risk of breaking
// later when a module using the interface is updated, e.g., Mainline modules.

package vendor.xiaomi.hardware.aidl.midevauth;
@VintfStability
interface IMidevauthService {
  int devauth_AllPersistData_clean();
  int devauth_BlackUidList_load(String s);
  int devauth_BlackUid_check(in byte[] b);
  String devauth_CAVersion_get();
  int devauth_OfflineMasterKey_check(in byte[] b);
  int devauth_OnlineDerivedKey_check(in byte[] a, in byte[] b);
  int devauth_OnlineDerivedkey_load(String s);
  String devauth_OnlineKey_WithUid_prepare(String s);
  String devauth_UidList_get();
  String devauth_UidList_prepare(String s);
  byte[] devauth_challenge_get(int i);
  String devauth_key_dump();
  int devauth_key_load(String a, String b);
  String devauth_key_prepare();
  int devauth_key_version();
  int devauth_token_verify(int i, in byte[] a, in byte[] b, in byte[] c, in byte[] d);
  byte[] devauth_token_get(int i, in byte[] uid, in byte[] keyMeta, in byte[] challenge);
}
