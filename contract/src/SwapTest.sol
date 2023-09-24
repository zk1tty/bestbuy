// Ref: Counter.sol 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {HookHelper} from "./HookHelper.sol";
import {Counter} from "../src/Counter.sol";
import {HookMiner} from "../test/utils/HookMiner.sol";

contract SwapTest is HookHelper, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    address manager_addr;
    Counter counter;
    PoolKey poolKey;
    PoolId poolId;

    constructor(IPoolManager _poolManager) HookHelper(_poolManager) {
        manager_addr = address(_poolManager);
    }

    function setUp() public {
        
        // creates the pool manager, test tokens, and other utility routers
        HookHelper.initSwapHelper();

        // Deploy the hook to an address with the correct flags
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_MODIFY_POSITION_FLAG
                | Hooks.AFTER_MODIFY_POSITION_FLAG
        );
        (address hookAddress, bytes32 salt) = HookMiner.find(address(this), flags, 0, type(Counter).creationCode, abi.encode(address(manager)));
        counter = new Counter{salt: salt}(IPoolManager(manager_addr));
        require(address(counter) == hookAddress, "CounterTest: hook address mismatch");

        // Create the pool
        poolKey = PoolKey(Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, IHooks(counter));
        poolId = poolKey.toId();
        manager.initialize(poolKey, SQRT_RATIO_1_1, ZERO_BYTES);

        // Provide liquidity to the pool
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-60, 60, 10 ether));
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-120, 120, 10 ether));
        modifyPositionRouter.modifyPosition(
            poolKey, IPoolManager.ModifyPositionParams(TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10 ether)
        );
    }

    function callSwapHooks(int256 amount) public {
        // positions were created in setup()
        // assertEq(counter.beforeModifyPositionCount(), 3);
        // assertEq(counter.afterModifyPositionCount(), 3);

        // assertEq(counter.beforeSwapCount(), 0);
        // assertEq(counter.afterSwapCount(), 0);

        // Let's perform a test swap! //
        bool zeroForOne = true;
        swap(poolKey, amount, zeroForOne);
        // ------------------- //

        // assertEq(counter.beforeSwapCount(), 1);
        // assertEq(counter.afterSwapCount(), 1);
    }
}