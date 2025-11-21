// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAccessControl {
    enum Role { None, Patient, Doctor, Organization }

    event RoleRegistered(address indexed user, Role indexed role);

    function isPatient(address user) external view returns (bool);
    function isDoctor(address user) external view returns (bool);
    function isOrganization(address user) external view returns (bool);
}