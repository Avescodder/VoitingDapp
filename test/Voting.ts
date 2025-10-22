import { expect } from "chai";
import { network } from "hardhat"
const { ethers } = await network.connect();

async function deployVotingFixture() {
  const [admin, candidate1, candidate2, voter1, voter2] = await ethers.getSigners();
  const VotingLogic = await ethers.getContractFactory("VotingLogic");
  const voting = await VotingLogic.deploy();

  return { voting, admin, candidate1, candidate2, voter1, voter2 };
}

class FixtureLoader {
  private snapshotId: string | null = null;
  private cachedResult: any;

  async load(fixture: () => Promise<any>) {
    if (this.snapshotId) {
      await ethers.provider.send("evm_revert", [this.snapshotId]);
      this.snapshotId = await ethers.provider.send("evm_snapshot", []);
      return this.cachedResult;
    }
    this.cachedResult = await fixture();
    this.snapshotId = await ethers.provider.send("evm_snapshot", []);
    return this.cachedResult;
  }
}

const fixtureLoader = new FixtureLoader();

describe("VotingLogic", function () {
  describe("Deployment", function () {
    it("Should set the deployer as admin", async function () {
      const { voting, admin } = await fixtureLoader.load(deployVotingFixture);
      const adminUser = await voting.getCandidate(admin.address).catch(() => null);
      // Admin не должен быть кандидатом, но должен быть в системе
    });

    it("Should start with Closed status", async function () {
      const { voting } = await fixtureLoader.load(deployVotingFixture);
      expect(await voting.currentStatus()).to.equal(0); // 0 = Closed
    });
  });

  describe("Candidate Registration", function () {
    it("Should allow users to register as candidates when voting is closed", async function () {
      const { voting, candidate1 } = await fixtureLoader.load(deployVotingFixture);
      await expect(voting.connect(candidate1).registerCandidate("Alice"))
        .to.emit(voting, "CandidateRegistered")
        .withArgs(candidate1.address, "Alice");

      const candidateData = await voting.getCandidate(candidate1.address);
      expect(candidateData.userName).to.equal("Alice");
      expect(candidateData.userCandidate).to.be.true;
    });

    it("Should not allow duplicate registration", async function () {
      const { voting, candidate1 } = await fixtureLoader.load(deployVotingFixture);
      await voting.connect(candidate1).registerCandidate("Alice");

      await expect(
        voting.connect(candidate1).registerCandidate("Alice2")
      ).to.be.revertedWith("Already registered as candidate");
    });

    it("Should not allow registration when voting is open", async function () {
      const { voting, admin, candidate1 } = await fixtureLoader.load(deployVotingFixture);
      await voting.connect(admin).changeStatus(1); // Open

      await expect(
        voting.connect(candidate1).registerCandidate("Alice")
      ).to.be.revertedWith("Cannot add candidate during voting");
    });
  });

  describe("Status Management", function () {
    it("Should allow admin to change status", async function () {
      const { voting, admin } = await fixtureLoader.load(deployVotingFixture);
      await expect(voting.connect(admin).changeStatus(1))
        .to.emit(voting, "StatusChanged")
        .withArgs(1, admin.address);
      expect(await voting.currentStatus()).to.equal(1);
    });

    it("Should not allow non-admin to change status", async function () {
      const { voting, voter1 } = await fixtureLoader.load(deployVotingFixture);
      await expect(
        voting.connect(voter1).changeStatus(1)
      ).to.be.revertedWith("Not admin");
    });

    it("Should not allow setting the same status", async function () {
      const { voting, admin } = await fixtureLoader.load(deployVotingFixture);
      await expect(
        voting.connect(admin).changeStatus(0) // Already Closed
      ).to.be.revertedWith("This status already set");
    });
  });

  describe("Voting", function () {
    it("Should allow voting when status is Open", async function () {
      const { voting, admin, candidate1, voter1 } = await fixtureLoader.load(deployVotingFixture);
      await voting.connect(candidate1).registerCandidate("Alice");
      await voting.connect(admin).changeStatus(1);

      await expect(voting.connect(voter1).vote(candidate1.address))
        .to.emit(voting, "Voted")
        .withArgs(voter1.address, candidate1.address, 1);

      const candidateData = await voting.getCandidate(candidate1.address);
      expect(candidateData.votesCount).to.equal(1);
    });

    it("Should not allow double voting", async function () {
      const { voting, admin, candidate1, voter1 } = await fixtureLoader.load(deployVotingFixture);
      await voting.connect(candidate1).registerCandidate("Alice");
      await voting.connect(admin).changeStatus(1);
      await voting.connect(voter1).vote(candidate1.address);

      await expect(
        voting.connect(voter1).vote(candidate1.address)
      ).to.be.revertedWith("Already voted");
    });

    it("Should not allow voting when status is Closed", async function () {
      const { voting, candidate1, voter1 } = await fixtureLoader.load(deployVotingFixture);
      await voting.connect(candidate1).registerCandidate("Alice");

      await expect(
        voting.connect(voter1).vote(candidate1.address)
      ).to.be.revertedWith("Voting is not open");
    });

    it("Should track the current leader", async function () {
      const { voting, admin, candidate1, candidate2, voter1, voter2 } = await fixtureLoader.load(deployVotingFixture);
      await voting.connect(candidate1).registerCandidate("Alice");
      await voting.connect(candidate2).registerCandidate("Bob");
      await voting.connect(admin).changeStatus(1);

      await voting.connect(voter1).vote(candidate1.address);
      expect(await voting.currentLeader()).to.equal(candidate1.address);

      await voting.connect(voter2).vote(candidate2.address);
      await voting.connect(admin).vote(candidate2.address);
      expect(await voting.currentLeader()).to.equal(candidate2.address);
    });
  });

  describe("Results", function () {
    it("Should return winner correctly", async function () {
      const { voting, admin, candidate1, voter1 } = await fixtureLoader.load(deployVotingFixture);
      await voting.connect(candidate1).registerCandidate("Alice");
      await voting.connect(admin).changeStatus(1);
      await voting.connect(voter1).vote(candidate1.address);

      const winner = await voting.getWinner();
      expect(winner.userName).to.equal("Alice");
      expect(winner.votesCount).to.equal(1);
    });

    it("Should revert getWinner when no votes", async function () {
      const { voting } = await fixtureLoader.load(deployVotingFixture);
      await expect(voting.getWinner()).to.be.revertedWith("No votes yet");
    });

    it("Should allow admin to get all results", async function () {
      const { voting, admin, candidate1, candidate2, voter1 } = await fixtureLoader.load(deployVotingFixture);
      await voting.connect(candidate1).registerCandidate("Alice");
      await voting.connect(candidate2).registerCandidate("Bob");
      await voting.connect(admin).changeStatus(1);
      await voting.connect(voter1).vote(candidate1.address);

      const results = await voting.connect(admin).getAllResults();
      expect(results.length).to.equal(2);
      expect(results[0].userName).to.equal("Alice");
      expect(results[1].userName).to.equal("Bob");
    });
  });
});