import 'dart:typed_data';

import 'package:agent_dart/agent/cbor.dart';
import 'package:agent_dart/agent/types.dart';
import 'package:agent_dart/agent/utils/leb128.dart';
import 'package:cbor/cbor.dart' as cbor;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:typed_data/typed_data.dart';

import 'types.dart';

// ignore: non_constant_identifier_names
final NANOSECONDS_PER_MILLISECONDS = BigInt.from(1000000);

// ignore: non_constant_identifier_names
final REPLICA_PERMITTED_DRIFT_MILLISECONDS = BigInt.from(60 * 1000);

class Expiry extends ToCBorable {
  late BigInt _value;

  BigInt get value => _value;

  Expiry(int deltaInMSec) {
    // Use bigint because it can overflow the maximum number allowed in a double float.
    _value = (BigInt.from(DateTime.now().millisecondsSinceEpoch) +
            BigInt.from(deltaInMSec) -
            REPLICA_PERMITTED_DRIFT_MILLISECONDS) *
        NANOSECONDS_PER_MILLISECONDS;
  }

  Uint8List toHash() {
    return lebEncode(_value);
  }

  @override
  void write(cbor.Encoder encoder) {
    if (kIsWeb) {
      var data = serializeValue(0, 27, _value.toRadixString(16));
      var buf = Uint8Buffer();
      buf.addAll(data.asUint8List());
      encoder.addBuilderOutput(buf);
    } else {
      encoder.writeInt(_value.toInt());
    }
  }
}

HttpAgentRequestTransformFnCall makeNonceTransform(
    [NonceFunc nonceFn = makeNonce]) {
  return (HttpAgentBaseRequest request) async {
    // Print the request object and its type
    print('Request: $request');
    print('Type of request: ${request.runtimeType}');

    // Compare runtimeType to 'HttpAgentSubmitRequest'
    if (request.runtimeType.toString() == 'HttpAgentSubmitRequest') {
      print('Request is a submit request');
      (request as HttpAgentSubmitRequest).body.nonce = nonceFn();
      print((request as HttpAgentSubmitRequest).body.nonce);
    }
  };
}

typedef NonceFunc = Nonce Function();
