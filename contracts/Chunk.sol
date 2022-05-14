// SPDX-License-Identifier: GPL

pragma solidity >=0.7.0 <0.9.0;

import "./ChainElement.sol";
import "./Product.sol";

contract Chunk is ChainElement {

    uint origin;

    constructor(uint _ID, address _owner, string memory _name, uint _origin) ChainElement(_ID, _owner, _name){
        origin = _origin;
    }

    function getOrigin() public view returns(uint _origin) {
        _origin = origin;
    }

}