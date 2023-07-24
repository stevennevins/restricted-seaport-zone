// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ZoneInteractionErrors} from "seaport-types/interfaces/ZoneInteractionErrors.sol";
import {ZoneInterface} from "seaport-types/interfaces/ZoneInterface.sol";
import {SeaportInterface} from "seaport-types/interfaces/SeaportInterface.sol";
import {Order, Schema, ZoneParameters} from "seaport-types/lib/ConsiderationStructs.sol";

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";

/**
 * @title  PausableZone
 * @author cupOJoseph, BCLeFevre, ryanio
 * @notice PausableZone is a simple zone implementation that approves every
 *         order. It can be self-destructed by its controller to pause
 *         restricted orders that have it set as their zone. Note that this zone
 *         cannot execute orders that return native tokens to the fulfiller.
 */
contract RestrictedZone is PausableUpgradeable, OwnableUpgradeable, ZoneInteractionErrors, ZoneInterface {
    address internal seaport;
    uint96 private mutex = 1;

    modifier lock() {
        require(mutex == 1, "Locked");
        mutex = 2;
        _;
        mutex = 1;
    }

    function initalize(address _seaport) external initializer {
        seaport = _seaport;
        __Ownable_init();
        __Pausable_init();
    }

    function fulFillOrder(Order calldata order, bytes32 _conduitKey) external payable whenNotPaused lock {
        SeaportInterface(seaport).fulfillOrder{value: msg.value}(order, _conduitKey);
    }

    /* @notice Pause this contract, safely stopping orders from using
     *         the contract as a zone. Restricted orders with this address as a
     *         zone will not be fulfillable unless the zone is redeployed to the
     *         same address.
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Check if a given order including extraData is currently valid.
     *
     * @dev This function is called by Seaport whenever any extraData is
     *      provided by the caller.
     *
     * @custom:param zoneParameters A struct that provides context about the
     *                              order fulfillment and any supplied
     *                              extraData, as well as all order hashes
     *                              fulfilled in a call to a match or
     *                              fulfillAvailable method.
     *
     * @return validOrderMagicValue A magic value indicating if the order is
     *                              currently valid.
     */
    function validateOrder(ZoneParameters calldata) external view returns (bytes4) {
        // Return the selector of isValidOrder as the magic value.
        if (mutex == 2 && !paused()) return ZoneInterface.validateOrder.selector;
        return bytes4(0);
    }

    /**
     * @dev Returns the metadata for this zone.
     */
    function getSeaportMetadata() external pure returns (string memory name, Schema[] memory schemas) {
        schemas = new Schema[](1);
        schemas[0].id = 3003; // this would need to be the value to the restricted zone
        schemas[0].metadata = new bytes(0);

        return ("RestrictedZone", schemas);
    }

    function supportsInterface(bytes4) external pure returns (bool) {
        return true;
    }
}
