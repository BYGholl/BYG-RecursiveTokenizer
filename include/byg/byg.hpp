#pragma once

#include <cstddef>
#include <cstdint>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

namespace byg {

struct InspectInfo {
    bool ok = false;
    std::string error;
    std::string format;
    std::string selected_backend;
    std::string payload_submode;
    std::uint64_t original_size = 0;
    std::uint32_t checksum_fnv1a32 = 0;
    std::size_t header_size = 0;
    std::size_t payload_size = 0;
    std::size_t container_size = 0;
};

inline const char* version() noexcept {
    return "v4.6-real-dataset-benchmark-suite";
}

inline const char* format_magic() noexcept {
    return "BYG46DB";
}

inline std::uint32_t fnv1a32(const std::vector<std::uint8_t>& data) noexcept {
    std::uint32_t h = 2166136261u;
    for (std::uint8_t b : data) {
        h ^= static_cast<std::uint32_t>(b);
        h *= 16777619u;
    }
    return h;
}

inline void append_u64_le(std::vector<std::uint8_t>& out, std::uint64_t v) {
    for (int i = 0; i < 8; ++i) out.push_back(static_cast<std::uint8_t>((v >> (i * 8)) & 0xffu));
}

inline void append_u32_le(std::vector<std::uint8_t>& out, std::uint32_t v) {
    for (int i = 0; i < 4; ++i) out.push_back(static_cast<std::uint8_t>((v >> (i * 8)) & 0xffu));
}

inline bool read_u64_le(const std::vector<std::uint8_t>& in, std::size_t& pos, std::uint64_t& v) {
    if (pos + 8 > in.size()) return false;
    v = 0;
    for (int i = 0; i < 8; ++i) v |= (static_cast<std::uint64_t>(in[pos++]) << (i * 8));
    return true;
}

inline bool read_u32_le(const std::vector<std::uint8_t>& in, std::size_t& pos, std::uint32_t& v) {
    if (pos + 4 > in.size()) return false;
    v = 0;
    for (int i = 0; i < 4; ++i) v |= (static_cast<std::uint32_t>(in[pos++]) << (i * 8));
    return true;
}

inline std::vector<std::uint8_t> compress_bytes(const std::vector<std::uint8_t>& raw) {
    std::vector<std::uint8_t> out;
    const char* magic = format_magic();
    for (int i = 0; i < 7; ++i) out.push_back(static_cast<std::uint8_t>(magic[i]));
    out.push_back(2); // public header API v1 stores raw bytes deterministically.
    append_u64_le(out, static_cast<std::uint64_t>(raw.size()));
    append_u32_le(out, fnv1a32(raw));
    out.insert(out.end(), raw.begin(), raw.end());
    return out;
}

inline InspectInfo inspect_bytes(const std::vector<std::uint8_t>& container) {
    InspectInfo info;
    info.container_size = container.size();
    const std::string magic(format_magic(), format_magic() + 7);
    if (container.size() < 20) { info.error = "container too small"; return info; }
    std::string got(reinterpret_cast<const char*>(container.data()), 7);
    if (got != magic) { info.error = "bad magic"; return info; }
    std::size_t pos = 7;
    std::uint8_t backend = container[pos++];
    if (backend != 2) { info.error = "unsupported public-api backend"; return info; }
    std::uint64_t original_size = 0;
    std::uint32_t checksum = 0;
    if (!read_u64_le(container, pos, original_size)) { info.error = "bad original_size"; return info; }
    if (!read_u32_le(container, pos, checksum)) { info.error = "bad checksum"; return info; }
    if (container.size() - pos != original_size) { info.error = "payload size mismatch"; return info; }
    std::vector<std::uint8_t> payload(container.begin() + static_cast<std::ptrdiff_t>(pos), container.end());
    if (fnv1a32(payload) != checksum) { info.error = "checksum mismatch"; return info; }
    info.ok = true;
    info.format = magic;
    info.selected_backend = "BYG_STORED";
    info.payload_submode = "stored_raw";
    info.original_size = original_size;
    info.checksum_fnv1a32 = checksum;
    info.header_size = pos;
    info.payload_size = payload.size();
    return info;
}

inline bool decompress_bytes(const std::vector<std::uint8_t>& container, std::vector<std::uint8_t>& raw, std::string* error = nullptr) {
    InspectInfo info = inspect_bytes(container);
    if (!info.ok) {
        if (error) *error = info.error;
        return false;
    }
    raw.assign(container.begin() + static_cast<std::ptrdiff_t>(info.header_size), container.end());
    return true;
}

inline std::vector<std::uint8_t> decompress_bytes(const std::vector<std::uint8_t>& container) {
    std::vector<std::uint8_t> raw;
    std::string err;
    if (!decompress_bytes(container, raw, &err)) return {};
    return raw;
}


inline bool read_file_bytes(const std::string& path, std::vector<std::uint8_t>& out, std::string* error = nullptr) {
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        if (error) *error = "open input failed";
        return false;
    }
    out.assign(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
    if (in.bad()) {
        if (error) *error = "read input failed";
        out.clear();
        return false;
    }
    return true;
}

inline bool write_file_bytes(const std::string& path, const std::vector<std::uint8_t>& bytes, std::string* error = nullptr) {
    std::ofstream out(path, std::ios::binary);
    if (!out) {
        if (error) *error = "open output failed";
        return false;
    }
    if (!bytes.empty()) {
        out.write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
    }
    if (!out.good()) {
        if (error) *error = "write output failed";
        return false;
    }
    return true;
}

inline bool compress_file(const std::string& input_path, const std::string& output_path, std::string* error = nullptr) {
    std::vector<std::uint8_t> raw;
    if (!read_file_bytes(input_path, raw, error)) return false;
    std::vector<std::uint8_t> container = compress_bytes(raw);
    return write_file_bytes(output_path, container, error);
}

inline bool decompress_file(const std::string& input_path, const std::string& output_path, std::string* error = nullptr) {
    std::vector<std::uint8_t> container;
    if (!read_file_bytes(input_path, container, error)) return false;
    std::vector<std::uint8_t> raw;
    if (!decompress_bytes(container, raw, error)) return false;
    return write_file_bytes(output_path, raw, error);
}

inline InspectInfo inspect_file(const std::string& path) {
    std::vector<std::uint8_t> container;
    std::string err;
    if (!read_file_bytes(path, container, &err)) {
        InspectInfo info;
        info.error = err;
        return info;
    }
    return inspect_bytes(container);
}

} // namespace byg
