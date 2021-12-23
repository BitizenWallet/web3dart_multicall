# Web3dart Multicall

Multicall implementation of web3dart

## Usage

Longer examples to `/example` folder.

```dart
final apiUrl = "https://cloudflare-eth.com"; //Replace with your API

final httpClient = Client();
final ethClient = Web3Client(apiUrl, httpClient);
final prefix = '0x000000000000000000000000000000000000000';
final addressList = [];
for (var i = 0; i < 10; i++) {
    addressList.add(EthereumAddress.fromHex(prefix + i.toString()));
}
final multicallAddr =
    EthereumAddress.fromHex('0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696');
final multicall = await Web3Multicall.getMulticallContractInstance(ethClient);
final function = multicall.function("getEthBalance");
final function1 = multicall.function("getCurrentBlockCoinbase");

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
```
