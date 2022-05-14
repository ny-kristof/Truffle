const FoodChain = artifacts.require("./FoodChain.sol");
const ChainElement = artifacts.require("./ChainElement.sol");
const Resource  = artifacts.require("./Resource.sol");
const Product  = artifacts.require("./Product.sol");
const Chunk  = artifacts.require("./Chunk.sol");
const Item  = artifacts.require("./Item.sol");

contract("Test FoodChain forward", accounts => {

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
  });

  it("should register the accouts.", async () => {
    await foodChaininstance.addParticipant(farm1, 1, { from: owner });
    await foodChaininstance.addParticipant(factory1, 3, { from: owner });
    await foodChaininstance.addParticipant(shipper1, 2, { from: owner });
    await foodChaininstance.addParticipant(farm2, 1, { from: owner });
    await foodChaininstance.addParticipant(wholesaler1, 4, { from: owner });
    await foodChaininstance.addParticipant(retailer1, 5, { from: owner });
    assert.equal(await foodChaininstance.getParticipant(farm1), 1 , "Farm not registered as a farm");
    assert.equal(await foodChaininstance.getParticipant(factory1), 3 , "Factory not registered as a factory");
    assert.equal(await foodChaininstance.getParticipant(shipper1), 2 , "Shipper not registered as a shipper");
    assert.equal(await foodChaininstance.getParticipant(farm2), 1 , "Farm2 not registered as a farm");
    assert.equal(await foodChaininstance.getParticipant(wholesaler1), 4 , "Wholesaler not registered as a wholesaler");
    assert.equal(await foodChaininstance.getParticipant(retailer1), 5 , "Retailer not registered as a retailer");
  });

  it("should NOT register another farm." , async () =>{
    try {
      await foodChaininstance.addParticipant(farm2, 1, {from: farm1});
    } catch (error) {
      assert(true, "Farm2 has not been registered -> only the owner can register");
      return;
    }
    assert(false, "Farm2 has been registered.");
  });

  it("should register the resources from Farm1.", async () => {
    const names = ["alma", "korte", "banan"];
    await foodChaininstance.registerResource(names[0], { from: farm1 });
    await foodChaininstance.registerResource(names[1], { from: farm1 });
    await foodChaininstance.registerResource(names[2], { from: farm1 });
    const resourcesarray = await foodChaininstance.getResources.call();
    assert.equal( await resourcesarray.length, 3 , "There should be 3 resources." );
  });

  it("should register the resources from Farm2.", async () => {
    const names = ["repa", "brokkoli", "cekla"];
    await foodChaininstance.registerResource(names[0], { from: farm2 });
    await foodChaininstance.registerResource(names[1], { from: farm2 });
    await foodChaininstance.registerResource(names[2], { from: farm2 });
    const resourcesarray = await foodChaininstance.getResources.call();
    assert.equal( await resourcesarray.length, 6 , "There should be 6 resources now." );
  });

  it("should register a shipment from Farm1 to Factory1.", async () => {
    await foodChaininstance.registerShipment(farm1, factory1, [0,2] ,  { from: shipper1 });
    const shipmentssarray = await foodChaininstance.getShipments.call();
    assert.equal( await shipmentssarray.length, 1 , "There should be a registered shipment." );
  });

  it("should register a shipment from Farm2 to Factory1.", async () => {
    await foodChaininstance.registerShipment(farm2, factory1, [3,4] ,  { from: shipper1 });
    const shipmentssarray = await foodChaininstance.getShipments.call();
    assert.equal( await shipmentssarray.length, 2 , "There should be two registered shipments." );
  });

  it("should register a product Factory1.", async () => {
    await foodChaininstance.registerProduct("almasbananospite", [0,2] ,  { from: factory1 });
    const productsarray = await foodChaininstance.getProducts.call();
    assert.equal( await productsarray.length, 1 , "There should be a registered product." );
  });

  it("should NOT register a product Factory1.", async () => {
    try {
      await foodChaininstance.registerProduct("repasceklaspite", [3, 5] ,  { from: factory1 });
    } catch (error) {
      assert(error.message.includes("The resource has not yet been shipped.") , "Cekla has not yet been shipped to Factory1");
      return;
    }
    assert(false, "New product from not shipped entity is registered.");
  });

  it("should register a shipment from Factory1 to Wholesaler1.", async () => {
    await foodChaininstance.registerShipment(factory1, wholesaler1, [0] ,  { from: shipper1 });
    const shipmentssarray = await foodChaininstance.getShipments.call();
    assert.equal( await shipmentssarray.length, 3 , "There should be three registered shipments." );
  });

  it("should split a product to 3 chunks Wholesaler1.", async () => {
    await foodChaininstance.splitProductToChunk( 0, 3 ,  { from: wholesaler1 });
    const chunkarray = await foodChaininstance.getChunks.call();
    const firstchunk = await chunkarray[0];
    let chunk = await Resource.at(firstchunk);
    const name = await chunk.getName.call();
    assert.equal( await chunkarray.length, 3 , "There should be 3 registered chunks." );
    assert.equal(name, "almasbananospite" , "The names should match." );
  });

  it("should register a shipment from Wholesaler1 to Reatailer1.", async () => {
    await foodChaininstance.registerShipment(wholesaler1, retailer1, [1,2] ,  { from: shipper1 });
    const shipmentssarray = await foodChaininstance.getShipments.call();
    assert.equal( await shipmentssarray.length, 4 , "There should be four registered shipments." );
    let chunkarray = await foodChaininstance.getChunks.call();
    let chunkaddress1 = await chunkarray[1];
    let chunk1 = await Chunk.at(chunkaddress1);
    let chunkaddress2 = await chunkarray[2];
    let chunk2 = await Chunk.at(chunkaddress2);
    assert(await chunk2.isShipped(), "The second chunk should be shipped.");
    assert.equal(await chunk1.getInShipment(), 3, "The first chunk should be in the fourth shipment.");
  });

  it("should split a chunk to 2 items Retailer1.", async () => {
    await foodChaininstance.splitChunkToItem( 1, 2 ,  { from: retailer1 });
    const itemarray = await foodChaininstance.getItems.call();
    const seconditem = await itemarray[1];
    let item = await Item.at(seconditem);
    const name = await item.getName.call();
    const owner = await item.getOwner.call();
    assert.equal( await itemarray.length, 2 , "There should be 2 registered items." );
    assert.equal(name, "almasbananospite" , "The names should match." );
    assert.equal(owner, accounts[6], "The owner should be the retailer." );
  });

  it("should mark the item spoiled Retailer1.", async () => {
    await foodChaininstance.reportDefectShipmentToRetailer(1 , {from: shipper1 });
    const defectreports = await foodChaininstance.getDefectReports.call();
    const defectreport = await defectreports[0];
    //const defectreport = await DefectReport.at(defectreportaddress);
    const spoiledentities = await foodChaininstance.getSpoiledEntitiesOfDR(0);

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
    assert(await item.isSpoiled(), "The second item should be spoiled");
    assert.equal(await resource.isSpoiled(), false ,  "The fourth resource (repa) should not be spoiled");

  });

});