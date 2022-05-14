// SPDX-License-Identifier: GPL

pragma solidity >=0.7.0 <0.9.0;

import "./ChainElement.sol";
import "./Resource.sol";

contract Product is ChainElement {

    uint[] ingredients;

    constructor(uint _ID, address _owner, string memory _name) ChainElement(_ID, _owner, _name){

    }

    function getIngredients() public view returns(uint[] memory _ingredients) {
        _ingredients = ingredients;
    }

    function addIngredient(uint _ingredient) public{
        ingredients.push(_ingredient);
    } 

}