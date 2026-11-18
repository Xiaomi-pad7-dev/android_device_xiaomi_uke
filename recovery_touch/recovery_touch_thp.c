/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

/* Runs Xiaomi's touch host processing daemon, which recovery otherwise lacks. */

#include <android/log.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <sys/system_properties.h>
#include <time.h>

#define LOG_TAG "recovery_touch_thp"
#define LOG(prio, ...) __android_log_print(ANDROID_LOG_##prio, LOG_TAG, __VA_ARGS__)

/* The daemon waits for a sane clock before reporting touches. */
static void ensure_sane_clock(void) {
    char value[PROP_VALUE_MAX];
    struct timespec build = {0};
    struct timespec now;

    if (__system_property_get("ro.build.date.utc", value) <= 0) return;
    build.tv_sec = atol(value);

    if (clock_gettime(CLOCK_REALTIME, &now) == 0 && now.tv_sec >= build.tv_sec) return;

    if (clock_settime(CLOCK_REALTIME, &build) != 0) {
        LOG(ERROR, "failed to set the clock to the build date");
    }
}

int main(void) {
    void* handle;
    int (*thp_daemon_main)(void);
    int ret;

    ensure_sane_clock();

    handle = dlopen("libtouchreport.so", RTLD_NOW);
    if (!handle) {
        LOG(ERROR, "dlopen failed: %s", dlerror());
        return 1;
    }

    thp_daemon_main = (int (*)(void))dlsym(handle, "thp_daemon_main");
    if (!thp_daemon_main) {
        LOG(ERROR, "thp_daemon_main not found: %s", dlerror());
        return 1;
    }

    ret = thp_daemon_main();
    LOG(ERROR, "thp_daemon_main returned %d", ret);
    return ret ? ret : 1;
}
