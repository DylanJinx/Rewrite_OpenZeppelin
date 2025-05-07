//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Hashes {
    // 无论输入的顺序如何，结果都相同
    function commutativeKeccak256(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        return a < b ? efficientKeccak256(a, b) : efficientKeccak256(b, a);
    }

    function efficientKeccak256(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        assembly ("memory-safe") {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    function nonEfficientKeccak256(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        return keccak256(abi.encode(a, b));
        // return keccak256(abi.encodePacked(a, b));
        // encode 和 encodePacked的区别见readme
    }
}
