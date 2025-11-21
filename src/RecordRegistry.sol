// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "src/interface/IRecordRegistry.sol";
import "src/interface/IAccessControl.sol";

contract RecordRegistry is IRecordRegistry {
    IAccessControl public accessControl;

    mapping(string => Record) public records;
    mapping(address => string[]) public ownerRecords;
    mapping(string => string[]) public parentChildren;

    constructor(IAccessControl _accessControl) {
        accessControl = _accessControl;
    }

    modifier onlyPatient() {
        require(accessControl.isPatient(msg.sender), "Not patient");
        _;
    }

    function addRecord(
        string memory cid,
        string memory parentCID,
        string memory recordType
    ) external onlyPatient {
        _addRecord(cid, parentCID, recordType, msg.sender);
    }

    function addRecordByOwner(
        string memory cid,
        string memory parentCID,
        string memory recordType,
        address owner
    ) external {
        require(
            accessControl.isDoctor(msg.sender),
            "Not authorized"
        );
        _addRecord(cid, parentCID, recordType, owner);
    }

    function _addRecord(
        string memory cid,
        string memory parentCID,
        string memory recordType,
        address owner
    ) internal {
        require(bytes(cid).length > 0, "CID empty");
        require(!records[cid].exists, "Record exists");

        bytes32 recordTypeHash = keccak256(abi.encodePacked(recordType));
        uint8 version = 1;

        if (bytes(parentCID).length > 0) {
            require(records[parentCID].exists, "Parent not exist");
            version = records[parentCID].version + 1;
            parentChildren[parentCID].push(cid);
        }

        records[cid] = Record({
            cid: cid,
            parentCID: parentCID,
            createdBy: msg.sender,
            owner: owner,
            recordTypeHash: recordTypeHash,
            createdAt: block.timestamp,
            version: version,
            exists: true
        });

        ownerRecords[owner].push(cid);

        emit RecordAdded(owner, cid, parentCID, recordTypeHash, block.timestamp);
    }

    // === VIEW FUNCTIONS ===
    function getRecord(string memory cid) external view returns (Record memory) {
        require(records[cid].exists, "Not exist");
        return records[cid];
    }

    function getOwnerRecords(address owner) external view returns (string[] memory) {
        return ownerRecords[owner];
    }

    function recordExists(string memory cid) external view returns (bool) {
        return records[cid].exists;
    }
}