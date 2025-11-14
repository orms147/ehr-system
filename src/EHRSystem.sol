// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "./AccessControl.sol";
import {RecordRegistry} from "./RecordRegistry.sol";

contract EHRSystem {
    AccessControl public accessControl;
    RecordRegistry public recordRegistry;

    constructor() {
        accessControl = new AccessControl();
        recordRegistry = new RecordRegistry(accessControl);
    }

    function registerAsPatient() external {
        accessControl.register(AccessControl.Role.Patient);
    }

    function addRecord(string calldata cid) external {
        recordRegistry.addRecord(cid);
    }
}