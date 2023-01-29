import { expect } from "chai";
import {ethers} from "hardhat";

describe("Parent FGO Test Suite", () => {
  let parent: any, child: any;
  beforeEach("deploy Contracts", async () => {
    const Parent = await ethers.getContractFactory("ParentTemplates");
    parent = await Parent.deploy();
    const Child = await ethers.getContractFactory("ParentTemplates");
    child = await Child.deploy();
  });

  describe("deployment", () => {
    it("total supply at 0", async () => {
      expect(await parent.totalSupply()).to.equal(0);
    });
  });

  describe("create template struct", () => {});

  describe("only owner permissions", () => {});

  describe("mint token", () => {});

  describe("update uri", () => {});

  describe("transfer token", () => {});

  describe("burn token", () => {});
});
