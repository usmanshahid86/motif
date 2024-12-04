// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BitcoinUtils {

    bytes constant CHARSET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";
    struct Output {
        uint64 value;
        bytes scriptPubKey;
    }

    error InvalidPSBTMagic();
    error PSBTTooShort();
    error UnsupportedPSBTVersion(uint8 version);
    error ExpectedGlobalUnsignedTx();
    error UnexpectedEndOfData();
    
    function getWitnessProgram(bytes memory script) public pure returns (bytes32) {
        return sha256(script);
    }
    
    // Convert script to P2WSH scriptPubKey
    function getScriptPubKey(bytes memory script) public pure returns (bytes memory) {
        bytes32 witnessProgram = getWitnessProgram(script);
        
        // P2WSH scriptPubKey: OP_0 <32-byte-hash>
        return abi.encodePacked(
            bytes1(0x00),  // witness version
            bytes1(0x20),  // push 32 bytes
            witnessProgram
        );
    }
    
    // Helper to verify if a script matches an address's witness program
    function verifyScriptForAddress(
        bytes memory script,
        bytes32 witnessProgram
    ) public pure returns (bool) {
        return sha256(script) == witnessProgram;
    }
    
    // Convert 8-bit array to 5-bit array
    function convertBits(bytes memory data, uint8 fromBits, uint8 toBits, bool pad) 
        internal pure returns (bytes memory) {
        uint256 acc = 0;
        uint256 bits = 0;
        bytes memory ret = new bytes(64); // Max possible size
        uint256 length = 0;
        
        for (uint256 i = 0; i < data.length; i++) {
            acc = (acc << fromBits) | uint8(data[i]);
            bits += fromBits;
            
            while (bits >= toBits) {
                bits -= toBits;
                ret[length] = bytes1(uint8((acc >> bits) & ((1 << toBits) - 1)));
                length++;
            }
        }
        
        if (pad && bits > 0) {
            ret[length] = bytes1(uint8((acc << (toBits - bits)) & ((1 << toBits) - 1)));
            length++;
        }
        
        // Trim to actual length
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = ret[i];
        }
        return result;
    }
    
    // Create checksum for Bech32 address
    function createChecksum(bytes memory hrp, bytes memory data) 
        internal pure returns (bytes memory) {
        uint256[] memory values = new uint256[](hrp.length + data.length + 7);
        uint256 i = 0;
        
        // Expand HRP
        for (; i < hrp.length; i++) {
            values[i] = uint8(hrp[i]) >> 5;
        }
        values[i++] = 0;
        for (uint256 j = 0; j < hrp.length; j++) {
            values[i++] = uint8(hrp[j]) & 31;
        }
        
        // Add data
        for (uint256 j = 0; j < data.length; j++) {
            values[i++] = uint8(data[j]);
        }
        
        // Add checksum template
        values[i++] = 0;
        values[i++] = 0;
        values[i++] = 0;
        values[i++] = 0;
        values[i++] = 0;
        values[i++] = 0;
        
        // Calculate checksum
        uint256 polymod = 1;
        for (i = 0; i < values.length; i++) {
            uint256 b = polymod >> 25;
            polymod = ((polymod & 0x1ffffff) << 5) ^ values[i];
            for (uint256 j = 0; j < 5; j++) {
                if (((b >> j) & 1) == 1) {
                    polymod ^= uint256(0x3b6a57b2) << (j * 5);
                }
            }
        }
        polymod ^= 1;
        
        // Convert checksum to 5-bit array
        bytes memory checksum = new bytes(6);
        for (i = 0; i < 6; i++) {
            checksum[5 - i] = bytes1(uint8((polymod >> (5 * i)) & 31));
        }
        return checksum;
    }
    
    // Convert scriptPubKey to Bech32 address
    function toBech32Address(bytes memory scriptPubKey) public pure returns (string memory) {
        require(scriptPubKey.length > 2, "Invalid scriptPubKey length");
        require(scriptPubKey[0] == 0x00, "Invalid witness version");
        
        // HRP for mainnet
        bytes memory hrp = "bc";
        
        // Convert scriptPubKey to 5-bit data
        bytes memory converted = convertBits(scriptPubKey, 8, 5, true);
        
        // Get checksum
        bytes memory checksum = createChecksum(hrp, converted);
        
        // Combine all parts
        bytes memory combined = new bytes(converted.length + checksum.length);
        for (uint i = 0; i < converted.length; i++) {
            combined[i] = converted[i];
        }
        for (uint i = 0; i < checksum.length; i++) {
            combined[converted.length + i] = checksum[i];
        }
        
        // Create final string
        bytes memory result = new bytes(hrp.length + 1 + combined.length);
        for (uint i = 0; i < hrp.length; i++) {
            result[i] = hrp[i];
        }
        result[hrp.length] = "1";
        
        // Encode data using charset
        for (uint i = 0; i < combined.length; i++) {
            result[hrp.length + 1 + i] = CHARSET[uint8(combined[i])];
        }
        
        return string(result);
    }

    function extractPublicKeys(bytes memory scriptBytes) public pure returns (bytes memory pubKey1, bytes memory pubKey2) {
        require(scriptBytes.length >= 66, "Script is too short to contain two public keys");

        pubKey1 = new bytes(33);
        pubKey2 = new bytes(33);

        for(uint i = 0; i < 33; i++) {
            pubKey1[i] = scriptBytes[i + 1];
            pubKey2[i] = scriptBytes[i + 34];
        }
    }

    function extractVoutFromPSBT(bytes calldata psbtBytes) public pure returns (Output[] memory) {
        uint256 pos = 5; // Skip magic bytes

        // Verify magic bytes
        if (psbtBytes.length < 5 || 
            psbtBytes[0] != 0x70 || 
            psbtBytes[1] != 0x73 || 
            psbtBytes[2] != 0x62 || 
            psbtBytes[3] != 0x74 || 
            psbtBytes[4] != 0xff) {
            revert InvalidPSBTMagic();
        }

        // Read PSBT version
        if (pos >= psbtBytes.length) {
            revert PSBTTooShort();
        }
        uint8 version = uint8(psbtBytes[pos]);
        pos++;

        if (version != 0x01) {
            revert UnsupportedPSBTVersion(version);
        }

        // Read global unsigned tx
        if (psbtBytes[pos] != 0x00) {
            revert ExpectedGlobalUnsignedTx();
        }
        pos++;

        // Read tx length
        pos++; // Skip tx length byte

        // Skip version (4 bytes)
        pos += 4;

        // Read input count
        (uint64 inputCount, uint256 bytesRead) = readCompactSize(psbtBytes, pos);
        pos += bytesRead;

        // Skip inputs
        for (uint64 i = 0; i < inputCount; i++) {
            pos = skipInput(psbtBytes, pos);
        }

        // Read output count
        (uint64 outputCount, uint256 bytesRead2) = readCompactSize(psbtBytes, pos);
        pos += bytesRead;

        // Create outputs array
        Output[] memory outputs = new Output[](outputCount);

        // Parse outputs
        for (uint64 i = 0; i < outputCount; i++) {
            if (pos + 8 > psbtBytes.length) {
                revert UnexpectedEndOfData();
            }

            // Read value (8 bytes)
            uint64 value = uint64(readLittleEndianUint64(psbtBytes, pos));
            pos += 8;

            // Read scriptPubKey
            (uint64 scriptSize, uint256 scriptBytesRead) = readCompactSize(psbtBytes, pos);
            pos += scriptBytesRead;

            if (pos + scriptSize > psbtBytes.length) {
                revert UnexpectedEndOfData();
            }

            // Extract scriptPubKey
            bytes memory script = extractBytes(psbtBytes, pos, uint256(scriptSize));
            pos += uint256(scriptSize);

            outputs[i] = Output({
                value: value,
                scriptPubKey: script
            });
        }

        return outputs;
    }

    function readCompactSize(bytes calldata data, uint256 pos) internal pure returns (uint64, uint256) {
        if (pos >= data.length) {
            return (0, 0);
        }

        uint8 first = uint8(data[pos]);
        if (first < 253) {
            return (uint64(first), 1);
        }

        if (first == 253) {
            if (pos + 3 > data.length) {
                return (0, 0);
            }
            return (uint64(readLittleEndianUint16(data, pos + 1)), 3);
        }

        if (first == 254) {
            if (pos + 5 > data.length) {
                return (0, 0);
            }
            return (uint64(readLittleEndianUint32(data, pos + 1)), 5);
        }

        if (pos + 9 > data.length) {
            return (0, 0);
        }
        return (uint64(readLittleEndianUint64(data, pos + 1)), 9);
    }

    function skipInput(bytes calldata data, uint256 pos) internal pure returns (uint256) {
        if (pos + 32 > data.length) {
            revert UnexpectedEndOfData();
        }
        pos += 32; // Skip txid

        if (pos + 4 > data.length) {
            revert UnexpectedEndOfData();
        }
        pos += 4; // Skip vout index

        // Skip script
        if (pos >= data.length) {
            revert UnexpectedEndOfData();
        }
        (uint64 scriptSize, uint256 bytesRead) = readCompactSize(data, pos);
        pos += bytesRead + uint256(scriptSize);

        if (pos + 4 > data.length) {
            revert UnexpectedEndOfData();
        }
        pos += 4; // Skip sequence

        return pos;
    }

    function readLittleEndianUint16(bytes calldata data, uint256 pos) internal pure returns (uint16) {
        return uint16(uint8(data[pos])) | (uint16(uint8(data[pos + 1])) << 8);
    }

    function readLittleEndianUint32(bytes calldata data, uint256 pos) internal pure returns (uint32) {
        return uint32(uint8(data[pos])) |
               (uint32(uint8(data[pos + 1])) << 8) |
               (uint32(uint8(data[pos + 2])) << 16) |
               (uint32(uint8(data[pos + 3])) << 24);
    }

    function readLittleEndianUint64(bytes calldata data, uint256 pos) internal pure returns (uint64) {
        return uint64(uint8(data[pos])) |
               (uint64(uint8(data[pos + 1])) << 8) |
               (uint64(uint8(data[pos + 2])) << 16) |
               (uint64(uint8(data[pos + 3])) << 24) |
               (uint64(uint8(data[pos + 4])) << 32) |
               (uint64(uint8(data[pos + 5])) << 40) |
               (uint64(uint8(data[pos + 6])) << 48) |
               (uint64(uint8(data[pos + 7])) << 56);
    }

    function extractBytes(bytes calldata data, uint256 start, uint256 length) internal pure returns (bytes memory) {
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = data[start + i];
        }
        return result;
    }

}