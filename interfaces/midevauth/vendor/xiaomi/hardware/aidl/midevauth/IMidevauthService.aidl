//
// SPDX-FileCopyrightText: 2026 JohnnyFFM
// SPDX-FileCopyrightText: 2026 The LineageOS Project
// SPDX-License-Identifier: MIT
//

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
