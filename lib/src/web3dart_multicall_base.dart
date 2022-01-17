import 'dart:typed_data';
import 'package:convert/convert.dart';

import 'package:web3dart/web3dart.dart';

import 'multicall2abi.dart';

class Web3MulticallCall {
  EthereumAddress target;
  ContractFunction function;
  List<dynamic> params;

  Web3MulticallCall(this.target, this.function, this.params);
}

class Web3MulticallResult {
  bool success;
  List<dynamic> returnData;

  Web3MulticallResult(this.success, this.returnData);
}

class AggregateResult {
  BigInt blockNumber;
  List<List<dynamic>> returnData;

  AggregateResult(this.blockNumber, this.returnData);
}

class BlockAggregateResult {
  BigInt blockNumber;
  String blockHash;
  List<Web3MulticallResult> results;

  BlockAggregateResult(this.blockNumber, this.blockHash, this.results);
}

class Web3Multicall {
  static final _address = {
    // Ethereum mainnet
    BigInt.from(1):
        EthereumAddress.fromHex("0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696"),
    // Ethereum testnet Kovan
    BigInt.from(42):
        EthereumAddress.fromHex("0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696"),
    // Ethereum testnet Rinkeby
    BigInt.from(4):
        EthereumAddress.fromHex("0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696"),
    // Ethereum testnet Görli
    BigInt.from(5):
        EthereumAddress.fromHex("0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696"),
    // Ethereum testnet Ropsten
    BigInt.from(3):
        EthereumAddress.fromHex("0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696"),

    // BSC mainnet
    BigInt.from(56):
        EthereumAddress.fromHex("0xed386Fe855C1EFf2f843B910923Dd8846E45C5A4"),
    // BSC testnet
    BigInt.from(97):
        EthereumAddress.fromHex("0xed386Fe855C1EFf2f843B910923Dd8846E45C5A4"),

    // HECO mainnet
    BigInt.from(128):
        EthereumAddress.fromHex("0x3D776858642919784d4EfC6192E39fA83cC7B028"),
    // HECO testnet
    BigInt.from(256):
        EthereumAddress.fromHex("0x2868Dbd253A3db600e23957cFb8ffecD3899d977"),

    // Polygon(Matic) mainnet
    BigInt.from(137):
        EthereumAddress.fromHex("0xed386Fe855C1EFf2f843B910923Dd8846E45C5A4"),
    // Polygon(Matic) testnet Mumbai
    BigInt.from(80001):
        EthereumAddress.fromHex("0xed386Fe855C1EFf2f843B910923Dd8846E45C5A4"),

    // Fantom mainnet
    BigInt.from(250):
        EthereumAddress.fromHex("0xD98e3dBE5950Ca8Ce5a4b59630a5652110403E5c"),
  };

  static setMulticallAddress(BigInt chainId, EthereumAddress address) {
    _address[chainId] = address;
  }

  static bool isSupported(BigInt chainId) {
    return _address.containsKey(chainId);
  }

  static Future<DeployedContract> getMulticallContractInstance(
      Web3Client client) async {
    final chanId = await client.getChainId();
    if (!_address.containsKey(chanId)) {
      throw Exception(
          "Can't find a deployed instance, please [setMulticallAddress] before you start");
    }
    return DeployedContract(contractAbi, _address[chanId]!);
  }

  static List<dynamic> _encodeCallData(List<Web3MulticallCall> calls) {
    final calldata = [];
    for (var call in calls) {
      calldata.add([call.target, call.function.encodeCall(call.params)]);
    }
    return calldata;
  }

  static List<List<dynamic>> _decodeReturnData(
      List<Web3MulticallCall> calls, List<dynamic> data) {
    final List<List<dynamic>> returnData = [];
    for (var i = 0; i < calls.length; i++) {
      returnData.add(calls[i]
          .function
          .decodeReturnValues(hex.encode((data[i] as Uint8List))));
    }
    return returnData;
  }

  static List<Web3MulticallResult> _decodeMulticallResult(
      List<Web3MulticallCall> calls, List<dynamic> returnData) {
    final List<Web3MulticallResult> results = [];
    for (var i = 0; i < calls.length; i++) {
      try {
        results.add(Web3MulticallResult(
            returnData[i].first,
            calls[i]
                .function
                .decodeReturnValues(hex.encode(returnData[i][1]))));
      } catch (e) {
        results.add(Web3MulticallResult(false, returnData[i][1]));
      }
    }
    return results;
  }

  static Future<List<dynamic>> _call(
      Web3Client client, List<Web3MulticallCall> calls, String functionName,
      {bool? requireSuccess}) async {
    final multicall = await getMulticallContractInstance(client);
    final function = multicall.function(functionName);

    final result = await client.call(
        contract: multicall,
        function: function,
        params: requireSuccess != null
            ? [requireSuccess, _encodeCallData(calls)]
            : [_encodeCallData(calls)]);
    return result;
  }

  static Future<AggregateResult> aggregate(
      Web3Client client, List<Web3MulticallCall> calls) async {
    final result = await _call(client, calls, "aggregate");
    final BigInt blockNumber = result[0];
    final List<List<dynamic>> returnData = _decodeReturnData(calls, result[1]);
    return AggregateResult(blockNumber, returnData);
  }

  static Future<BlockAggregateResult> blockAndAggregate(
      Web3Client client, List<Web3MulticallCall> calls) async {
    final result = await _call(client, calls, "blockAndAggregate");
    final BigInt blockNumber = result[0];
    final String blockHash = hex.encode(result[1]);
    final List<Web3MulticallResult> results =
        _decodeMulticallResult(calls, result[2]);
    return BlockAggregateResult(blockNumber, blockHash, results);
  }

  static Future<List<Web3MulticallResult>> tryAggregate(
    Web3Client client,
    bool requireSuccess,
    List<Web3MulticallCall> calls,
  ) async {
    final result = await _call(client, calls, "tryAggregate",
        requireSuccess: requireSuccess);
    return _decodeMulticallResult(calls, result.first);
  }

  static Future<BlockAggregateResult> tryBlockAndAggregate(Web3Client client,
      bool requireSuccess, List<Web3MulticallCall> calls) async {
    final result = await _call(client, calls, "tryBlockAndAggregate",
        requireSuccess: requireSuccess);
    final BigInt blockNumber = result[0];
    final String blockHash = hex.encode(result[1]);
    final List<Web3MulticallResult> results =
        _decodeMulticallResult(calls, result[2]);
    return BlockAggregateResult(blockNumber, blockHash, results);
  }
}
