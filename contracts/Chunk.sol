// SPDX-License-Identifier: GPL

pragma solidity >=0.7.0 <0.9.0;

import "./ChainElement.sol";

//A Wholesaler-ek által szétbontott termék a chunk
contract Chunk is ChainElement {

    //A termék azonosítója, amelyből a chunk készül
    uint origin;

    constructor(uint _ID, address _owner, string memory _name, uint _origin) ChainElement(_ID, _owner, _name){
        origin = _origin;
    }

    function getOrigin() public view returns(uint _origin) {
        _origin = origin;
    }

}