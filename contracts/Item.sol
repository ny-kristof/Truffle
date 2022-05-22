// SPDX-License-Identifier: GPL

pragma solidity >=0.7.0 <0.9.0;

import "./ChainElement.sol";

//A Retailer-ek által tovább bontott chunk a végtermék
contract Item is ChainElement {

    //A chunk azonosítója, amelyből a végtermék készül
    uint origin;

    constructor(uint _ID, address _owner, string memory _name, uint _origin) ChainElement(_ID, _owner, _name){
        origin = _origin;
    }

    function getOrigin() public view returns(uint _origin) {
        _origin = origin;
    }

}