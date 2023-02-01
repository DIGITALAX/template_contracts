import { ethers, network, run } from "hardhat";

const main = async () => {
  try {
    // const Parent = await ethers.getContractFactory("ParentTemplates");
    // const Child = await ethers.getContractFactory("ChildTemplates");

    // const child = await Child.deploy("ChildTemplates", "CTFGO");
    // const parent = await Parent.deploy(child.address);

    // const WAIT_BLOCK_CONFIRMATIONS = 20;

    // child.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // parent.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);

    // console.log(`Parent Templates Contract deployed at\n${parent.address}`);
    // console.log(`Child Templates Contract deployed at\n${child.address}`);

    await run(`verify:verify`, {
      address: "0xC1D06Ea0AFEBADC943708239Aa7642fA93B955E0",
      constructorArguments: ["ChildTemplates", "CTFGO"],
    });

    await run(`verify:verify`, {
      address: "0x6Eba8878953de820FCb98Ba795FC05a90f30e0b7",
      constructorArguments: ["0xC1D06Ea0AFEBADC943708239Aa7642fA93B955E0"],
    });
  } catch (err: any) {
    console.error(err.message);
  }
};

main();
