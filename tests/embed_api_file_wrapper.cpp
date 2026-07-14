#include <byg/byg.hpp>

#include <cstdio>
#include <cstdint>
#include <iostream>
#include <string>
#include <vector>

static std::vector<std::uint8_t> make_payload(std::size_t n) {
    std::vector<std::uint8_t> out;
    out.reserve(n);
    std::uint32_t x = 0x12345678u;
    for (std::size_t i = 0; i < n; ++i) {
        x = (1103515245u * x + 12345u);
        std::uint8_t b = static_cast<std::uint8_t>((x >> 16) & 0xffu);
        if ((i % 97) < 64) b = static_cast<std::uint8_t>('A' + (i % 26));
        out.push_back(b);
    }
    return out;
}

static int check_roundtrip(const std::string& prefix, const std::vector<std::uint8_t>& raw) {
    const std::string raw_path = prefix + "_raw.bin";
    const std::string container_path = prefix + "_container.byg";
    const std::string restored_path = prefix + "_restored.bin";
    std::string err;
    if (!byg::write_file_bytes(raw_path, raw, &err)) {
        std::cerr << "write raw failed: " << err << "\n";
        return 10;
    }
    if (!byg::compress_file(raw_path, container_path, &err)) {
        std::cerr << "compress_file failed: " << err << "\n";
        return 11;
    }
    byg::InspectInfo info = byg::inspect_file(container_path);
    if (!info.ok) {
        std::cerr << "inspect_file failed: " << info.error << "\n";
        return 12;
    }
    if (info.format != byg::format_magic()) return 13;
    if (info.selected_backend != "BYG_STORED") return 14;
    if (info.payload_submode != "stored_raw") return 15;
    if (info.original_size != raw.size()) return 16;
    if (!byg::decompress_file(container_path, restored_path, &err)) {
        std::cerr << "decompress_file failed: " << err << "\n";
        return 17;
    }
    std::vector<std::uint8_t> restored;
    if (!byg::read_file_bytes(restored_path, restored, &err)) {
        std::cerr << "read restored failed: " << err << "\n";
        return 18;
    }
    if (restored != raw) return 19;
    std::remove(raw_path.c_str());
    std::remove(container_path.c_str());
    std::remove(restored_path.c_str());
    return 0;
}

int main() {
    std::vector<std::uint8_t> large = make_payload(256 * 1024);
    int rc = check_roundtrip("byg_file_wrapper_large", large);
    if (rc != 0) return rc;
    std::vector<std::uint8_t> empty;
    rc = check_roundtrip("byg_file_wrapper_empty", empty);
    if (rc != 0) return rc;

    byg::InspectInfo missing = byg::inspect_file("definitely_missing_byg_file_wrapper_input.bin");
    if (missing.ok) return 30;
    if (missing.error.find("open input failed") == std::string::npos) return 31;

    std::cout << "BYG_FILE_WRAPPER_SMOKE_OK\n";
    std::cout << "version=" << byg::version() << "\n";
    std::cout << "magic=" << byg::format_magic() << "\n";
    std::cout << "large_bytes=" << large.size() << "\n";
    std::cout << "file_wrapper_cases=3\n";
    return 0;
}
