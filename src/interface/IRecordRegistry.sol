// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

    event RecordAdded(address indexed owner, string cid, string parentCID, bytes32 recordTypeHash, uint256 timestamp);

    function addRecord(string memory cid, string memory parentCID, string memory recordType) external;
    function addRecordByOwner(string memory cid, string memory parentCID, string memory recordType, address owner) external;
    function getRecord(string memory cid) external view returns (Record memory);
    function getOwnerRecords(address owner) external view returns (string[] memory);
    function recordExists(string memory cid) external view returns (bool);
}