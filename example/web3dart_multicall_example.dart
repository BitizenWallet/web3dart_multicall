import 'dart:developer';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart_multicall/web3dart_multicall.dart';

final apiUrl = "https://cloudflare-eth.com"; //Replace with your API

final httpClient = Client();
final ethClient = Web3Client(apiUrl, httpClient);

final prefix = '0x000000000000000000000000000000000000000';

final addressList = [];

final multicallAddr =
    EthereumAddress.fromHex('0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696');

late DeployedContract multicall;
late ContractFunction function;
late ContractFunction function1;

void main() async {
  for (var i = 0; i < 10; i++) {
    addressList.add(EthereumAddress.fromHex(prefix + i.toString()));
  }
  multicall = await Web3Multicall.getMulticallContractInstance(ethClient);
  function = multicall.function("getEthBalance");
  function1 = multicall.function("getCurrentBlockCoinbase");

  await tryBlockAndAggregateDemo();
  await tryAggregateDemo();
  await aggregateDemo();
  await aggregateFailedDemo();
}

Future<void> aggregateDemo() async {
  final List<Web3MulticallCall> calls = [];
  for (var i = 0; i < addressList.length; i++) {
    calls.add(Web3MulticallCall(multicallAddr, function, [addressList[i]]));
    calls.add(Web3MulticallCall(multicallAddr, function1, []));
  }

  final result = await Web3Multicall.aggregate(ethClient, calls);
  for (var i = 0; i < calls.length; i++) {
    final addr = addressList[i ~/ 2].toString();
    final balance = EtherAmount.inWei(result.returnData[i].first as BigInt)
        .getInEther
        .toString();
    final next = ++i;
    final coinbase =
        (result.returnData[next].first as EthereumAddress).toString();
    log("address $addr, balance $balance, coinbase $coinbase");
  }
}

Future<void> tryAggregateDemo() async {
  final List<Web3MulticallCall> calls = [];
  for (var i = 0; i < addressList.length; i++) {
    calls.add(Web3MulticallCall(multicallAddr, function, [addressList[i]]));
    calls.add(Web3MulticallCall(
        i % 2 == 0
            ? EthereumAddress.fromHex(
                "0xB8c77482e45F1F44dE1745F52C74426C631bDD52")
            : multicallAddr,
        function1,
        []));
  }

  final result = await Web3Multicall.tryAggregate(ethClient, true, calls);
  for (var i = 0; i < calls.length; i++) {
    final addr = addressList[i ~/ 2].toString();
    final balance = EtherAmount.inWei(result[i].returnData.first as BigInt)
        .getInEther
        .toString();
    final next = ++i;
    var coinbase = 'failed';
    try {
      coinbase = (result[next].returnData.first as EthereumAddress).toString();
    } catch (e) {
      log("${result[next].returnData}");
    }
    log("address $addr, success ${result[next].success}, balance $balance, coinbase $coinbase");
  }
}

Future<void> tryBlockAndAggregateDemo() async {
  final List<Web3MulticallCall> calls = [];
  for (var i = 0; i < addressList.length; i++) {
    calls.add(Web3MulticallCall(multicallAddr, function, [addressList[i]]));
    calls.add(Web3MulticallCall(
        i % 2 == 0
            ? EthereumAddress.fromHex(
                "0xB8c77482e45F1F44dE1745F52C74426C631bDD52")
            : multicallAddr,
        function1,
        []));
  }

  final result =
      await Web3Multicall.tryBlockAndAggregate(ethClient, true, calls);
  for (var i = 0; i < calls.length; i++) {
    final addr = addressList[i ~/ 2].toString();
    final balance =
        EtherAmount.inWei(result.results[i].returnData.first as BigInt)
            .getInEther
            .toString();
    final next = ++i;
    var coinbase = 'failed';
    try {
      coinbase =
          (result.results[next].returnData.first as EthereumAddress).toString();
    } catch (e) {
      log("${result.results[next].returnData}");
    }
    log("address $addr, success ${result.results[next].success}, blockHash ${result.blockHash}, balance $balance, coinbase $coinbase");
  }
}

Future<void> aggregateFailedDemo() async {
  final List<Web3MulticallCall> calls = [];
  for (var i = 0; i < addressList.length; i++) {
    calls.add(Web3MulticallCall(multicallAddr, function, [addressList[i]]));
    calls.add(Web3MulticallCall(
        i % 2 == 0
            ? EthereumAddress.fromHex(
                "0xB8c77482e45F1F44dE1745F52C74426C631bDD52")
            : multicallAddr,
        function1,
        []));
  }

  final result = await Web3Multicall.aggregate(ethClient, calls);
  for (var i = 0; i < calls.length; i++) {
    final addr = addressList[i ~/ 2].toString();
    final balance = EtherAmount.inWei(result.returnData[i].first as BigInt)
        .getInEther
        .toString();
    final next = ++i;
    final coinbase =
        (result.returnData[next].first as EthereumAddress).toString();
    log("address $addr, balance $balance, coinbase $coinbase");
  }
}
