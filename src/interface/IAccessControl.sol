// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAccessControl {
    enum Role {
        None,
        Patient,
        Doctor,
        Organization
    }

    function isPatient(address user) external view returns (bool);
    function isDoctor(address user) external view returns (bool);
    function isOrganization(address user) external view returns (bool);

    function registerRole(address user, Role role) external;
    function updateRole(address user, Role newRole) external;

    function getRole(address user) external view returns (Role);
}