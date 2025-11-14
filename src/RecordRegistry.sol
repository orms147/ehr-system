// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAccessControl} from "./interface/IAccessControl.sol";

contract RecordRegistry {
    IAccessControl public accessControl;

    struct Record {
        string cid;
        address owner;
        bool exists;
    }

    mapping(string => Record) public records;
    mapping(address => string[]) public ownerRecords;

    event RecordAdded(string indexed cid, address indexed owner);

    constructor(IAccessControl _accessControl) {
        accessControl = _accessControl;
    }

    modifier onlyPatient() {
        require(accessControl.isPatient(msg.sender), "Not patient");
        _;
    }

    function addRecord(string calldata cid) external onlyPatient {
        require(!records[cid].exists, "Exists");
        records[cid] = Record(cid, msg.sender, true);
        ownerRecords[msg.sender].push(cid);
        emit RecordAdded(cid, msg.sender);
    }
}