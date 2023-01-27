const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Child FGO Test Suite", () => {
  let parent;
  beforeEach("deploy Contracts", async () => {
    const Child = await ethers.getContractFactory("ParentTemplates");
    child = await Child.deploy();
  });

  describe("create template struct", () => {});

  describe("only owner permissions", () => {});

  describe("mint token", () => {});

  describe("update uri", () => {});

  describe("transfer token", () => {});

  describe("burn token", () => {});
});
