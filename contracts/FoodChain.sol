// SPDX-License-Identifier: GPL

pragma solidity >=0.7.0 <0.9.0;

import "./Resource.sol";
import "./Product.sol";
import "./Chunk.sol";
import "./Item.sol";
import "./ChainElement.sol";

contract FoodChain {

    address owner;

    enum ROLE {
        None,
        Farm,
        Shipper,
        Factory,
        Wholesaler,
        Retailer
    }

    struct Shipment{
        uint ID;
        address from;
        address to;
        address shipper;
        uint[] elements;
    }

    struct DefectReport{
        uint ID;
        uint entityID;
        address source;
        address issuer;
        ChainElement[] spoiledEntities;
    }

    mapping(address => ROLE)  parties;
    Resource[] resources;
    Shipment[] shipments;
    Product[] products;
    Chunk[] chunks;
    Item[] items;
    DefectReport[] defectReports;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /*
    function getRole(uint num) external pure returns(ROLE role){
        if(num == uint(0)) return ROLE.None;
        if(num == uint(1)) return ROLE.Farm;
        if(num == uint(2)) return ROLE.Shipper;
        if(num == uint(3)) return ROLE.Factory;
        if(num == uint(4)) return ROLE.Wholesaler;
        if(num == uint(5)) return ROLE.Retailer;
    }
    */

    function getResources() external view returns(Resource[] memory resourcelist){
        resourcelist = resources;
    }
    function getShipments() external view returns(Shipment[] memory shipmentlist){
        shipmentlist = shipments;
    }
    function getProducts() external view returns(Product[] memory productlist){
        productlist= products;
    }
    function getChunks() external view returns(Chunk[] memory chunklist){
        chunklist = chunks;
    }
    function getItems() external view returns(Item[] memory itemlist){
        itemlist= items;
    }
    function getDefectReports() external view returns(DefectReport[] memory reportlist){
        reportlist= defectReports;
    }
    function getSpoiledEntitiesOfDR(uint defectID) external view returns(ChainElement[] memory){
        return defectReports[defectID].spoiledEntities;
    }
    


    function getParticipant(address participant) external view returns(ROLE role){
        role = parties[participant];
    }

    function addParticipant(address participant, uint role) external onlyOwner{
        parties[participant] = ROLE(role);
    }

    function registerResource(string memory name) external {
        require(parties[msg.sender] == ROLE.Farm, "Sender is not a Farm.");
        Resource resourcetoadd = new Resource(resources.length, msg.sender, name);
        resources.push(resourcetoadd);
        /*
        console.log("Resources:");
        for(uint i = 0; i < resources.length; i++){
            console.logString(resources[i].getName());
        }
        */
    }

    function registerShipment(address from, address to, uint[] memory entityIDs) external{
        require(parties[msg.sender] == ROLE.Shipper, "Sender is not a Shipper.");
        require(parties[from] != ROLE.None, "Departure location is not a participant.");
        require(parties[to] != ROLE.None, "Arrival location is not a participant.");
        require( (parties[from] == ROLE.Farm && parties[to] == ROLE.Factory)
            || (parties[from] == ROLE.Factory && parties[to] == ROLE.Wholesaler)
            || (parties[from] == ROLE.Wholesaler && parties[to] == ROLE.Retailer) 
            , "Invalid route, only either of the following is possible: Farm -> Factory, Factory -> Wholesaler , Wholesaler -> Retailer");
        
        uint[] memory emptyElements;
        Shipment memory shipmenttoadd = Shipment(shipments.length, from, to, msg.sender, emptyElements);
        shipments.push(shipmenttoadd);
        for(uint i = 0; i < entityIDs.length; i++ ){
            addEntityToShipment(shipmenttoadd.ID, entityIDs[i]);
        }
        /*
        console.log("Shipments:");
        for(uint i = 0; i < shipments.length; i++){
            console.log("From: " , shipments[i].from, " , To: " ,  shipments[i].to);
        }
        */
    }

    function addEntityToShipment(uint shipmentID, uint entityID) private {
        
        ROLE roleOfDeparture = parties[shipments[shipmentID].from];
        require(msg.sender == shipments[shipmentID].shipper, "Only shipper of the shipment can add resource.");

        for(uint j = 0; j < shipments[shipmentID].elements.length; j++)
            require(shipments[shipmentID].elements[j] != entityID , "Entity is already added to shipment.");

        if(roleOfDeparture == ROLE.Farm){
            require(resources.length > entityID, "entityID out of bounds");
            require(resources[entityID].getOwner() == shipments[shipmentID].from , "The resource doesn't belong to the Farm you are trying to ship from.");
            require(!resources[entityID].isShipped() , "The entity is already shipped.");
            require(!resources[entityID].isSpoiled(), "The resource is spoiled!");
            shipments[shipmentID].elements.push(entityID);
            resources[entityID].setInShipment(shipmentID);
            resources[entityID].markShipped();
        }
        else if(roleOfDeparture == ROLE.Factory){
            require(products.length > entityID, "entityID out of bounds");
            require(products[entityID].getOwner() == shipments[shipmentID].from , "The product doesn't belong to the Factory you are trying to ship from.");
            require(!products[entityID].isShipped() , "The entity is already shipped.");
            require(!products[entityID].isSpoiled(), "The product is spoiled!");
            shipments[shipmentID].elements.push(entityID);
            products[entityID].setInShipment(shipmentID);
            products[entityID].markShipped();
        }
        else if(roleOfDeparture == ROLE.Wholesaler){
            require(chunks.length > entityID, "entityID out of bounds");
            require(chunks[entityID].getOwner() == shipments[shipmentID].from , "The chunk doesn't belong to the Wholesaler you are trying to ship from.");
            require(!chunks[entityID].isShipped() , "The entity is already shipped.");
            require(!chunks[entityID].isSpoiled(), "The chunk is spoiled!");
            shipments[shipmentID].elements.push(entityID);
            chunks[entityID].setInShipment(shipmentID);
            chunks[entityID].markShipped();
        }
        else{
            revert();
        }
    }

    function registerProduct(string memory name, uint[] memory entityIDs ) external{
        require(parties[msg.sender] == ROLE.Factory, "Only a Factory can register a product.");
        Product producttoadd = new Product(products.length, msg.sender, name);
        products.push(producttoadd);
        for(uint i = 0; i < entityIDs.length; i++ ){
            addResourceToProduct(producttoadd.getID(), entityIDs[i]);
        }
        /*
        console.log("Products:");
        for(uint i = 0; i < products.length; i++){
            console.logString(products[i].getName());
        }
        console.log("Resources in Product" , producttoadd.getName() ,  ": ");
        for(uint i = 0; i < producttoadd.getIngredients().length; i++){
            Resource resourceInProduct = resources[entityIDs[i]]; 
            console.logString(resourceInProduct.getName());
        }
        */
    }

    function addResourceToProduct(uint prodID, uint entityID) private{
        require(resources[entityID].isShipped(), "The resource has not yet been shipped.");
        require(!resources[entityID].isSpoiled(), "The resource is spoiled!");
        uint shipmentOfResource = resources[entityID].getInShipment();
        require(msg.sender == shipments[shipmentOfResource].to , "The Resource's shipping destination was a different Factory");
        products[prodID].addIngredient(entityID);
    }

    function splitProductToChunk(uint prodID, uint numOfChunks) external{
        require(parties[msg.sender] == ROLE.Wholesaler, "The sender must be a wholesaler.");
        address shippedTo = shipments[products[prodID].getInShipment()].to;
        require(products[prodID].isShipped() && shippedTo == msg.sender, "The product was not shipped to you.");
        require(!products[prodID].isSpoiled(), "The product is spoiled!");
        for(uint i = 0 ; i < numOfChunks ; i++){
            Chunk chunktoadd = new Chunk(chunks.length, msg.sender, products[prodID].getName(), prodID);
            chunks.push(chunktoadd);
        }

    }

    function splitChunkToItem(uint chunkID, uint numOfItems) external {
        require(parties[msg.sender] == ROLE.Retailer, "The sender must be a retailer");
        address shippedTo = shipments[chunks[chunkID].getInShipment()].to;
        require(chunks[chunkID].isShipped() && shippedTo == msg.sender, "The chunk was not shipped to you.");
        require(!chunks[chunkID].isSpoiled(), "The chunk is spoiled!");
        for(uint i = 0 ; i < numOfItems ; i++){
            Item itemtoadd = new Item(items.length, msg.sender, chunks[chunkID].getName(), chunkID);
            items.push(itemtoadd);
        }
    }


    /// ------------------------DEFECT REPORTS------------------------

    
    function reportDefectFarm(uint resourceID) external {
        DefectReport memory dr = createDefect(resourceID, ROLE.Farm);
        trackResourceToItem(resourceID, dr.ID);
    }

    function reportDefectShipmentToFactory(uint resourceID) external {
        DefectReport memory dr = createDefectShipment(resourceID, ROLE.Farm);
        trackResourceToItem(resourceID, dr.ID);
    }

    function reportDefectFactory(uint productID) external {
        DefectReport memory dr = createDefect(productID, ROLE.Factory);
        trackProductToItem(productID, dr.ID);
    }

    function reportDefectShipmentToWholesaler(uint productID) external {
        DefectReport memory dr = createDefectShipment(productID, ROLE.Factory);
        trackProductToItem(productID, dr.ID);
    }

    function reportDefectWholesaler(uint chunkID) external {
        DefectReport memory dr = createDefect(chunkID, ROLE.Wholesaler);
        trackChunkToItem(chunkID, dr.ID);
    }

    function reportDefectShipmentToRetailer(uint chunkID) external {
        DefectReport memory dr = createDefectShipment(chunkID, ROLE.Wholesaler);
        trackChunkToItem(chunkID, dr.ID);
    }

    function reportDefectRetailer(uint itemID) external {
        createDefect(itemID, ROLE.Retailer);
        items[itemID].markDefect();
        defectReports[defectReports.length-1].spoiledEntities.push(items[itemID]);
    }

    function createDefectShipment(uint elementID, ROLE role) private returns(DefectReport memory) {
        Shipment memory shipment;

        if(role == ROLE.Farm)
        {
            shipment = shipments[resources[elementID].getInShipment()];
        }
        else if(role == ROLE.Factory)
        {
            shipment = shipments[products[elementID].getInShipment()];
        }
        else if(role == ROLE.Wholesaler)
        {
            shipment = shipments[chunks[elementID].getInShipment()];
        }
        else
        {
            assert(false);
        }
        require(shipment.shipper == msg.sender 
             || shipment.to == msg.sender, "Only the Shipper of the element or the destination participant can report a shipment related defect.");

        ChainElement[] memory emptyElements;
        DefectReport memory defectReport = DefectReport( defectReports.length, elementID, shipment.shipper, msg.sender, emptyElements);
        defectReports.push(defectReport);
        
        return defectReport;
    }

    function createDefect(uint elementID, ROLE role) private returns(DefectReport memory) {
        require(parties[msg.sender] == role, "Wrong function called according to role.");
        if(role == ROLE.Farm)
        {
            require(msg.sender == resources[elementID].getOwner(), "Only the producer of the element can mark it.");
        }
        else if(role == ROLE.Factory)
        {
            require(msg.sender == products[elementID].getOwner(), "Only the producer of the element can mark it.");
        }
        else if(role == ROLE.Wholesaler)
        {
            require(msg.sender == chunks[elementID].getOwner(), "Only the producer of the element can mark it.");
        }
        else if(role == ROLE.Retailer)
        {
            require(msg.sender == items[elementID].getOwner(), "Only the producer of the element can mark it.");
        }
        else
        {
            assert(false);
        }
        ChainElement[] memory emptyElements;
        DefectReport memory defectReport = DefectReport( defectReports.length, elementID, msg.sender, msg.sender, emptyElements);
        defectReports.push(defectReport);
        
        return defectReport;
    }


    function trackChunkToItem(uint chunkID, uint reportID) private{
        chunks[chunkID].markDefect();
        defectReports[reportID].spoiledEntities.push(chunks[chunkID]);
        Shipment memory affectedShipment = shipments[chunks[chunkID].getInShipment()];
        Chunk chunktomark;
        for(uint i = 0; i < affectedShipment.elements.length ; i++)
        {
            chunktomark = chunks[affectedShipment.elements[i]];
            chunktomark.markDefect();
            defectReports[reportID].spoiledEntities.push(chunktomark);
            for(uint j = 0; j < items.length; j++)
            {
                if(items[j].getOrigin() == chunktomark.getID())
                {
                    items[j].markDefect();
                    defectReports[reportID].spoiledEntities.push(items[j]);
                }
            }
        }

    }

    function trackProductToItem(uint prodID, uint reportID) private{
        products[prodID].markDefect();
        defectReports[reportID].spoiledEntities.push(products[prodID]);
        Shipment memory affectedShipment = shipments[products[prodID].getInShipment()];
        Product producttomark;
        for(uint i = 0; i < affectedShipment.elements.length ; i++)
        {
            producttomark = products[affectedShipment.elements[i]];
            producttomark.markDefect();
            defectReports[reportID].spoiledEntities.push(producttomark);
            for(uint j = 0; j < chunks.length; j++)
            {
                if(chunks[j].getOrigin() == producttomark.getID())
                {
                    trackChunkToItem(j,reportID);
                }
            }
        }
    }

    function trackResourceToItem(uint resID, uint reportID) private{
        resources[resID].markDefect();
        defectReports[reportID].spoiledEntities.push(resources[resID]);
        Shipment memory affectedShipment = shipments[resources[resID].getInShipment()];
        Resource restomark;
        for(uint i = 0; i < affectedShipment.elements.length ; i++)
        {
            restomark = resources[affectedShipment.elements[i]];
            restomark.markDefect();
            defectReports[reportID].spoiledEntities.push(restomark);
            for(uint j = 0; j < products.length; j++)
            {
                if(products[j].getOwner() == affectedShipment.to)
                {
                    for(uint k = 0; k < products[j].getIngredients().length; k++)
                    {
                        if(products[j].getIngredients()[k] == restomark.getID())
                        {
                            trackProductToItem(j, reportID);
                        }
                    }
                }
            }
        }
    }
    
}