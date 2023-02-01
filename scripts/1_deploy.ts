import { ethers, network, run } from "hardhat";

const main = async () => {
  try {
    const Parent = await ethers.getContractFactory("ParentTemplates");
    const Child = await ethers.getContractFactory("ChildTemplates");

    const child = await Child.deploy("ChildTemplates", "CTFGO");
    const parent = await Parent.deploy(child.address);

    const WAIT_BLOCK_CONFIRMATIONS = 6;

    child.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    parent.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);

    console.log(`Parent Templates Contract deployed at\n${parent.address}`);
    console.log(`Child Templates Contract deployed at\n${child.address}`);

    await run(`verify:Child`, {
      address: child.address,
      constructorArguments: ["ChildTemplates", "CTFGO"],
    });

    await run(`verify:Parent`, {
      address: parent.address,
      constructorArguments: [child.address],
    });
  } catch (err: any) {
    console.error(err.message);
  }
};

main();
