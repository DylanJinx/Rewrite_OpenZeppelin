// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../src/Hashes.sol";

contract HashesTest is Test {
    bytes32 constant BYTES32_ZERO = bytes32(0);
    bytes32 constant BYTES32_ONE = bytes32(uint256(1));
    bytes32 constant BYTES32_MAX = bytes32(type(uint256).max);
    
    address constant TEST_ADDRESS_1 = 0x1234567890123456789012345678901234567890;
    address constant TEST_ADDRESS_2 = 0xABcdEFABcdEFabcdEfAbCdefabcdeFABcDEFabCD;
    
    string constant TEST_STRING_1 = "Hello, Foundry!";
    string constant TEST_STRING_2 = "Testing Hashes library";
    
    bytes constant TEST_BYTES_1 = "raw bytes data 1";
    bytes constant TEST_BYTES_2 = "another bytes value";

    function setUp() public {

    }

    function testCommutativeProperty() public pure {
        // 测试不同顺序的输入产生相同的哈希结果
        bytes32 a = BYTES32_ONE;
        bytes32 b = BYTES32_MAX;
        
        bytes32 result1 = Hashes.commutativeKeccak256(a, b);
        bytes32 result2 = Hashes.commutativeKeccak256(b, a);
        
        assertEq(result1, result2, "commutativeKeccak256 should return same value regardless of input order");
    }

    function testEfficientVsNonEfficientKeccak256() public pure {
        // 测试高效和非高效实现的输出一致性
        bytes32 a = BYTES32_ONE;
        bytes32 b = BYTES32_MAX;
        
        bytes32 efficientResult = Hashes.efficientKeccak256(a, b);
        bytes32 nonEfficientResult = Hashes.nonEfficientKeccak256(a, b);
        
        assertEq(efficientResult, nonEfficientResult, "Both implementations should produce the same hash");
    }

    function testWithUintValues() public pure {
        // 用uint256值测试
        uint256 uintA = 1;
        uint256 uintB = 2;
        
        bytes32 a = bytes32(uintA);
        bytes32 b = bytes32(uintB);
        
        // 测试交换性
        bytes32 result1 = Hashes.commutativeKeccak256(a, b);
        bytes32 result2 = Hashes.commutativeKeccak256(b, a);
        assertEq(result1, result2, "Should be commutative with uint values");
        
        // 测试实现一致性
        bytes32 efficientResult = Hashes.efficientKeccak256(a, b);
        bytes32 nonEfficientResult = Hashes.nonEfficientKeccak256(a, b);
        assertEq(efficientResult, nonEfficientResult, "Both implementations should match with uint values");
    }
    
    function testWithAddresses() public pure {
        // 用地址值测试
        bytes32 a = bytes32(uint256(uint160(TEST_ADDRESS_1)));
        bytes32 b = bytes32(uint256(uint160(TEST_ADDRESS_2)));
        
        // 测试交换性
        bytes32 result1 = Hashes.commutativeKeccak256(a, b);
        bytes32 result2 = Hashes.commutativeKeccak256(b, a);
        assertEq(result1, result2, "Should be commutative with address values");
        
        // 测试实现一致性
        bytes32 efficientResult = Hashes.efficientKeccak256(a, b);
        bytes32 nonEfficientResult = Hashes.nonEfficientKeccak256(a, b);
        assertEq(efficientResult, nonEfficientResult, "Both implementations should match with address values");
    }
    
    function testWithStrings() public pure {
        // 用字符串值测试
        bytes32 a = keccak256(abi.encodePacked(TEST_STRING_1));
        bytes32 b = keccak256(abi.encodePacked(TEST_STRING_2));
        
        // 测试交换性
        bytes32 result1 = Hashes.commutativeKeccak256(a, b);
        bytes32 result2 = Hashes.commutativeKeccak256(b, a);
        assertEq(result1, result2, "Should be commutative with string-derived values");
        
        // 测试实现一致性
        bytes32 efficientResult = Hashes.efficientKeccak256(a, b);
        bytes32 nonEfficientResult = Hashes.nonEfficientKeccak256(a, b);
        assertEq(efficientResult, nonEfficientResult, "Both implementations should match with string-derived values");
    }
    
    function testWithBytes() public pure {
        // 用bytes值测试
        bytes32 a = keccak256(TEST_BYTES_1);
        bytes32 b = keccak256(TEST_BYTES_2);
        
        // 测试交换性
        bytes32 result1 = Hashes.commutativeKeccak256(a, b);
        bytes32 result2 = Hashes.commutativeKeccak256(b, a);
        assertEq(result1, result2, "Should be commutative with bytes-derived values");
        
        // 测试实现一致性
        bytes32 efficientResult = Hashes.efficientKeccak256(a, b);
        bytes32 nonEfficientResult = Hashes.nonEfficientKeccak256(a, b);
        assertEq(efficientResult, nonEfficientResult, "Both implementations should match with bytes-derived values");
    }
    
    function testEdgeCases() public pure {
        // 测试边缘情况 - 相同值
        bytes32 a = BYTES32_ONE;
        
        bytes32 result = Hashes.commutativeKeccak256(a, a);
        bytes32 efficientResult = Hashes.efficientKeccak256(a, a);
        bytes32 nonEfficientResult = Hashes.nonEfficientKeccak256(a, a);
        
        assertEq(result, efficientResult, "commutativeKeccak256 should match efficientKeccak256 with identical inputs");
        assertEq(efficientResult, nonEfficientResult, "Both implementations should match with identical inputs");
        
        // 测试边缘情况 - 零值
        bytes32 zero = BYTES32_ZERO;
        bytes32 nonZero = BYTES32_ONE;
        
        bytes32 resultWithZero = Hashes.commutativeKeccak256(zero, nonZero);
        bytes32 efficientResultWithZero = Hashes.efficientKeccak256(zero, nonZero);
        bytes32 nonEfficientResultWithZero = Hashes.nonEfficientKeccak256(zero, nonZero);
        
        assertEq(resultWithZero, efficientResultWithZero, "commutativeKeccak256 should match efficientKeccak256 with zero input");
        assertEq(efficientResultWithZero, nonEfficientResultWithZero, "Both implementations should match with zero input");
    }

    function testEncodingDifferenceWithNonBytes32Types() public pure {
        // 测试用uint128类型
        uint128 valueA = 123456;
        uint128 valueB = 789012;

        bytes memory encoded = abi.encode(valueA, valueB);

        bytes memory encodedPacked = abi.encodePacked(valueA, valueB);

        assertFalse(
            keccak256(encoded) == keccak256(encodedPacked),
            "encode and encodePacked should produce different results for uint128"
        );

        // 打印长度差异
        console.log("abi.encode length:", encoded.length);
        console.log("abi.encodePacked length:", encodedPacked.length);

        // 测试字符串类型
        string memory strA = "test";
        string memory strB = "string";
        
        bytes memory encodedStr = abi.encode(strA, strB);
        bytes memory encodedPackedStr = abi.encodePacked(strA, strB);
        
        // 验证字符串编码也会产生不同结果
        assertFalse(
            keccak256(encodedStr) == keccak256(encodedPackedStr),
            "encode and encodePacked should produce different results for strings"
        );
        
        console.log("String abi.encode length:", encodedStr.length);
        console.log("String abi.encodePacked length:", encodedPackedStr.length);

        bytes32 keccak256Encode = keccak256(abi.encode(valueA, valueB));
        bytes32 keccak256EncodePacked = keccak256(abi.encodePacked(valueA, valueB));
        
        console.log("Hash with abi.encode:", uint256(keccak256Encode));
        console.log("Hash with abi.encodePacked:", uint256(keccak256EncodePacked));
    }
}