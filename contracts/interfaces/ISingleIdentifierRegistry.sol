// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {SIDSchemaParams, SIDSchema, SID} from "../types/Structs.sol";
import {MessageLib} from "../lib/MessageLib.sol";

interface ISingleIdentifierRegistry {

    function registrySID(MessageLib.SendMessage memory _payload) external;

    function updateSID(MessageLib.UpdateMessage memory _payload) external;

    function schemaRegistry(SIDSchemaParams calldata _schema, bytes calldata _signature) external;

    function updateSchemaEmitter(bytes32 _schemaId, address _emitter) external;

    function revoke(bytes32 _passportId) external;
}
