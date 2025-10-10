// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Test} from "forge-std/Test.sol";
import {WadRayMath} from "../src/protocol/libraries/math/WadRayMath.sol";
import {PercentageMath} from "../src/protocol/libraries/math/PercentageMath.sol";

contract MinimalistMathTest is Test {
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    function test_WadMath() public {
        uint256 a = 2 * WadRayMath.WAD;
        uint256 b = 3 * WadRayMath.WAD;
        uint256 result = a.wadMul(b);
        assertEq(result, 6 * WadRayMath.WAD);

        uint256 divResult = result.wadDiv(a);
        assertEq(divResult, b);
    }

    function test_RayMath() public {
        uint256 a = 2 * WadRayMath.RAY;
        uint256 b = 3 * WadRayMath.RAY;
        uint256 result = a.rayMul(b);
        assertEq(result, 6 * WadRayMath.RAY);

        uint256 divResult = result.rayDiv(a);
        assertEq(divResult, b);
    }

    function test_PercentageMath() public {
        uint256 value = 1000;
        uint256 percentage = 2500; // 25%

        uint256 result = value.percentMul(percentage);
        assertEq(result, 250);

        uint256 divResult = result.percentDiv(percentage);
        assertEq(divResult, value);
    }

    function test_Constants() public {
        assertEq(WadRayMath.WAD, 1e18);
        assertEq(WadRayMath.RAY, 1e27);
        assertEq(PercentageMath.PERCENTAGE_FACTOR, 10000);
    }

    function test_Conversions() public {
        uint256 wadValue = 1.5e18;
        uint256 rayValue = wadValue.wadToRay();
        assertEq(rayValue, 1.5e27);

        uint256 backToWad = rayValue.rayToWad();
        assertEq(backToWad, wadValue);
    }
}
