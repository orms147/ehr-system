// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IEHRSystem.sol";
import "./interfaces/IAccessControl.sol";
import "./interfaces/IRecordRegistry.sol";
import "./interfaces/IConsentLedger.sol";
import "./AccessControl.sol";
import "./RecordRegistry.sol";
import "./ConsentLedger.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title EHRSystemSecure - Contract chính (có pause, ownable, delegate flow)
contract EHRSystemSecure is IEHRSystem, Ownable, Pausable {
    IAccessControl public override accessControl;
    IRecordRegistry public override recordRegistry;
    IConsentLedger public override consentLedger;

    struct DelegateRequest {
        address doctor;
        address patient;
        string rootCID;
        bool approved;
    }

    mapping(bytes32 => DelegateRequest) public delegateRequests;

    event DelegateRequested(bytes32 indexed requestId, address indexed doctor, address indexed patient, string rootCID);
    event DelegateApproved(bytes32 indexed requestId, address indexed doctor, address indexed patient, string rootCID);

    constructor(address initialVerifier) Ownable(msg.sender) {
        accessControl = new AccessControl(initialVerifier);
        recordRegistry = new RecordRegistry(accessControl);
        consentLedger = new ConsentLedger();

        // Authorize chính contract này để gọi grantInternal
        ConsentLedger(address(consentLedger)).authorizeContract(address(this));

        emit SystemInitialized(
            address(accessControl),
            address(recordRegistry),
            address(consentLedger)
        );
    }

    // Wrapper functions
    function addRecord(string memory cid, string memory parentCID, string memory recordType) external override whenNotPaused {
        recordRegistry.addRecord(cid, parentCID, recordType);
    }

    function grantConsent(
        address grantee,
        string memory rootCID,
        bytes32 encKeyHash,
        uint256 expireAt,
        bool includeUpdates,
        bool allowDelegate
    ) external override whenNotPaused {
        consentLedger.grant(grantee, rootCID, encKeyHash, expireAt, includeUpdates, allowDelegate);
    }

    function revokeConsent(string memory rootCID, address grantee) external override whenNotPaused {
        consentLedger.revoke(rootCID, grantee);
    }

    // Emergency pause
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Delegate flow (doctor request → organization approve)
    modifier onlyDoctor() {
        require(accessControl.isDoctor(msg.sender), "Not doctor");
        _;
    }

    modifier onlyOrganization() {
        require(accessControl.isOrganization(msg.sender), "Not organization");
        _;
    }

    function requestDelegateAccess(address patient, string memory rootCID) external onlyDoctor whenNotPaused {
        bytes32 reqId = keccak256(abi.encode(msg.sender, patient, rootCID));
        require(delegateRequests[reqId].doctor == address(0), "Request exists");

        delegateRequests[reqId] = DelegateRequest({
            doctor: msg.sender,
            patient: patient,
            rootCID: rootCID,
            approved: false
        });

        emit DelegateRequested(reqId, msg.sender, patient, rootCID);
    }

    function approveDelegate(bytes32 reqId, bytes32 encKeyHash, uint256 duration) external onlyOrganization whenNotPaused {
        DelegateRequest storage req = delegateRequests[reqId];
        require(req.doctor != address(0), "Not exist");
        require(!req.approved, "Already approved");

        req.approved = true;

        ConsentLedger(address(consentLedger)).grantInternal(
            req.patient,
            req.doctor,
            req.rootCID,
            encKeyHash,
            block.timestamp + duration, // linh hoạt, mặc định có thể là 30 days
            true,
            false
        );

        emit DelegateApproved(reqId, req.doctor, req.patient, req.rootCID);
    }
}