// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MerkleProof} from "../src/MerkleProof.sol";
import {Hashes} from "../src/Hashes.sol";

contract MerkleProofTest is Test {
    // leaves
    bytes32 internal leaf1;
    bytes32 internal leaf2;
    bytes32 internal leaf3;
    bytes32 internal leaf4;

    // 中间节点
    bytes32 internal node12;
    bytes32 internal node34;

    // root
    bytes32 internal root;

    // 构建merkle tree
    function setUp() public {
        leaf1 = keccak256(abi.encodePacked("leaf1"));
        leaf2 = keccak256(abi.encodePacked("leaf2"));
        leaf3 = keccak256(abi.encodePacked("leaf3"));
        leaf4 = keccak256(abi.encodePacked("leaf4"));

        node12 = Hashes.commutativeKeccak256(leaf1, leaf2);
        node34 = Hashes.commutativeKeccak256(leaf3, leaf4);
        root = Hashes.commutativeKeccak256(node12, node34);
    }

    function testVerifyLeaf1Success() public view {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = leaf2;
        proof[1] = node34;

        bool verified = MerkleProof.verify(proof, root, leaf1);
        assertTrue(verified, "Leaf 1 should be verified successfully");
    }

    function testVerifyLeaf1FailWrongProof() public view {
        bytes32[] memory wrongProof = new bytes32[](2);

        wrongProof[0] = leaf2;
        wrongProof[1] = keccak256("random_number");

        bool verified = MerkleProof.verify(wrongProof, root, leaf1);
        assertFalse(verified, "Leaf 1 should not be verified with wrong proof");
    }

    function testMultiProofVerify() public view {
        /**
        * 多重默克尔证明需要：
        * 1. leaves 数组
        * 2. proof 数组：多重合并时尚未出现的兄弟节点
        * 3. proofFlags：标记是“从 leaves/生成的 hashes 中取”还是“从 proof 中取” 
        *
        * 本例 4个叶子完全构成了整棵树，理论上并不需要额外“兄弟节点”做 proof，
        * 因为它们两两配对就能往上“自己”合并到根。
        * 
        * 但为了让示例更具参考价值，这里可以手动构造一个 proof + proofFlags。
        */
        
        bytes32[] memory leaves = new bytes32[](4);
        leaves[0] = leaf1;
        leaves[1] = leaf2;
        leaves[2] = leaf3;
        leaves[3] = leaf4;

        // 这里故意构造一个“空”proof，说明我们直接用 leaves 能合并到 root
        // 因为 node12 = 合并(leaf1, leaf2), node34 = 合并(leaf3, leaf4),
        // 然后 root = 合并(node12, node34)
        bytes32[] memory proof = new bytes32[](0);

        // 构造 proofFlags
        //   整个多重合并过程一共需要 leavesLen + proof.length - 1 = 4 + 0 - 1 = 3 步合并
        //   也就是要产生 3 个新的 hash
        //   每步看 proofFlags[i] 的值决定要不要从 leaves 的下一个来取：
        //     - true 时，从“尚未合并过的 leaves/hashes 队列”中取
        //     - false 时，从 proof 中取
        //   这里因为 proof 为空，所以全是从 leaves/hashes 里取 => 全是true
        bool[] memory proofFlags = new bool[](3);
        proofFlags[0] = true;  // 第一次合并 (leaf1, leaf2) 得到 node12
        proofFlags[1] = true;  // 第二次合并 (leaf3, leaf4) 得到 node34
        proofFlags[2] = true;  // 第三次合并 (node12, node34) => root

        bool verified = MerkleProof.multiProofVerify(proof, proofFlags, root, leaves);
        assertTrue(verified, "Multi-proof verifying all leaves should succeed");
    }

    function testCustomHasher() public view {
        // 自定义哈希函数
        function(bytes32, bytes32) view returns (bytes32) customHasher = _orderedKeccak256;

        bytes32[] memory proof = new bytes32[](2);
        proof[0] = leaf2;
        proof[1] = node34;

        bool verified = MerkleProof.verify(proof, root, leaf1, customHasher);
        assertFalse(verified, "Leaf 1 should not be verified with custom hasher");
    }

    function _orderedKeccak256(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        bytes32 result = keccak256(abi.encodePacked(a, b));
        return keccak256(abi.encodePacked(result, "random_salt"));
    }
}