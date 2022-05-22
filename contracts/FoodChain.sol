// SPDX-License-Identifier: GPL

pragma solidity >=0.7.0 <0.9.0;

import "./Resource.sol";
import "./Product.sol";
import "./Chunk.sol";
import "./Item.sol";
import "./ChainElement.sol";

contract FoodChain {

    //A contract tulajdonosa, akinek joga van hozzáadni vagy törölni résztvevőket
    address owner;

    //A részvevők szerpe a rendszerben
    enum ROLE {
        None,
        Farm,
        Shipper,
        Factory,
        Wholesaler,
        Retailer
    }

    struct Shipment{
        uint ID; //Azonosító
        address from; //Honnan
        address to; //Hová
        address shipper; //Szállító címe
        uint[] elements; //Szállítmányban lévő elemek azonosítója
    }

    struct DefectReport{
        uint ID; //Azonosító
        uint entityID; //A hibásként megjelölt elem
        address source; //Akinél megjelent a hiba
        address issuer; //Aki bejelentette a hibát
        ChainElement[] spoiledEntities; //Az összes érintett entitás, amit hibásnak jelöl meg
    }

    mapping(address => ROLE)  parties; //Résztvevők
    Resource[] resources; 
    Shipment[] shipments;
    Product[] products;
    Chunk[] chunks;
    Item[] items;
    DefectReport[] defectReports;

    //Csak a rendszer tulajdonosa használhatja a függvényt
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        //A szerződést telepítő cím lesz a tulajdonos
        owner = msg.sender;
    }

    //Olvasó főggvények a tárolókhoz
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

    //Alapanyag regisztrálása egy tetszőleges névvel
    function registerResource(string memory name) external {
        require(parties[msg.sender] == ROLE.Farm, "Sender is not a Farm."); //Csak farm regisztrálhat alapanyagot
        Resource resourcetoadd = new Resource(resources.length, msg.sender, name);
        resources.push(resourcetoadd);
    }

    //Szállítmány regisztrálása kiindulási és célállapottal, illetve a szállított entitások azonosítójával
    function registerShipment(address from, address to, uint[] memory entityIDs) external{
        require(parties[msg.sender] == ROLE.Shipper, "Sender is not a Shipper."); //Csak szállító regisztrálhat
        require(parties[from] != ROLE.None, "Departure location is not a participant."); //Csak rendszeren belülről...
        require(parties[to] != ROLE.None, "Arrival location is not a participant."); //..belülre szállíthatunk
        //Csak a következő indulás->érkezés kombináció lehetséges
        //Farm->Factory , Factory->Wholesaler , Wholesaler->Retailer
        require( (parties[from] == ROLE.Farm && parties[to] == ROLE.Factory)
            || (parties[from] == ROLE.Factory && parties[to] == ROLE.Wholesaler)
            || (parties[from] == ROLE.Wholesaler && parties[to] == ROLE.Retailer) 
            , "Invalid route, only either of the following is possible: Farm -> Factory, Factory -> Wholesaler , Wholesaler -> Retailer");
        
        //Üres szállítmány létrehozása
        uint[] memory emptyElements;
        Shipment memory shipmenttoadd = Shipment(shipments.length, from, to, msg.sender, emptyElements);
        shipments.push(shipmenttoadd);
        //Az össze elem hozzáadása a szállítmányhoz
        for(uint i = 0; i < entityIDs.length; i++ ){
            addEntityToShipment(shipmenttoadd.ID, entityIDs[i]);
        }
    }

    //Entitás hozzáadása egy szállítmányhoz
    function addEntityToShipment(uint shipmentID, uint entityID) private {
        
        //Csak a szállítmány regisztrálója tud entitást hozzáadni
        ROLE roleOfDeparture = parties[shipments[shipmentID].from];
        require(msg.sender == shipments[shipmentID].shipper, "Only shipper of the shipment can add an entity.");

        //Egy entitást nem lehet többszöt hozzáadni egy szállítmányhoz
        for(uint j = 0; j < shipments[shipmentID].elements.length; j++)
            require(shipments[shipmentID].elements[j] != entityID , "Entity is already added to shipment.");

        //A három indulási lehetőség külön van kezelve
        if(roleOfDeparture == ROLE.Farm){
            require(resources.length > entityID, "entityID out of bounds"); //Érvénytelen ID
            require(resources[entityID].getOwner() == shipments[shipmentID].from , 
            "The resource doesn't belong to the Farm you are trying to ship from."); //A kiindulás helyéről származzon
            require(!resources[entityID].isShipped() , "The entity is already shipped."); //Ne legyen még szállítva
            require(!resources[entityID].isSpoiled(), "The resource is spoiled!"); //Romlott entitás nem mehet tovább
            shipments[shipmentID].elements.push(entityID); //A hozzáadás itt történik meg
            resources[entityID].setInShipment(shipmentID); //Az alapanyagban is beállítjuk, hogy melyik szállítmányban van
            resources[entityID].markShipped(); //Szállítva
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
            //Ha mégis rossz helyről indulna a szállítmány (nem jó részvevő) akkor visszagörgetjük
            revert();
        }
    }

    //Termék regiszrálás csak gyár által név és alapanyagok megadásával
    function registerProduct(string memory name, uint[] memory entityIDs ) external{
        require(parties[msg.sender] == ROLE.Factory, "Only a Factory can register a product.");
        Product producttoadd = new Product(products.length, msg.sender, name);
        products.push(producttoadd);
        for(uint i = 0; i < entityIDs.length; i++ ){
            addResourceToProduct(producttoadd.getID(), entityIDs[i]);
        }
    }

    //Alapanyag hozzáadása a regisztrált termékhez
    function addResourceToProduct(uint prodID, uint entityID) private{
        require(resources[entityID].isShipped(), "The resource has not yet been shipped.");
        require(!resources[entityID].isSpoiled(), "The resource is spoiled!");
        uint shipmentOfResource = resources[entityID].getInShipment();
        require(msg.sender == shipments[shipmentOfResource].to , "The Resource's shipping destination was a different Factory"); 
        products[prodID].addIngredient(entityID);
    }

    //A Wholesaler által termék szétbontása megadott számú chunkra
    function splitProductToChunk(uint prodID, uint numOfChunks) external{
        require(parties[msg.sender] == ROLE.Wholesaler, "The sender must be a wholesaler.");
        address shippedTo = shipments[products[prodID].getInShipment()].to;
        require(products[prodID].isShipped() && shippedTo == msg.sender, "The product was not shipped to you.");
        require(!products[prodID].isSpoiled(), "The product is spoiled!");
        for(uint i = 0 ; i < numOfChunks ; i++){
            //Ugyanaz lesz a neve, mint a terméknek, amiből készül
            Chunk chunktoadd = new Chunk(chunks.length, msg.sender, products[prodID].getName(), prodID);
            chunks.push(chunktoadd);
        }

    }

    //A Retailer által chunk szétbontása megadott számú végtermékre
    function splitChunkToItem(uint chunkID, uint numOfItems) external {
        require(parties[msg.sender] == ROLE.Retailer, "The sender must be a retailer");
        address shippedTo = shipments[chunks[chunkID].getInShipment()].to;
        require(chunks[chunkID].isShipped() && shippedTo == msg.sender, "The chunk was not shipped to you.");
        require(!chunks[chunkID].isSpoiled(), "The chunk is spoiled!");
        for(uint i = 0 ; i < numOfItems ; i++){
            //Végtermék neve megegyezik a chunk nevével, amiből készül
            Item itemtoadd = new Item(items.length, msg.sender, chunks[chunkID].getName(), chunkID);
            items.push(itemtoadd);
        }
    }


    /// ------------------------DEFECT REPORTS------------------------

    //Alapanyag hibájának jelentése farmon
    function reportDefectFarm(uint resourceID) external {
        DefectReport memory dr = createDefect(resourceID, ROLE.Farm);
        trackResourceToItem(resourceID, dr.ID);
    }

    //Alapanyag hibájának jelentése a szállítmányban
    function reportDefectShipmentToFactory(uint resourceID) external {
        DefectReport memory dr = createDefectShipment(resourceID, ROLE.Farm);
        trackResourceToItem(resourceID, dr.ID);
    }

    //Termék hibának jelentése a gyárban
    function reportDefectFactory(uint productID) external {
        DefectReport memory dr = createDefect(productID, ROLE.Factory);
        trackProductToItem(productID, dr.ID);
    }

    //Termék hibájának jelentése a szállítmányban
    function reportDefectShipmentToWholesaler(uint productID) external {
        DefectReport memory dr = createDefectShipment(productID, ROLE.Factory);
        trackProductToItem(productID, dr.ID);
    }

    //Chunk hibájának jelentése a nagykereskedőnél
    function reportDefectWholesaler(uint chunkID) external {
        DefectReport memory dr = createDefect(chunkID, ROLE.Wholesaler);
        trackChunkToItem(chunkID, dr.ID);
    }

    //Chunk hibájának jelentése a szállítmányban
    function reportDefectShipmentToRetailer(uint chunkID) external {
        DefectReport memory dr = createDefectShipment(chunkID, ROLE.Wholesaler);
        trackChunkToItem(chunkID, dr.ID);
    }

    //Végtermék hibájának jelentése a viszonteladónál
    function reportDefectRetailer(uint itemID) external {
        createDefect(itemID, ROLE.Retailer);
        items[itemID].markDefect();
        defectReports[defectReports.length-1].spoiledEntities.push(items[itemID]);
    }

    /// ------------------------HELPER FUNCTIONS------------------------

    //A szállítmányban való hibamegjelölés segédfüggvénye
    function createDefectShipment(uint elementID, ROLE role) private returns(DefectReport memory) {
        Shipment memory shipment;

        //A kiinduló állomástól függően meghatározza, hogy melyik szállítmányt érinti a hiba
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
        //Csak a szállító, illetve a cél résztvevő jelenthet szállítmány hibát.
        require(shipment.shipper == msg.sender 
             || shipment.to == msg.sender, "Only the Shipper of the element or the destination participant can report a shipment related defect.");

        //Hiba jelentés elkészítése és inicializálása. A "track" kezdetű függvények töltik majd fel a potenciálisan hibás entitásokkal.
        ChainElement[] memory emptyElements;
        DefectReport memory defectReport = DefectReport( defectReports.length, elementID, shipment.shipper, msg.sender, emptyElements);
        defectReports.push(defectReport);
        
        return defectReport;
    }

    //A gyártás helyénél való megjelölés segédfüggvénye
    function createDefect(uint elementID, ROLE role) private returns(DefectReport memory) {
        //Itt ellenőrizzük, hogy a szerep szerint megfelelő hibabejelentő függvényt hívta-e
        require(parties[msg.sender] == role, "Wrong function called according to role.");
        //Csak a tulajdonosa jelölhet meg hibásként egy entitást
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

        //Hiba jelentés elkészítése és inicializálása. A "track" kezdetű függvények töltik majd fel a potenciálisan hibás entitásokkal.
        ChainElement[] memory emptyElements;
        DefectReport memory defectReport = DefectReport( defectReports.length, elementID, msg.sender, msg.sender, emptyElements);
        defectReports.push(defectReport);
        
        return defectReport;
    }

    /// ------------------------DEFECT TRACKING------------------------

    //Chunk megjelölése hibásként, majd az összes potenciálisan hibás chunk és végtermék megjelölése
    function trackChunkToItem(uint chunkID, uint reportID) private{
        //eredeti hibás chunk megjelölése 
        chunks[chunkID].markDefect();
        //hozzáadása a DefectReport objektumhoz
        defectReports[reportID].spoiledEntities.push(chunks[chunkID]);
        //A chunk szállítmányának meghatározása
        Shipment memory affectedShipment = shipments[chunks[chunkID].getInShipment()];
        Chunk chunktomark;
        //Az összes chunk hibásként megjelölése, ami az eredetivel együtt utazott
        for(uint i = 0; i < affectedShipment.elements.length ; i++)
        {
            chunktomark = chunks[affectedShipment.elements[i]];
            chunktomark.markDefect();
            defectReports[reportID].spoiledEntities.push(chunktomark);
            //Minden végtermék ellenőrzése, hogy az éppen megjelölt chunkból készült-e...
            for(uint j = 0; j < items.length; j++)
            {
                if(items[j].getOrigin() == chunktomark.getID())
                {
                    //... ha igen, akkor azt is megjelöljük és hozzáadjuk a DefectReporthoz
                    items[j].markDefect();
                    defectReports[reportID].spoiledEntities.push(items[j]);
                }
            }
        }

    }

    //Termék megjelölése hibásként, majd az összes potenciálisan hibás termék, chunk és végtermék megjelölése
    function trackProductToItem(uint prodID, uint reportID) private{
        //eredetileg hibás termék megjelölése
        products[prodID].markDefect();
        defectReports[reportID].spoiledEntities.push(products[prodID]);
        //a termék szállítmányának meghatározása
        Shipment memory affectedShipment = shipments[products[prodID].getInShipment()];
        Product producttomark;
        //A szállítmányban minden más termék megjelölése
        for(uint i = 0; i < affectedShipment.elements.length ; i++)
        {
            producttomark = products[affectedShipment.elements[i]];
            producttomark.markDefect();
            defectReports[reportID].spoiledEntities.push(producttomark);
            //Az összes chunk megvizsgálása, hogy melyik készült az éppen megjelölt termékből
            for(uint j = 0; j < chunks.length; j++)
            {
                //Ha az éppen megjelölt termékből készült, akkor tovább követjük a hibát a láncon
                if(chunks[j].getOrigin() == producttomark.getID())
                {
                    trackChunkToItem(j,reportID);
                }
            }
        }
    }

    //Alapanyag megjelölése hibásként, majd az összes potenciálisan hibás alapanyag, termék, chunk és végtermék megjelölése
    function trackResourceToItem(uint resID, uint reportID) private{
        //eredetileg hibás alapanyag megjelölése
        resources[resID].markDefect();
        defectReports[reportID].spoiledEntities.push(resources[resID]);
         //az alapanyag szállítmányának meghatározása
        Shipment memory affectedShipment = shipments[resources[resID].getInShipment()];
        Resource restomark;
        //A szállítmányban minden más alapanyag megjelölése
        for(uint i = 0; i < affectedShipment.elements.length ; i++)
        {
            restomark = resources[affectedShipment.elements[i]];
            restomark.markDefect();
            defectReports[reportID].spoiledEntities.push(restomark);

            for(uint j = 0; j < products.length; j++)
            {
                //minden termék vizsgálata, ha azonos helyre érkezett, mint a hibás szállítmány
                if(products[j].getOwner() == affectedShipment.to)
                {
                    for(uint k = 0; k < products[j].getIngredients().length; k++)
                    {
                        //Ha a termék egyik alapanyaga éppen hibásnak lett megjelölve, akkor a termék is hibás lesz
                        //majd tovább követjük a hibát a láncon
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