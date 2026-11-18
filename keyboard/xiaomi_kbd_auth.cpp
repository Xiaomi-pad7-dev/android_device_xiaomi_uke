/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

/*
 * The keyboard stops sending keys a while after attaching unless the tablet
 * answers its MiAuth challenge with a token from the devauth trustlet.
 * Handshake from https://github.com/JohnnyFFM/xiaomi-keyboard-fix
 */

#define LOG_TAG "xiaomi_kbd_auth"

#include <aidl/vendor/xiaomi/hardware/aidl/midevauth/IMidevauthService.h>
#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/unique_fd.h>
#include <android/binder_manager.h>

#include <fcntl.h>
#include <unistd.h>

#include <array>
#include <cstdint>
#include <memory>
#include <vector>

using aidl::vendor::xiaomi::hardware::aidl::midevauth::IMidevauthService;
using android::base::unique_fd;

namespace {

constexpr char kDevice[] = "/dev/nanodev0";
constexpr size_t kFrameSize = 66;
constexpr size_t kPacketSize = 68;

constexpr uint8_t kCmdAuthStart = 0x31;
constexpr uint8_t kCmdChallenge = 0x32;
constexpr uint8_t kCmdToken = 0x33;
constexpr uint8_t kCmdStatus = 0x24;
constexpr uint8_t kStatusInit = 0x01;
constexpr uint8_t kStatusReauth = 0x64;

constexpr size_t kUidSize = 16;
constexpr size_t kKeyMetaSize = 4;
constexpr size_t kChallengeSize = 16;

using Bytes = std::vector<uint8_t>;

class KeyboardAuth {
  public:
    KeyboardAuth(unique_fd fd, std::shared_ptr<IMidevauthService> service)
        : fd_(std::move(fd)), service_(std::move(service)) {}

    void run() {
        sendAuthStart();
        std::array<uint8_t, kPacketSize> packet;
        while (true) {
            ssize_t len = TEMP_FAILURE_RETRY(read(fd_.get(), packet.data(), packet.size()));
            if (len < 0) {
                PLOG(ERROR) << "read failed";
                return;
            }
            if (len == 0) {
                usleep(100000);
                continue;
            }
            handlePacket(packet.data(), len);
        }
    }

  private:
    void sendCommand(uint8_t cmd, const Bytes& payload) {
        Bytes body = {0x4f, 0x31, 0x80, 0x38, cmd, static_cast<uint8_t>(payload.size())};
        body.insert(body.end(), payload.begin(), payload.end());
        uint8_t sum = 0;
        for (uint8_t b : body) sum += b;

        std::array<uint8_t, kFrameSize> frame = {0x32, 0x00};
        std::copy(body.begin(), body.end(), frame.begin() + 2);
        frame[2 + body.size()] = sum;
        if (!android::base::WriteFully(fd_, frame.data(), frame.size())) {
            PLOG(ERROR) << "write of command " << +cmd << " failed";
        }
    }

    void sendAuthStart() { sendCommand(kCmdAuthStart, {'M', 'I', 'A', 'U', 'T', 'H'}); }

    static bool isHeader(const uint8_t* p) { return p[0] == 0x31 && p[1] == 0x38 && p[2] == 0x80; }

    // Messages are framed as <type> 31 38 80 <cmd> <len> <payload>.
    static size_t messageSize(const uint8_t* msg) {
        switch (msg[0]) {
            case 0x22:
                return 16;
            case 0x23:
                return 32;
            case 0x24:
            case 0x26:
                return 7 + msg[5];
            default:
                return 0;
        }
    }

    void handlePacket(const uint8_t* p, size_t len) {
        size_t i = 0;
        while (i + 7 <= len) {
            const uint8_t* msg = p + i;
            size_t size = messageSize(msg);
            if (size == 0 || !isHeader(msg + 1) || isHeader(msg + 5)) {
                i++;
                continue;
            }
            size_t avail = len - i;
            switch (msg[4]) {
                case kCmdStatus:
                    if (msg[6] == kStatusInit || msg[6] == kStatusReauth) {
                        LOG(INFO) << "keyboard asked for authentication";
                        sendAuthStart();
                    }
                    break;
                case kCmdAuthStart:
                    if (avail >= 32) onKeyInfo(msg);
                    break;
                case kCmdChallenge:
                    if (avail >= 38 && msg[5] == 0x20) onChallenge(msg);
                    break;
            }
            i += size;
        }
    }

    // Keyboard UID and its two key metadata blocks.
    void onKeyInfo(const uint8_t* msg) {
        uid_.assign(msg + 8, msg + 8 + kUidSize);
        const uint8_t* meta1 = msg + 24;
        const uint8_t* meta2 = msg + 28;
        const uint8_t* meta = (meta1[0] & 0x40) ? meta2 : meta1;
        keyMeta_.assign(meta, meta + kKeyMetaSize);

        Bytes payload = keyMeta_;
        Bytes challenge(kChallengeSize);
        if (!android::base::ReadFully(random_, challenge.data(), challenge.size())) {
            PLOG(ERROR) << "cannot read a random challenge";
            return;
        }
        payload.insert(payload.end(), challenge.begin(), challenge.end());
        sendCommand(kCmdChallenge, payload);
    }

    // Keyboard token (ignored) followed by the keyboard's challenge to us.
    void onChallenge(const uint8_t* msg) {
        if (uid_.empty()) return;
        Bytes challenge(msg + 22, msg + 22 + kChallengeSize);
        Bytes token;
        auto status = service_->devauth_token_get(1, uid_, keyMeta_, challenge, &token);
        if (!status.isOk() || token.empty()) {
            LOG(ERROR) << "devauth_token_get failed: " << status.getDescription();
            return;
        }
        sendCommand(kCmdToken, token);
        LOG(INFO) << "keyboard authenticated";
    }

    unique_fd fd_;
    unique_fd random_{open("/dev/urandom", O_RDONLY | O_CLOEXEC)};
    std::shared_ptr<IMidevauthService> service_;
    Bytes uid_;
    Bytes keyMeta_;
};

}  // namespace

int main() {
    const std::string name = std::string(IMidevauthService::descriptor) + "/default";
    auto service = IMidevauthService::fromBinder(
            ndk::SpAIBinder(AServiceManager_waitForService(name.c_str())));
    if (!service) {
        LOG(ERROR) << "cannot get " << name;
        return 1;
    }

    unique_fd fd(open(kDevice, O_RDWR | O_CLOEXEC));
    if (!fd.ok()) {
        PLOG(ERROR) << "cannot open " << kDevice;
        return 1;
    }

    KeyboardAuth(std::move(fd), std::move(service)).run();
    return 1;
}
