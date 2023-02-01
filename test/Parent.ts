import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import {
  imageURI,
  parentURI,
  secondSvg,
  secondURI,
  svg,
} from "../lib/constants";

describe("Parent FGO Test Suite", () => {
  let parent: any, child: any, deployer: any, second: any;
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

  describe("token usage", () => {
    let result_single: any;

    beforeEach("mint parent token", async () => {
      const transaction_single = await parent
        .connect(deployer)
        .createTemplate(svg, [1, 2], "long sleeve jacket");
      result_single = await transaction_single.wait();
    });

    describe("mint token", () => {
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
        expect(_childTokenIds).to.eql([
          BigNumber.from("1"),
          BigNumber.from("2"),
        ]);
      });

      it("updates uri and template", async () => {
        await parent.updateSvg(1, secondSvg);
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
        expect(_imageURI).to.equal(secondURI);
        expect(_childTokenIds).to.eql([
          BigNumber.from("1"),
          BigNumber.from("2"),
        ]);
      });
    });

    describe("approval", () => {
      beforeEach("approve for child transfer", async () => {
        await child.connect(deployer).setApprovalForAll(parent.address, true);
      });

      describe("transfer tokens from", () => {
        let result: any;
        beforeEach("transfer the tokens", async () => {
          const transaction_single = await parent
            .connect(deployer)
            .transferFrom(deployer.address, second.address, 1);
          result = transaction_single.wait();
        });

        it("transfers one token", async () => {
          (expect(result).to as any)
            .emit("Transfer")
            .withArgs(deployer.address, second.address, 1);

          (expect(result).to as any)
            .emit("TransferBatch")
            .withArgs(
              deployer.address,
              deployer.address,
              second.address,
              [1, 2],
              [1]
            );
        });

        it("has a new owner", async () => {
          expect(await parent.tokenIdToOwner(1)).to.equal(second.address);
        });

        it("child tokens new owner", async () => {
          expect(await child.tokenIdToOwner(1)).to.equal(second.address);
          expect(await child.tokenIdToOwner(2)).to.equal(second.address);
        });
      });

      describe("only owner can transfer", () => {
        it("rejects a non owner", async () => {
          await (
            expect(
              parent
                .connect(second)
                .transferFrom(deployer.address, second.address, 1)
            ).to.be as any
          ).revertedWith("ERC721: caller is not token owner or approved");
        });
      });

      describe("burn tokens", () => {
        let result: any;
        beforeEach("burn a token", async () => {
          await child.isApprovedForAll(deployer.address, parent.address);
          const transaction = await parent.burnTemplate(1, [1, 2], [1, 1]);
          result = transaction.wait();
        });

        it("emits burn transfer", async () => {
          (expect(result).to as any)
            .emit("Transfer")
            .withArgs(deployer.address, "0x" + "0".repeat(40), 1);

          (expect(result).to as any)
            .emit("TransferBatch")
            .withArgs(
              deployer.address,
              deployer.address,
              0x0000000000000000000000000000000000000000,
              [2],
              [1]
            );
        });

        it("has a new 0 address owner", async () => {
          expect(await parent.tokenIdToOwner(1)).to.equal(
            "0x" + "0".repeat(40)
          );
        });

        it("child tokens new 0 address owner", async () => {
          expect(await child.tokenIdToOwner(1)).to.equal("0x" + "0".repeat(40));
          expect(await child.tokenIdToOwner(2)).to.equal("0x" + "0".repeat(40));
        });
      });

      describe("only owner can burn", () => {
        it("reverts non-owner", async () => {
          await (
            expect(parent.connect(second).burnTemplate(1, [1, 2], [1, 1]))
              .to.be as any
          ).revertedWith("Ownable: caller is not the owner");
        });
      });
    });
  });
});
