import { expect } from "chai";
import { ethers } from "hardhat";
import { formatURI, imageURI, svg } from "../lib/constants";

describe("Child FGO Test Suite", () => {
  let deployer: any, child: any, second: any, parent: any;
  beforeEach("deploy Contracts", async () => {
    [deployer, second] = await ethers.getSigners();
    const Child = await ethers.getContractFactory("ChildTemplates");
    child = await Child.deploy("ChildTemplates", "CFGO");
    const Parent = await ethers.getContractFactory("ParentTemplates");
    parent = await Parent.deploy(child.address);
    await child.addParentContract(parent.address);
  });

  describe("constructor", () => {
    it("returns name and symbol", async () => {
      expect(await child.name()).to.equal("ChildTemplates");
      expect(await child.symbol()).to.equal("CFGO");
    });
  });

  describe("ids", () => {
    it("set to 0", async () => {
      expect(await child.tokenIdPointer()).to.equal(0);
    });

    it("not exists at 0", async () => {
      await (expect(child.tokenExists([0])).to.be as any).revertedWith(
        "Token Id has not yet been minted"
      );
    });

    it("not exists at 1", async () => {
      await (expect(child.tokenExists([1])).to.be as any).revertedWith(
        "Token Id has not yet been minted"
      );
    });
  });

  describe("mint token", () => {
    let result_single: any, result_multi: any;
    beforeEach("mint token", async () => {
      const transaction_single = await child
        .connect(deployer)
        .mint(deployer.address, 1, svg, "leftArm");
      result_single = await transaction_single.wait();
      const transaction_multi = await child
        .connect(deployer)
        .mintBatch(deployer.address, [1], [svg], ["leftArm"]);
      result_multi = await transaction_multi.wait();
    });

    describe("mint functionality", () => {
      it("token id increases", async () => {
        expect(await child.tokenIdPointer()).to.equal(2);
      });

      it("has an amount of 1", async () => {
        expect(await child.tokenIdToAmount(1)).to.equal(1);
      });

      it("token exists", async () => {
        expect(await child.tokenExists([1])).to.equal(true);
      });

      it("template uri values", async () => {
        const {
          _name,
          _tokenId,
          _imageURI,
          _amount,
        }: {
          _name: string;
          _tokenId: string;
          _imageURI: string;
          _amount: string;
        } = {
          ...(await child.tokenIdToTemplate(1)),
        };

        expect(_name).to.equal("leftArm");
        expect(_amount).to.equal(String(1));
        expect(_tokenId).to.equal(String(1));
        expect(_imageURI).to.equal(imageURI);
      });

      it("uri exists", async () => {
        expect(await child.tokenIdToURI(1)).to.exist;
      });

      it("emits template created event", async () => {
        (expect(result_single).to as any)
          .emit("ChildTemplateCreated")
          .withArgs(1, formatURI);
      });
    });

    describe("transfer tokens", () => {
      let single_result: any, multi_result: any;
      beforeEach("transfer", async () => {
        // const transaction_single = await child
        //   .connect(deployer)
        //   .safeTransferFrom(deployer.address, second.address, 1, 1, 0x00);
        // single_result = transaction_single.wait();
        // const transaction_multi = await child
        //   .connect(deployer)
        //   .safeBatchTransferFrom(
        //     deployer.address,
        //     second.address,
        //     [2],
        //     [1],
        //     0x00
        //   );
        // multi_result = transaction_multi.wait();
      });

      it("transfers one token", async () => {
        (expect(single_result).to as any)
          .emit("TransferSingle")
          .withArgs(deployer.address, deployer.address, second.address, 1, 1);
      });

      it("has a new owner single", async () => {
        expect(await child.tokenIdToOwner(1)).to.equal(second.address);
      });

      it("batch transfer tokens", async () => {
        (expect(multi_result).to as any)
          .emit("TransferBatch")
          .withArgs(
            deployer.address,
            deployer.address,
            second.address,
            [2],
            [1]
          );
      });

      it("has a new owner batch", async () => {
        expect(await child.tokenIdToOwner(2)).to.equal(second.address);
      });
    });

    describe("burn tokens", () => {
      let single_result: any, multi_result: any;
      beforeEach("burn", async () => {
        const transaction_single = await child.connect(deployer)._burn(1, 1);
        single_result = transaction_single.wait();
        const transaction_multi = await child
          .connect(deployer)
          ._burnBatch([2], [1]);
        multi_result = transaction_multi.wait();
      });

      it("burns one token", async () => {
        (expect(single_result).to as any)
          .emit("TransferSingle")
          .withArgs(
            deployer.address,
            deployer.address,
            0x0000000000000000000000000000000000000000,
            1,
            1
          );
      });

      it("has a new owner", async () => {
        expect(await child.tokenIdToOwner(1)).to.equal("0x" + "0".repeat(40));
      });

      it("batch burn tokens", async () => {
        (expect(multi_result).to as any)
          .emit("TransferBatch")
          .withArgs(
            deployer.address,
            deployer.address,
            0x0000000000000000000000000000000000000000,
            [2],
            [1]
          );
      });
    });
  });

  describe("not owner mint", () => {
    it("reverts not owner", async () => {
      await (
        expect(child.connect(second).mint(deployer.address, 1, svg, "leftArm"))
          .to.be as any
      ).reverted;
    });
  });
});
