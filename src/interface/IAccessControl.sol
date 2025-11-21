// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IAccessControl {
    enum Role { None, Patient, Doctor, Organization }
    
    event RoleRegistered(address indexed user, Role role);

    function registerRole(address user, Role role) external;
    function isPatient(address user) external view returns (bool);
    function isDoctor(address user) external view returns (bool);
}