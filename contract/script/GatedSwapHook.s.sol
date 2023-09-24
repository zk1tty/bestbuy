// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolModifyPositionTest} from "@uniswap/v4-core/contracts/test/PoolModifyPositionTest.sol";
import {PoolSwapTest} from "@uniswap/v4-core/contracts/test/PoolSwapTest.sol";
import {PoolDonateTest} from "@uniswap/v4-core/contracts/test/PoolDonateTest.sol";
import {HookMiner} from "../test/utils/HookMiner.sol";

import {GatedSwapHook} from "../src/GatedSwapHook.sol";
import {HookHelper} from "../src/HookHelper.sol";
import {SwapTest} from "../src/SwapTest.sol";

/// @notice Forge script for deploying v4 & hooks to **anvil**
/// @dev This script only works on an anvil RPC because v4 exceeds bytecode limits
contract GatedSwapHookScript is Script {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);
    address constant POOL_MANAGER_SEPOLIA = address(0x64255ed21366DB43d89736EE48928b890A84E2Cb);

    function setUp() public {}

    function run() public {
        vm.broadcast();

        // TODO: use the expiternal manager address.
        // PoolManager manager = new PoolManager(500000);
        address manager_addr;
        manager_addr = POOL_MANAGER_SEPOLIA;
        //---//                      

        // hook contracts must have specific flags encoded in the address
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_MODIFY_POSITION_FLAG
                | Hooks.AFTER_MODIFY_POSITION_FLAG
        );

        // Mine a salt that will produce a hook address with the correct flags
        (address hookAddress, bytes32 salt) = HookMiner.find(CREATE2_DEPLOYER, flags, 1000, type(GatedSwapHook).creationCode, abi.encode(manager_addr));

        // **Deploy** the hook using CREATE2
        vm.broadcast();
        GatedSwapHook gatedSwapHook = new GatedSwapHook{salt: salt}(IPoolManager(manager_addr));
        console.log("gatedSwapHook:%s", gatedSwapHook);
        require(address(gatedSwapHook) == hookAddress, "gatedSwapHookScript: hook address mismatch");

        vm.broadcast();
        SwapTest swapTest = new SwapTest(IPoolManager(manager_addr));
        console.log("swapTest:%s", swapTest);

        // Additional contracts for interacting with the pool
        vm.startBroadcast();
        // Callers: HookHelper is weraped with SwapTest!
        // helpers
        new PoolModifyPositionTest(IPoolManager(manager_addr));
        new PoolSwapTest(IPoolManager(manager_addr));
        new PoolDonateTest(IPoolManager(manager_addr));
        vm.stopBroadcast();
    }
}