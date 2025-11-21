// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRecordRegistry {
    struct Record {
        string cid;
        string parentCID;
        address createdBy;
        address owner;
        bytes32 recordTypeHash;
        uint256 createdAt;
        uint8 version;
        bool exists;
    }

    event RecordAdded(string indexed cid, address indexed owner, string parentCID, uint256 timestamp);
    event RecordUpdated(string indexed oldCID, string indexed newCID, address indexed owner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, string indexed cid);

    function addRecord(string memory cid, string memory parentCID, string memory recordType) external;
    function addRecordByDoctor(string memory cid, string memory parentCID, string memory recordType, address patient) external;
    function updateRecordCID(string memory oldCID, string memory newCID) external;
    function transferOwnership(string memory cid, address newOwner) external;
    function getRecord(string memory cid) external view returns (Record memory);
    function getOwnerRecords(address owner) external view returns (string[] memory);
    function getChildRecords(string memory parentCID) external view returns (string[] memory);
    function recordExists(string memory cid) external view returns (bool);
}