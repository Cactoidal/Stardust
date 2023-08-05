// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IPilot {

    function mint(address to) external;

    function instantiate(address to, uint id) external;

    function getId() external view returns(uint256);

    }
