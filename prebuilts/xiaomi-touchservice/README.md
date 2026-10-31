# Xiaomi PencilEngine port (uke)

Ported from the stock HyperOS 3 ROM for `uke` so pen apps that gate their
gesture support on Xiaomi's PencilEngine actually get it on LineageOS.

## What ships

| file | installs to | source |
|---|---|---|
| `prebuilts/xiaomi-pencilengine/xiaomi-pencilengine-pad.jar` | `/system_ext/framework/` | stock `system_ext_a.img` (`dump.erofs --cat`) |
| `prebuilts/xiaomi-touchservice/TouchService.apk` | `/system_ext/priv-app/TouchService/` | stock `system_ext_a.img` + our `classes2.dex` stubs |
| `stylus` app (`org.pixelos.stylus`) | `/system_ext/priv-app/XiaomiStylus/` | this tree |

`TouchService.apk` declares `sharedUserId android.uid.system`, so it is imported
with `android_app_import { certificate: "platform", privileged: true }` — the
build re-signs it and installs it as uid 1000.

## Why the stubs exist

`TouchService` resolves three MIUI classes at runtime that LineageOS does not
have. Missing them it logs

```
E/PencilEngine_FeatureManager: Fail to get feature support status, miui.os.HyperOSCustFeatureResolve
I/PencilEngine_Service: Binding request rejected, not support this device
```

and StarNote silently gets nothing. The stubs live in `classes2.dex` inside the
APK (sources in `stubs/`):

| stub | behaviour |
|---|---|
| `miui.os.HyperOSCustFeatureResolve` | `getBoolean("support_pencil_engine")` → `true`, everything else → caller default |
| `miui.hardware.input.MiuiInputManager` | singleton; `enableStylusTouchFilmForApp` / `enableStylusPostureForApp` log and no-op |
| `miui.os.Build` | `IS_INTERNATIONAL_BUILD = true` |

## Rebuilding the APK with stubs

```bash
javac --release 8 -d /tmp/stubout $(find stubs -name '*.java')
(cd /tmp/stubout && jar cf /tmp/miui-stubs.jar .)
$OUT/host/linux-x86/bin/d8 --min-api 30 --output /tmp/dexout /tmp/miui-stubs.jar
cp /tmp/dexout/classes.dex /tmp/classes2.dex

cp TouchService.apk /tmp/TouchService_new.apk
(cd /tmp && zip -j TouchService_new.apk classes2.dex)

$OUT/host/linux-x86/bin/apksigner sign \
    --key build/make/target/product/security/platform.pk8 \
    --cert build/make/target/product/security/platform.x509.pem \
    --out TouchService.apk /tmp/TouchService_new.apk
```

`apksigner` must be used, never `signapk`: R+ system apps need
`resources.arsc` stored uncompressed, and `signapk` deflates it, which makes the
package manager reject the APK on boot.

## The other half of the gate: the settings marker

Even with the jar and the service in place, StarNote only registers a listener
when `Settings.System.stylus_pencil_engine_version == "0.3.2"`. Without it the
bind succeeds, `triggerFunction` is called before registration, returns `-1`, and
the app unbinds:

```
I/PencilEngine_Service: No listener has been registered for this process N
I/MI-PencilManager:     Unbound service
```

`StylusApplication` writes the marker on boot.

Healthy log once everything is in place:

```
I/MI-PencilManager:       System initialization successful
I/MI-PencilManager:       Is bound service = true, is support notify system = true
I/PencilEngine_Service:   Binding request accepted
I/PencilEngine_Service:   Add client record, client pid = N, client records count = 1
I/PencilEngine_TouchFilm: Client N request touch film = true
```

## Testing without a rebuild

Both artifacts can be dropped in by hand on a rooted userdebug build:

```bash
mkdir -p /mnt/ovl && mount -t tmpfs -o size=256m tmpfs /mnt/ovl
mkdir -p /mnt/ovl/upper /mnt/ovl/work
mount -t overlay overlay \
  -o lowerdir=/system_ext,upperdir=/mnt/ovl/upper,workdir=/mnt/ovl/work /system_ext
# copy the jar to /system_ext/framework/ and the APK to
# /system_ext/priv-app/TouchService/TouchService.apk, chmod 644, restorecon
adb shell stop && adb shell start        # framework restart rescans priv-app
```

The overlay is tmpfs, so it dies on reboot — that is why it is now baked into
the build instead.
