// SPDX-License-Identifier: GPL

pragma solidity >=0.7.0 <0.9.0;

import "./ChainElement.sol";

contract Resource is ChainElement {

    constructor(uint _ID, address _owner, string memory _name) ChainElement(_ID, _owner, _name){

    }
}
