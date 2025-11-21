// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "src/interface/IAccessControl.sol";

contract AccessControl is IAccessControl {
    mapping(address => Role) public roles;
    mapping(address => bool) public isRegistered;

    function registerRole(address user, Role role) external {
        require(!isRegistered[user], "Already registered");
        require(role != Role.None, "Invalid role");

        roles[user] = role;
        isRegistered[user] = true;

        emit RoleRegistered(user, role);
    }

    function isPatient(address user) external view returns (bool) {
        return roles[user] == Role.Patient;
    }

    function isDoctor(address user) external view returns (bool) {
        return roles[user] == Role.Doctor;
    }
}