// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IConsentLedger.sol";

contract ConsentLedger is IConsentLedger, ReentrancyGuard {
    using ECDSA for bytes32;

    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "ConsentPermit(address patient,address grantee,string rootCID,bytes32 encKeyHash,uint256 issuedAt,uint256 expireAt,bool includeUpdates,bool allowDelegate,uint256 nonce)"
    );

    bytes32 public immutable DOMAIN_SEPARATOR;
    string public constant NAME = "EHR Consent Ledger";
    string public constant VERSION = "2";

    mapping(address => mapping(string => Consent)) public consents; // grantee => rootCID => Consent
    mapping(address => uint256) public nonces;
    mapping(address => bool) public authorizedContracts;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(NAME)),
                keccak256(bytes(VERSION)),
                block.chainid,
                address(this)
            )
        );
    }

    modifier onlyAuthorized() {
        require(msg.sender == tx.origin || authorizedContracts[msg.sender], "Unauthorized");
        _;
    }

    function authorizeContract(address c) external onlyAuthorized {
        authorizedContracts[c] = true;
    }

    function grant(
        address grantee,
        string memory rootCID,
        bytes32 encKeyHash,
        uint256 expireAt,
        bool includeUpdates,
        bool allowDelegate
    ) external nonReentrant {
        _grant(msg.sender, grantee, rootCID, encKeyHash, expireAt, includeUpdates, allowDelegate);
    }

    function grantInternal(
        address patient,
        address grantee,
        string memory rootCID,
        bytes32 encKeyHash,
        uint256 expireAt,
        bool includeUpdates,
        bool allowDelegate
    ) external nonReentrant onlyAuthorized {
        _grant(patient, grantee, rootCID, encKeyHash, expireAt, includeUpdates, allowDelegate);
    }

    function _grant(
        address patient,
        address grantee,
        string memory rootCID,
        bytes32 encKeyHash,
        uint256 expireAt,
        bool includeUpdates,
        bool allowDelegate
    ) internal {
        require(grantee != address(0), "Invalid grantee");
        require(bytes(rootCID).length > 0, "Empty CID");
        require(expireAt == type(uint256).max || expireAt > block.timestamp, "Invalid expire");

        uint256 nonce = nonces[patient]++;

        consents[grantee][rootCID] = Consent({
            patient: patient,
            grantee: grantee,
            rootCID: rootCID,
            encKeyHash: encKeyHash,
            issuedAt: block.timestamp,
            expireAt: expireAt,
            active: true,
            includeUpdates: includeUpdates,
            allowDelegate: allowDelegate,
            nonce: nonce
        });

        emit ConsentGranted(patient, grantee, rootCID, expireAt, allowDelegate);
    }

    function grantBySig(ConsentPermit calldata permit, bytes calldata signature) external nonReentrant {
        require(permit.nonce == nonces[permit.patient], "Invalid nonce");

        bytes32 structHash = keccak256(abi.encode(
            PERMIT_TYPEHASH,
            permit.patient,
            permit.grantee,
            keccak256(bytes(permit.rootCID)),
            permit.encKeyHash,
            permit.issuedAt,
            permit.expireAt,
            permit.includeUpdates,
            permit.allowDelegate,
            permit.nonce
        ));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address signer = digest.recover(signature);
        require(signer == permit.patient, "Invalid signature");

        nonces[permit.patient]++;

        consents[permit.grantee][permit.rootCID] = Consent({
            patient: permit.patient,
            grantee: permit.grantee,
            rootCID: permit.rootCID,
            encKeyHash: permit.encKeyHash,
            issuedAt: permit.issuedAt,
            expireAt: permit.expireAt,
            active: true,
            includeUpdates: permit.includeUpdates,
            allowDelegate: permit.allowDelegate,
            nonce: permit.nonce
        });

        emit ConsentGranted(permit.patient, permit.grantee, permit.rootCID, permit.expireAt, permit.allowDelegate);
    }

    function revoke(string memory rootCID, address grantee) external nonReentrant {
        Consent storage c = consents[grantee][rootCID];
        require(c.active && c.patient == msg.sender, "Unauthorized");
        c.active = false;
        emit ConsentRevoked(msg.sender, grantee, rootCID, block.timestamp);
    }

    function canAccess(address grantee, string memory cid) external view override returns (bool) {
        Consent memory c = consents[grantee][cid];
        if (!c.active) return false;
        if (c.expireAt != type(uint256).max && block.timestamp > c.expireAt) return false;
        return true;
    }

    function getConsent(address grantee, string memory rootCID) external view override returns (Consent memory) {
        return consents[grantee][rootCID];
    }

    function getNonce(address patient) external view override returns (uint256) {
        return nonces[patient];
    }
}