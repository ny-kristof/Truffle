const FoodChain = artifacts.require("./FoodChain.sol");
const ChainElement = artifacts.require("./ChainElement.sol");
const Resource  = artifacts.require("./Resource.sol");
const Product  = artifacts.require("./Product.sol");
const Chunk  = artifacts.require("./Chunk.sol");
const Item  = artifacts.require("./Item.sol");

contract("Test FoodChain defect report2", accounts => {
    let foodChaininstance = null;
    let owner = null;
    let farm1 = null;
    let factory1 = null;
    let shipper1 = null;
    let farm2 = null;
    let wholesaler1 = null;
    let retailer1 = null;

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
        await foodChaininstance.registerProduct("repasbrokkolispite", [3,4] ,  { from: factory1 });

        await foodChaininstance.registerShipment(factory1, wholesaler1, [0] ,  { from: shipper1 });
        await foodChaininstance.registerShipment(factory1, wholesaler1, [1] ,  { from: shipper1 });

        await foodChaininstance.splitProductToChunk( 0, 3 ,  { from: wholesaler1 });
        await foodChaininstance.splitProductToChunk( 1, 5 ,  { from: wholesaler1 });

        await foodChaininstance.registerShipment(wholesaler1, retailer1, [1,2] ,  { from: shipper1 });

        await foodChaininstance.splitChunkToItem( 1, 2 ,  { from: retailer1 });
      });

      it("should mark Banan spoiled Shipper1.", async () => {
        await foodChaininstance.reportDefectShipmentToFactory(0 , {from: shipper1 });
        const defectreports = await foodChaininstance.getDefectReports.call();
        /*
        const defectreport = await defectreports[0];
        //const defectreport = await DefectReport.at(defectreportaddress);
        const spoiledentities = await foodChaininstance.getSpoiledEntitiesOfDR(0);
        */
        
        const itemlist = await foodChaininstance.getItems.call();
        const itemaddress = await itemlist[1];
        const item = await Item.at(itemaddress);

        const chunklist = await foodChaininstance.getChunks.call();
        const chunkaddress = await chunklist[5];
        const chunk = await Chunk.at(chunkaddress);
    
        const productlist = await foodChaininstance.getProducts.call();
        const productaddress0 = await productlist[0];
        const productaddress1 = await productlist[1];
        const product0 = await Product.at(productaddress0);
        const product1 = await Product.at(productaddress1);
    
        const resourcelist = await foodChaininstance.getResources.call();
        const resourceaddress = await resourcelist[3];
        const resourceaddress2 = await resourcelist[2];
        const repa = await Product.at(resourceaddress);
        const banan = await Product.at(resourceaddress2);
    
        assert.equal(await defectreports.length , 1 , "There should be a registered defect report.");
        assert(await product0.isSpoiled(), "The first product should be spoiled");
        assert.equal(await product1.isSpoiled(), false, "The second product should NOT be spoiled");
        assert.equal(await chunk.isSpoiled(), false ,  "The fifth chunk should not be spoiled.");
        assert(await item.isSpoiled(), "The second item should be spoiled");
        assert.equal(await repa.isSpoiled(), false ,  "The fourth resource (repa) should not be spoiled");
        assert(await banan.isSpoiled(),   "The third resource (banan) should be spoiled");
    
      });

      it("should NOT register another product from Alma.", async () => {
        try {
          await foodChaininstance.registerProduct("almasceklaspite", [0,5] ,  { from: factory1 });
        } catch (error) {
          assert(error.message.includes("The resource is spoiled!") , "Alma is spoiled, no product registration allowed.");
          return;
        }
        assert(false, "New product from spoiled entity is registered.");
      });

      it("should NOT split the product into chunks.", async () => {
        try {
          await foodChaininstance.splitProductToChunk( 0, 3 ,  { from: wholesaler1 });
        } catch (error) {
          assert(error.message.includes("The product is spoiled!") , "The product is spoiled, no splitting allowed.");
          return;
        }
        assert(false, "New chunk from spoiled product is registered.");
      });

});