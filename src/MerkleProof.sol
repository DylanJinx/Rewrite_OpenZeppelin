// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Hashes} from "./Hashes.sol";

library MerkleProof {
    error MerkleProofInvalidMultiproof();

    // 如果“叶子”可以被证明是由“根”定义的默克尔树的一部分，则返回true。
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
    * 从叶子节点开始，通过证明路径重建 Merkle 根：
    * - 从叶子节点开始
    * - 对于证明中的每个元素，计算当前哈希值和证明元素的哈希
    * - 继续这个过程，直到处理完所有证明元素
    * - 返回计算出的根哈希
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = Hashes.commutativeKeccak256(computedHash, proof[i]);
        }

        return computedHash;
    }

    /**
    * - pure：函数体内不能读取或修改任何合约状态，连 msg.sender、区块号等区块链环境变量也不能访问。
    * - view：函数体内只能读取合约状态（或读取区块链环境变量），但不能修改它。
    *
    * 当使用像 keccak256 这类内置函数或库函数时，一般只是在函数内部做纯粹的计算（无状态访问），所以可以声明为 pure。
    * 
    * 但是，当把哈希逻辑抽象为可传入的函数指针（比如 function(bytes32, bytes32) view returns (bytes32) hasher）时，编译器并不知道这个 hasher 里面会不会读取合约状态。它只看到：
    * 这是一个 function(...) view returns (...) 形式的参数，意味着调用时允许读取状态。
    * 因此， processMultiProof(...) 函数本身就必须至少是 view，以表示**“我可能会通过 hasher 访问合约存储或区块链环境信息”**。这就导致它无法再保持为 pure。
    */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = Hashes.commutativeKeccak256(computedHash, proof[i]);
        }

        return computedHash;
    }

    // 自定义哈希算法
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bool) {
        return processProof(proof, leaf, hasher) ==root;
    }

    function processProof(
        bytes32[] memory proof,
        bytes32 leaf,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = hasher(computedHash, proof[i]);
        }

        return computedHash;
    }

    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bool) {
        return processProofCalldata(proof, leaf, hasher) == root;
    }

    function processProofCalldata(
        bytes32[] calldata proof,
        bytes32 leaf,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = hasher(computedHash, proof[i]);
        }

        return computedHash;
    }

    // 多重证明
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        uint256 leavesLen = leaves.length;
        uint256 proofFlagsLen = proofFlags.length;

        if (proofFlagsLen != leavesLen + proof.length - 1) {
            revert MerkleProofInvalidMultiproof();
        }

        bytes32[] memory hashes = new bytes32[](proofFlagsLen);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;

        for (uint256 i = 0; i < proofFlagsLen; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]) : proof[proofPos++];

            hashes[i] = Hashes.commutativeKeccak256(a, b);
        }

        if (proofFlagsLen > 0) {
            // 要确保 proofPos 已经用完全部 proof， 说明没有多也没有少
            if (proofPos != proof.length) {
                revert MerkleProofInvalidMultiproof();
            }

            // 返回最终 hashes[proofFlagslen - 1]这一项，就是组合出来的根
            return hashes[proofFlagsLen - 1];
        } else if (leavesLen > 0) {
            // 如果没有 proofFlags，但有叶子，那么直接返回叶子[0] （说明只有一个叶子可被视为根）
            return leaves[0];
        } else {
            // 如果既没有 proofFlags，也没有叶子，那么返回 proof[0]
            // 注释里提到：这是一个“空集合”的特殊情况，也会被当作“合法”
            return proof[0];
        }
    }

    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bool) {
        return processMultiProof(proof, proofFlags, leaves, hasher) == root;
    }

    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bytes32 merkleRoot) {
        uint256 leavesLen = leaves.length;
        uint256 proofFlagsLen = proofFlags.length;

        if (proofFlagsLen != leavesLen + proof.length - 1) {
            revert MerkleProofInvalidMultiproof();
        }

        bytes32[] memory hashes = new bytes32[](proofFlagsLen);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;

        for (uint256 i = 0; i < proofFlagsLen; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]) : proof[proofPos++];

            hashes[i] = hasher(a, b);
        }

        if (proofFlagsLen > 0) {
            if (proofPos != proof.length) {
                revert MerkleProofInvalidMultiproof();
            }

            return hashes[proofFlagsLen - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    // calldata
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        uint256 leavesLen = leaves.length;
        uint256 proofFlagsLen = proofFlags.length;

        if (proofFlagsLen != leavesLen + proof.length - 1) {
            revert MerkleProofInvalidMultiproof();
        }

        bytes32[] memory hashes = new bytes32[](proofFlagsLen);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;

        for (uint256 i = 0; i < proofFlagsLen; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]) : proof[proofPos++];

            hashes[i] = Hashes.commutativeKeccak256(a, b);
        }

        if (proofFlagsLen > 0) {
            // 要确保 proofPos 已经用完全部 proof， 说明没有多也没有少
            if (proofPos != proof.length) {
                revert MerkleProofInvalidMultiproof();
            }

            // 返回最终 hashes[proofFlagslen - 1]这一项，就是组合出来的根
            return hashes[proofFlagsLen - 1];
        } else if (leavesLen > 0) {
            // 如果没有 proofFlags，但有叶子，那么直接返回叶子[0] （说明只有一个叶子可被视为根）
            return leaves[0];
        } else {
            // 如果既没有 proofFlags，也没有叶子，那么返回 proof[0]
            // 注释里提到：这是一个“空集合”的特殊情况，也会被当作“合法”
            return proof[0];
        }
    }

    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bool) {
        return processMultiProof(proof, proofFlags, leaves, hasher) == root;
    }

    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves,
        function(bytes32, bytes32) view returns (bytes32) hasher
    ) internal view returns (bytes32 merkleRoot) {
        uint256 leavesLen = leaves.length;
        uint256 proofFlagsLen = proofFlags.length;

        if (proofFlagsLen != leavesLen + proof.length - 1) {
            revert MerkleProofInvalidMultiproof();
        }

        bytes32[] memory hashes = new bytes32[](proofFlagsLen);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;

        for (uint256 i = 0; i < proofFlagsLen; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]) : proof[proofPos++];

            hashes[i] = hasher(a, b);
        }

        if (proofFlagsLen > 0) {
            if (proofPos != proof.length) {
                revert MerkleProofInvalidMultiproof();
            }

            return hashes[proofFlagsLen - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }
}
