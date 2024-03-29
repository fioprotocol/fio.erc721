const FIONFT = artifacts.require("FIONFT");

let registeredOracles;
const oraclePubKey = "0xFC5951F15085B0245407332EEFe6B20315395382";
const custodianPubKeys = [
    "0x825abC908237521012d8e5Dff76Bfe7cb7c0140c",
    "0x8c796f8ECfc49020ECB92eE9bb2da7E91b92A3F7",
    "0x53d1C568085d9B87439532e828DB94f96EF11B36",
    "0xF7b5EaDD2F36Cc86066916c231FCbF9010b2C4F5",
    "0x8c97730Dbd3894b0fB50905aDabF34401c0E1E3e",
    "0xC1B7E208Ea318347d6E399ded98C4d5e78AC97cA",
    "0x74036589F9E1150fb80a4DC9918B67df15307cAA",
    "0xc31ddff97fC50ec0A045C940419fbf45b8EB2A38",
    "0x89BdE6E6b7503A49075F2D1609c6dF1d0E1F11C0",
    "0xC6770f6B7308Cc0b379D5A054A4a85aC85C2cFE4"
];

module.exports = async (callback) => {
    let fionft;
    fionft = await FIONFT.deployed();

    try {
        const fionftAddress = await fionft.address;
        console.log('wfio contract address: ', fionftAddress);
    } catch (error) {
        console.log('Contract address error: ', error);
    }

    for (const i in custodianPubKeys) {
        try {
            await fionft.regoracle(oraclePubKey, {from: custodianPubKeys[i]});
            console.log(`Success: Custodian ${custodianPubKeys[i]} registered ${oraclePubKey}`);
        } catch (error) {
            console.log(`Failure: Custodian ${custodianPubKeys[i]} registering ${oraclePubKey}: ${error} `);
        }
    }

    try {
        registeredOracles = await fionft.getOracles();
        console.log('Registered Oracle: ', registeredOracles);
    } catch (err) {
        console.log('getOracles Error: ', err);
    }

    callback();
}