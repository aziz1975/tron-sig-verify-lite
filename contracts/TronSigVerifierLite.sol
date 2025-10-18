// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library TronMsg {
    // TIP-191 / personal_sign-style digests for TRON
    function digestForBytes32(bytes32 raw32) internal pure returns (bytes32) {
        // "\x19TRON Signed Message:\n32" + <32 raw bytes>
        return keccak256(abi.encodePacked("\x19TRON Signed Message:\n32", raw32));
    }

    function digestForHex66(string memory hexText) internal pure returns (bytes32) {
        // hexText must be "0x" + 64 hex chars (length 66)
        require(bytes(hexText).length == 66, "hex length != 66");
        return keccak256(abi.encodePacked("\x19TRON Signed Message:\n66", hexText));
    }
}

library SimpleECDSA {

    bytes32 private constant _HALF_ORDER =
        0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    function recover(bytes32 digest, bytes memory sig) internal pure returns (address) {
        if (sig.length != 65) return address(0);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }

        if (v < 27) v += 27;
        if (v != 27 && v != 28) return address(0);

        // Reject malleable signatures
        if (uint256(s) > uint256(_HALF_ORDER)) return address(0);

        address signer = ecrecover(digest, v, r, s);
        return signer;
    }
}

contract TronSigVerifierLite {
    // ----- BYTES32 PATH (recommended): wallet signed raw 32 bytes -----
    function recoverBytes32(bytes32 raw32, bytes calldata sig) public pure returns (address) {
        bytes32 d = TronMsg.digestForBytes32(raw32);
        return SimpleECDSA.recover(d, sig);
    }

    function verifyBytes32(bytes32 raw32, bytes calldata sig, address expected) external pure returns (bool) {
        address signer = recoverBytes32(raw32, sig);
        return signer != address(0) && signer == expected;
    }

    // ----- HEX-AS-TEXT PATH: wallet signed "0x" + 64 hex chars -----
    function toHexString(bytes32 data) public pure returns (string memory) {
        bytes16 HEX = "0123456789abcdef";
        bytes memory out = new bytes(66);
        out[0] = "0"; out[1] = "x";
        bytes memory b = abi.encodePacked(data);
        for (uint i = 0; i < 32; i++) {
            uint8 v = uint8(b[i]);
            out[2 + 2*i]     = HEX[v >> 4];
            out[2 + 2*i + 1] = HEX[v & 0x0f];
        }
        return string(out);
    }

    function recoverHexText(bytes32 raw32, bytes calldata sig) public pure returns (address) {
        string memory hexText = toHexString(raw32); // length 66
        bytes32 d = TronMsg.digestForHex66(hexText);
        return SimpleECDSA.recover(d, sig);
    }

    function verifyHexText(bytes32 raw32, bytes calldata sig, address expected) external pure returns (bool) {
        address signer = recoverHexText(raw32, sig);
        return signer != address(0) && signer == expected;
    }
}
