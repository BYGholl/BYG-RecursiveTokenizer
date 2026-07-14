#include <byg/byg.hpp>

#include <cstdint>
#include <iostream>
#include <string>
#include <vector>

static bool contains(const std::string& haystack, const std::string& needle) {
    return haystack.find(needle) != std::string::npos;
}

static int expect_inspect_fail(const std::vector<std::uint8_t>& container, const std::string& expected_error) {
    try {
        byg::InspectInfo info = byg::inspect_bytes(container);
        if (info.ok) {
            std::cerr << "unexpected inspect success for " << expected_error << "\n";
            return 10;
        }
        if (!contains(info.error, expected_error)) {
            std::cerr << "unexpected inspect error: " << info.error << " expected " << expected_error << "\n";
            return 11;
        }
        std::vector<std::uint8_t> raw;
        std::string err;
        if (byg::decompress_bytes(container, raw, &err)) {
            std::cerr << "unexpected decompress success for " << expected_error << "\n";
            return 12;
        }
        if (!contains(err, expected_error)) {
            std::cerr << "unexpected decompress error: " << err << " expected " << expected_error << "\n";
            return 13;
        }
    } catch (const std::exception& ex) {
        std::cerr << "exception escaped API negative path: " << ex.what() << "\n";
        return 14;
    } catch (...) {
        std::cerr << "unknown exception escaped API negative path\n";
        return 15;
    }
    return 0;
}

int main() {
    std::string text = "BYG v4.6 negative API error contract payload.";
    std::vector<std::uint8_t> raw(text.begin(), text.end());
    std::vector<std::uint8_t> valid = byg::compress_bytes(raw);
    if (valid.size() < 21) return 2;

    int rc = expect_inspect_fail({}, "container too small");
    if (rc != 0) return rc;

    std::vector<std::uint8_t> bad_magic = valid;
    const char replacement[7] = {'B','A','D','M','A','G','C'};
    for (int i = 0; i < 7; ++i) bad_magic[static_cast<std::size_t>(i)] = static_cast<std::uint8_t>(replacement[i]);
    rc = expect_inspect_fail(bad_magic, "bad magic");
    if (rc != 0) return rc;

    std::vector<std::uint8_t> unsupported_backend = valid;
    unsupported_backend[7] = 4;
    rc = expect_inspect_fail(unsupported_backend, "unsupported public-api backend");
    if (rc != 0) return rc;

    std::vector<std::uint8_t> truncated = valid;
    truncated.pop_back();
    rc = expect_inspect_fail(truncated, "payload size mismatch");
    if (rc != 0) return rc;

    std::vector<std::uint8_t> checksum_bad = valid;
    checksum_bad.back() ^= 0x55u;
    rc = expect_inspect_fail(checksum_bad, "checksum mismatch");
    if (rc != 0) return rc;

    std::cout << "BYG_API_NEGATIVE_SMOKE_OK\n";
    std::cout << "version=" << byg::version() << "\n";
    std::cout << "magic=" << byg::format_magic() << "\n";
    std::cout << "negative_cases=5\n";
    return 0;
}
