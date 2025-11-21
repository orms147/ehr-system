// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IConsentLedger {
    struct ConsentPermit {
        address patient;
        address grantee;
        string rootCID;
        bytes32 encKeyHash;
        uint256 issuedAt;
        uint256 expireAt;
        bool includeUpdates;
        bool allowDelegate;
        uint256 nonce;
    }

    struct Consent {
        address patient;
        address grantee;
        string rootCID;
        bytes32 encKeyHash;
        uint256 issuedAt;
        uint256 expireAt;
        bool active;
        bool includeUpdates;
        bool allowDelegate;
        uint256 nonce;
    }

    event ConsentGranted(address indexed patient, address indexed grantee, string indexed rootCID, uint256 expireAt, bool allowDelegate);
    event ConsentRevoked(address indexed patient, address indexed grantee, string indexed rootCID, uint256 timestamp);

    function grant(address grantee, string memory rootCID, bytes32 encKeyHash, uint256 expireAt, bool includeUpdates, bool allowDelegate) external;
    function grantBySig(ConsentPermit memory permit, bytes memory signature) external;
    function grantInternal(address patient, address grantee, string memory rootCID, bytes32 encKeyHash, uint256 expireAt, bool includeUpdates, bool allowDelegate) external;
    function revoke(string memory rootCID, address grantee) external;
    function canAccess(address grantee, string memory cid) external view returns (bool);
    function getConsent(address grantee, string memory rootCID) external view returns (Consent memory);
    function getNonce(address patient) external view returns (uint256);
}