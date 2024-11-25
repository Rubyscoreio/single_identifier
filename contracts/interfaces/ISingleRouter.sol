// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

interface ISingleRouter {

    function getTransferProtocol(bytes32 _emitterId, uint32 _destination) external returns (address);
}
