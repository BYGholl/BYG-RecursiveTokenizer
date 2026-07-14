#include <byg/byg.hpp>

#include <cstdint>
#include <iostream>
#include <string>
#include <vector>

int main() {
    std::string text = "BYG v4.6 public header embedding API smoke payload.";
    std::vector<std::uint8_t> raw(text.begin(), text.end());
    std::vector<std::uint8_t> container = byg::compress_bytes(raw);
    byg::InspectInfo info = byg::inspect_bytes(container);
    if (!info.ok) {
        std::cerr << "inspect failed: " << info.error << "\n";
        return 2;
    }
    if (info.format != byg::format_magic()) return 3;
    if (info.selected_backend != "BYG_STORED") return 4;
    if (info.payload_submode != "stored_raw") return 5;
    if (info.original_size != raw.size()) return 6;
    std::vector<std::uint8_t> restored;
    std::string err;
    if (!byg::decompress_bytes(container, restored, &err)) {
        std::cerr << "decompress failed: " << err << "\n";
        return 7;
    }
    if (restored != raw) return 8;
    if (std::string(byg::version()).find("v4.6-real-dataset-benchmark-suite") == std::string::npos) return 9;
    std::cout << "BYG_LIBRARY_API_SMOKE_OK\n";
    std::cout << "version=" << byg::version() << "\n";
    std::cout << "magic=" << byg::format_magic() << "\n";
    std::cout << "container_size=" << container.size() << "\n";
    return 0;
}
