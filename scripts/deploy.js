const main = async () => {
    const domainContractFactory = await hre.ethers.getContractFactory('Domains');
    const domainContract = await domainContractFactory.deploy("spark");
    await domainContract.deployed();

    console.log("Contract deployed to:", domainContract.address);

    let txn = await domainContract.register("fran", {
        value: hre.ethers.utils.parseEther('0.3')
    });
    await txn.wait();
    console.log("Minted domain");

    txn = await domainContract.setRecord("spark", "Spark Technologies");
    await txn.wait();
    console.log("Set record");

    const address = await domainContract.getAddress("fran");
    console.log("Owner of domain:", address);

    const balance = await hre.ethers.provider.getBalance(domainContract.address);
    console.log("Contract balance:", hre.ethers.utils.formatEther(balance));
}

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
};

runMain();