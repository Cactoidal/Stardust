// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IStardust {

    function updateEmployer(uint, address) external;

    function checkAvailable(uint _id) external view returns (bool);

    function setPrices(int[5] calldata) external;

    }
