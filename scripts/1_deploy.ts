const { ethers } = require("hardhat");

const main = async () => {
  try {
    const [deployer] = await ethers.getSigners();
    const Parent = await ethers.getContractFactory("ParentTemplates");
    // const Child = await ethers.getContractFactory("ChildTemplates");
    const parent = await Parent.deploy(
      "0x991677668f2b17712f2c20c87B8c31901e85C560"
    );
    console.log(`Parent Contract deployed at\n${parent.address}`);
    // const child = await Child.deploy("ChildTemplates", "CTFGO");
    // console.log(`Child Contract deployed at\n${child.address}`);
  } catch (err: any) {
    console.error(err.message);
  }
};

main();
