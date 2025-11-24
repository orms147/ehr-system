// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IAccessControl.sol";

contract AccessControl is IAccessControl {
    mapping(address => Role) public roles;
    mapping(address => bool) private _registered;

    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function registerRole(address user, Role role) external override onlyOwner {
        require(user != address(0), "Zero address");
        require(!_registered[user], "Already registered");
        require(role != Role.None, "Invalid role");

        roles[user] = role;
        _registered[user] = true;

        emit RoleRegistered(user, role);
    }

    function isPatient(address user) external view override returns (bool) {
        return roles[user] == Role.Patient;
    }

    function isDoctor(address user) external view override returns (bool) {
        return roles[user] == Role.Doctor;
    }

    function isOrganization(address user) external view override returns (bool) {
        return roles[user] == Role.Organization;
    }
}