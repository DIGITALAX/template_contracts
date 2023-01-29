import { expect } from "chai";
import { ethers } from "hardhat";
import { imageURI, parentURI, svg } from "../lib/constants";

describe("Parent FGO Test Suite", () => {
  let parent: any,
    child: any,
    childTokens: any,
    deployer: any,
    second: any,
    ids: any[];
  beforeEach("deploy Contracts", async () => {
    [deployer, second] = await ethers.getSigners();
    const Child = await ethers.getContractFactory("ChildTemplates");
    child = await Child.deploy("ChildTemplates", "CFGO");
    const Parent = await ethers.getContractFactory("ParentTemplates");
    parent = await Parent.deploy(child.address);

    // mint some child tokens to use
    await child.connect(deployer).mint(deployer.address, 1, svg, "leftArm");
    await child.connect(deployer).mint(deployer.address, 1, svg, "rightArm");
  });

  describe("constructor & deployment", () => {
    it("name of contract", async () => {
      expect(await parent.name()).to.equal("ParentTemplates");
    });

    it("symbol of contract", async () => {
      expect(await parent.symbol()).to.equal("PTFGO");
    });

    it("child contract", async () => {
      expect(await parent.childContract()).to.equal(child.address);
    });

    it("total supply at 0", async () => {
      expect(await parent.totalSupply()).to.equal(0);
    });
  });

  describe("mint token", () => {
    let result_single: any;

    beforeEach("mint parent token", async () => {
      const transaction_single = await parent
        .connect(deployer)
        .createTemplate(svg, [1, 2], "long sleeve jacket");
      result_single = await transaction_single.wait();
    });

    it("increases tokenid", async () => {
      expect(await parent.totalSupply()).to.equal(1);
    });

    it("emits event", async () => {
      (expect(result_single).to as any)
        .emit("ParentTemplateCreated")
        .withArgs(1, parentURI);
    });

    it("uri exists", async () => {
      expect(await parent.tokenIdToURI(1)).to.exist;
    });

    it("template uri values", async () => {
      const {
        _name,
        _tokenId,
        _imageURI,
      }: {
        _name: string;
        _tokenId: string;
        _imageURI: string;
      } = {
        ...(await parent.tokenIdToTemplate(1)),
      };

     const _childTokenIds = await parent.parentChildTokens(_tokenId);

      expect(_name).to.equal("long sleeve jacket");
      expect(_tokenId).to.equal(String(1));
      expect(_imageURI).to.equal(imageURI);
      expect(_childTokenIds).to.equal([1, 2]);
    });
  });

  describe("update uri", () => {});

  describe("transfer token", () => {});

  describe("burn token", () => {});
});
