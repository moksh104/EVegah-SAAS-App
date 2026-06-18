import 'dart:convert';
import 'dart:typed_data';

class BleDecoder {
  static List<int> hexToBytes(String hex) {
    hex = hex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  static String _utf16leFromBytes(List<int> bytes) {
    final codeUnits = <int>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      codeUnits.add(bytes[i] | (bytes[i + 1] << 8));
    }
    return String.fromCharCodes(codeUnits).trim();
  }

  /// Parse a BLE payload hex string and return a map of discovered fields.
  /// This is a heuristic parser intended to be adapted once the device
  /// protocol documentation is available.
  static Map<String, dynamic> parse(String hex) {
    final b = hexToBytes(hex);
    final bd = ByteData.sublistView(Uint8List.fromList(b));
    final out = <String, dynamic>{};

    out['raw'] = hex;
    out['length'] = b.length;

    // Example numeric reads (little-endian)
    int readUint16LE(int offset) => bd.getUint16(offset, Endian.little);
    int readUint32LE(int offset) => bd.getUint32(offset, Endian.little);

    if (b.length >= 6) {
      out['u16_0'] = readUint16LE(0);
      out['u8_2'] = b[2];
      out['u32_4'] = (b.length >= 8) ? readUint32LE(4) : null;
    }

    // Scan for UTF-16LE null-terminated strings
    final strings = <String>[];
    for (var i = 0; i < b.length - 1; i++) {
      // heuristic: valid UTF-16LE often contains ASCII bytes with 0x00 padding
      if (b[i + 1] == 0x00) {
        final buf = <int>[];
        while (i < b.length - 1 && !(b[i] == 0x00 && b[i + 1] == 0x00)) {
          buf.add(b[i]);
          buf.add(b[i + 1]);
          i += 2;
        }
        if (buf.isNotEmpty) {
          try {
            final s = _utf16leFromBytes(buf);
            if (s.isNotEmpty) strings.add(s);
          } catch (_) {}
        }
      }
    }
    out['utf16le_strings'] = strings;

    // ASCII chunks fallback
    final asciiChunks = <String>[];
    final ascii = <int>[];
    for (var j = 0; j < b.length; j++) {
      if (b[j] >= 0x20 && b[j] <= 0x7e) {
        ascii.add(b[j]);
      } else {
        if (ascii.isNotEmpty) {
          asciiChunks.add(String.fromCharCodes(ascii));
          ascii.clear();
        }
      }
    }
    if (ascii.isNotEmpty) asciiChunks.add(String.fromCharCodes(ascii));
    out['ascii_chunks'] = asciiChunks;

    // CRC / trailer guess: last two bytes
    if (b.length >= 2) {
      out['trailer_crc'] = b
          .sublist(b.length - 2)
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join();
    }

    return out;
  }
}
