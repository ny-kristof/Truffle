const FoodChain = artifacts.require("./FoodChain.sol");
const ChainElement = artifacts.require("./ChainElement.sol");
const Resource  = artifacts.require("./Resource.sol");
const Product  = artifacts.require("./Product.sol");
const Chunk  = artifacts.require("./Chunk.sol");
const Item  = artifacts.require("./Item.sol");

contract("Test FoodChain defect report", accounts => {
    let foodChaininstance = null;
    let owner = null;
    let farm1 = null;
    let factory1 = null;
    let shipper1 = null;
    let farm2 = null;
    let wholesaler1 = null;
    let retailer1 = null;

    //A 'Test FoodChain Forward'-ban tesztelt állapot előállítása
    before(async () => {
        foodChaininstance = await FoodChain.deployed();
    
        owner = accounts[0];
        farm1 = accounts[1];
        factory1 = accounts[2];
        shipper1 = accounts[3];
        farm2 = accounts[4];
        wholesaler1 = accounts[5];
        retailer1 = accounts[6];

        await foodChaininstance.addParticipant(farm1, 1, { from: owner });
        await foodChaininstance.addParticipant(factory1, 3, { from: owner });
        await foodChaininstance.addParticipant(shipper1, 2, { from: owner });
        await foodChaininstance.addParticipant(farm2, 1, { from: owner });
        await foodChaininstance.addParticipant(wholesaler1, 4, { from: owner });
        await foodChaininstance.addParticipant(retailer1, 5, { from: owner });

        let names = ["alma", "korte", "banan"];
        await foodChaininstance.registerResource(names[0], { from: farm1 });
        await foodChaininstance.registerResource(names[1], { from: farm1 });
        await foodChaininstance.registerResource(names[2], { from: farm1 });

        names = ["repa", "brokkoli", "cekla"];
        await foodChaininstance.registerResource(names[0], { from: farm2 });
        await foodChaininstance.registerResource(names[1], { from: farm2 });
        await foodChaininstance.registerResource(names[2], { from: farm2 });

        await foodChaininstance.registerShipment(farm1, factory1, [0,2] ,  { from: shipper1 });
        await foodChaininstance.registerShipment(farm2, factory1, [3,4] ,  { from: shipper1 });

        await foodChaininstance.registerProduct("almasbananospite", [0,2] ,  { from: factory1 });

        await foodChaininstance.registerShipment(factory1, wholesaler1, [0] ,  { from: shipper1 });

        await foodChaininstance.splitProductToChunk( 0, 3 ,  { from: wholesaler1 });

        await foodChaininstance.registerShipment(wholesaler1, retailer1, [1,2] ,  { from: shipper1 });

        await foodChaininstance.splitChunkToItem( 1, 2 ,  { from: retailer1 });
      });

      //Legrosszabb eset tesztelése, amikor már végig haladt a láncon az alapanyag, de megjelöli hibásként a farmja
      it("should mark Alma (id: 0) spoiled Farm1.", async () => {
        await foodChaininstance.reportDefectFarm(0 , {from: farm1 });
        //segédváltozók az ellenőrzéshez
        const defectreports = await foodChaininstance.getDefectReports.call();

        const itemlist = await foodChaininstance.getItems.call();
        const itemaddress = await itemlist[1];
        const item = await Item.at(itemaddress);
    
        const productlist = await foodChaininstance.getProducts.call();
        const productaddress = await productlist[0];
        const product = await Product.at(productaddress);
    
        const resourcelist = await foodChaininstance.getResources.call();
        const resourceaddress = await resourcelist[3];
        const resource = await Product.at(resourceaddress);
    
        assert.equal(await defectreports.length , 1 , "There should be a registered defect report.");
        assert(await product.isSpoiled(), "The first product should be spoiled");
        assert(await item.isSpoiled(), "The second item should be spoiled");
        assert.equal(await resource.isSpoiled(), false ,  "The fourth resource (repa) should not be spoiled");
      });


});