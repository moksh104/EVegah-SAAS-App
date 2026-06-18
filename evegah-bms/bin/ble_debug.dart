import 'dart:convert';
import '../lib/app/core/ble/ble_decoder.dart';

void main() {
  // Example RX payload (one of the repeated lines you provided)
  const hex =
      'd2037c01360e740001000d0000000000040000000000010e101036109a0af00a8c0215022201720165735072d87710778800640069000a00050069006e000a000501f40320000a000f0f3c003200010001014100575430304b5f3231383034325f31310000463930335f453330315f312e32480000323032343131303900009ed8';

  final parsed = BleDecoder.parse(hex);
  print(JsonEncoder.withIndent('  ').convert(parsed));
}
