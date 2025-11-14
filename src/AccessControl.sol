// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract AccessControl {
    enum Role { None, Patient, Doctor }
    mapping(address => Role) public roles;

    event RoleRegistered(address indexed user, Role role);

    function register(Role role) external {
        require(roles[msg.sender] == Role.None, "Already registered");
        roles[msg.sender] = role;
        emit RoleRegistered(msg.sender, role);
    }

    function isPatient(address user) external view returns (bool) {
        return roles[user] == Role.Patient;
    }

    function isDoctor(address user) external view returns (bool) {
        return roles[user] == Role.Doctor;
    }
}