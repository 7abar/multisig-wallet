// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract DeployMultiSig is Script {
    function run() external {
        address[] memory owners = new address[](3);
        owners[0] = vm.envAddress("OWNER_1");
        owners[1] = vm.envAddress("OWNER_2");
        owners[2] = vm.envAddress("OWNER_3");
        uint256 required = vm.envUint("REQUIRED");

        vm.startBroadcast();
        MultiSigWallet wallet = new MultiSigWallet(owners, required);
        console.log("MultiSigWallet deployed:", address(wallet));
        vm.stopBroadcast();
    }
}
