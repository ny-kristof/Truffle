// SPDX-License-Identifier: GPL

pragma solidity >=0.7.0 <0.9.0;

abstract contract ChainElement {

    uint  ID;
    address  owner;
    string  name;
    uint inShipment;
    bool  shipped;
    bool  defect;

    constructor(uint _ID, address _owner, string memory _name){
        ID = _ID;
        name = _name;
        owner = _owner;
    }

    function getID() public view returns(uint _id){
        _id = ID;
    }

    function getOwner() public view returns(address _owner){
        _owner = owner;
    }

    function getName() public view returns(string memory _name) {
        _name = name;
    }

    function markShipped() public {
        shipped = true;
    }

    function isShipped() public view returns(bool _shipped){
        _shipped = shipped;
    }

    function getInShipment() public view returns(uint _id){
        _id = inShipment;
    }

    function setInShipment(uint shipmentID) public {
        inShipment = shipmentID;
    }

    function markDefect() public {
        defect = true;
    }

    function isSpoiled() public view returns(bool _defect){
        _defect = defect;
    }
}
