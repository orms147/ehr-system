// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IAccessControl.sol";
import "./IRecordRegistry.sol";
import "./IConsentLedger.sol";

interface IEHRSystem {
    event SystemInitialized(address indexed accessControl, address indexed recordRegistry, address indexed consentLedger);

    function accessControl() external view returns (IAccessControl);
    function recordRegistry() external view returns (IRecordRegistry);
    function consentLedger() external view returns (IConsentLedger);

    function addRecord(string memory cid, string memory parentCID, string memory recordType) external;
    function grantConsent(address grantee, string memory rootCID, bytes32 encKeyHash, uint256 expireAt, bool includeUpdates, bool allowDelegate) external;
    function revokeConsent(string memory rootCID, address grantee) external;
}