// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IConsentLedger.sol";
import "./interfaces/IAccessControl.sol";
import "./interfaces/IRecordRegistry.sol";

/// @title DoctorUpdate - Bác sĩ tạo record + AUTO GRANT consent
contract DoctorUpdate {
    IAccessControl public immutable accessControl;
    IRecordRegistry public immutable recordRegistry;
    IConsentLedger public immutable consentLedger;

    event RecordAddedByDoctor(
        address indexed doctor,
        address indexed patient,
        string indexed cid,
        string parentCID
    );

    event AutoGranted(
        address indexed grantee,
        string indexed rootCID,
        uint256 expireAt
    );

    constructor(
        IAccessControl _accessControl,
        IRecordRegistry _recordRegistry,
        IConsentLedger _consentLedger
    ) {
        accessControl = _accessControl;
        recordRegistry = _recordRegistry;
        consentLedger = _consentLedger;
    }

    modifier onlyDoctor() {
        require(accessControl.isDoctor(msg.sender), "Not doctor");
        _;
    }

    /// @notice Bác sĩ tạo record cho bệnh nhân và tự động grant consent
    function addRecordByDoctor(
        string calldata cid,
        string calldata parentCID,
        address patient,
        bytes32 encKeyHashForPatient,  // mới thêm param để linh hoạt hơn
        bytes32 encKeyHashForDoctor
    ) external onlyDoctor {
        require(patient != address(0), "Invalid patient");
        require(accessControl.isPatient(patient), "Not patient");

        // 1. Tạo record (owner = patient)
        recordRegistry.addRecordByDoctor(cid, parentCID, "Follow-up", patient);

        // 2. Auto grant vĩnh viễn cho patient
        IConsentLedger(address(consentLedger)).grantInternal(
            patient,
            patient,
            cid,
            encKeyHashForPatient,
            type(uint256).max,
            true,
            false
        );
        emit AutoGranted(patient, cid, type(uint256).max);

        // 3. Auto grant 7 ngày cho bác sĩ
        IConsentLedger(address(consentLedger)).grantInternal(
            patient,
            msg.sender,
            cid,
            encKeyHashForDoctor,
            block.timestamp + 7 days,
            false,
            false
        );
        emit AutoGranted(msg.sender, cid, block.timestamp + 7 days);

        emit RecordAddedByDoctor(msg.sender, patient, cid, parentCID);
    }
}