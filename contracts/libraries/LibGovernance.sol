// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library LibGovernance {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;
    bytes32 constant STORAGE_POSITION = keccak256("governance.storage");

    struct Storage {
        bool initialized;
        // the set of active validators
        EnumerableSet.AddressSet membersSet;
        // Precision for calculation of minimum amount of members signatures required
        uint256 precision;
        // Percentage for minimum amount of members signatures required
        uint256 percentage;
    }

    function governanceStorage() internal pure returns (Storage storage gs) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }

    /// @return The current percentage for minimum amount of members signatures
    function percentage() internal view returns (uint256) {
        Storage storage gs = governanceStorage();
        return gs.percentage;
    }

    /// @return The current precision for minimum amount of members signatures
    function precision() internal view returns (uint256) {
        Storage storage gs = governanceStorage();
        return gs.precision;
    }

    function updateMembersPercentage(uint256 _newPercentage) internal {
        Storage storage gs = governanceStorage();
        require(
            _newPercentage < gs.precision,
            "LibGovernance: percentage must be less than precision"
        );
        gs.percentage = _newPercentage;
    }

    /// @notice Adds/removes a validator from the member set
    function updateMember(address _account, bool _status) internal {
        Storage storage gs = governanceStorage();
        if (_status) {
            require(
                gs.membersSet.add(_account),
                "LibGovernance: Account already added"
            );
        } else if (!_status) {
            require(
                LibGovernance.membersCount() > 1,
                "LibGovernance: contract would become memberless"
            );
            require(
                gs.membersSet.remove(_account),
                "LibGovernance: Account is not a member"
            );
        }
    }

    /// @notice Returns true/false depending on whether a given address is member or not
    function isMember(address _member) internal view returns (bool) {
        Storage storage gs = governanceStorage();
        return gs.membersSet.contains(_member);
    }

    /// @notice Returns the count of the members
    function membersCount() internal view returns (uint256) {
        Storage storage gs = governanceStorage();
        return gs.membersSet.length();
    }

    /// @notice Returns the address of a member at a given index
    function memberAt(uint256 _index) internal view returns (address) {
        Storage storage gs = governanceStorage();
        return gs.membersSet.at(_index);
    }

    /// @notice Accepts number of signatures in the range (n/2; n] where n is the number of members
    function validateSignaturesLength(uint256 _n) internal view {
        Storage storage gs = governanceStorage();
        uint256 members = gs.membersSet.length();
        require(_n <= members, "LibGovernance: Invalid number of signatures");
        require(
            _n > (members * gs.percentage) / gs.precision,
            "LibGovernance: Invalid number of signatures"
        );
    }

    /// @notice Validates the provided signatures against the member set
    function validateSignatures(bytes32 _ethHash, bytes[] calldata _signatures)
        internal
        view
    {
        address[] memory signers = new address[](_signatures.length);
        for (uint256 i = 0; i < _signatures.length; i++) {
            address signer = ECDSA.recover(_ethHash, _signatures[i]);
            require(isMember(signer), "LibGovernance: invalid signer");
            for (uint256 j = 0; j < i; j++) {
                require(
                    signer != signers[j],
                    "LibGovernance: duplicate signatures"
                );
            }
            signers[i] = signer;
        }
    }
}