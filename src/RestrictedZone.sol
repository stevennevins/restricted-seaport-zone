// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ZoneInterface} from "seaport-types/interfaces/ZoneInterface.sol";
import {SeaportInterface} from "seaport-types/interfaces/SeaportInterface.sol";
import {Order, Schema, SpentItem, ReceivedItem, ZoneParameters} from "seaport-types/lib/ConsiderationStructs.sol";

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {ERC165Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol";

contract PausableZone is PausableUpgradeable, OwnableUpgradeable, ERC165Upgradeable, ZoneInterface {
    event OrderFilled(
        address indexed fulfiller,
        address indexed offerer,
        SpentItem[] offer,
        ReceivedItem[] consideration,
        bytes32[] orderHashes
    );

    function initalize() external initializer {
        __Ownable_init();
        __Pausable_init();
    }

    /* @notice Pause this contract, safely stopping orders from using
     *         the contract as a zone. Restricted orders with this address as a
     *         zone will not be fulfillable unless the zone is unpaused. 
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
    function validateOrder(ZoneParameters calldata params) external returns (bytes4) {
        if (paused()) {
            return bytes4(0);
        }

        emit OrderFilled(params.fulfiller, params.offerer, params.offer, params.consideration, params.orderHashes);
        return ZoneInterface.validateOrder.selector;
    }

    /**
     * @dev Returns the metadata for this zone.
     */
    function getSeaportMetadata() external pure returns (string memory name, Schema[] memory schemas) {
        return ("PausableZone", schemas);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, ZoneInterface)
        returns (bool)
    {
        return interfaceId == type(ZoneInterface).interfaceId || super.supportsInterface(interfaceId);
    }
}
