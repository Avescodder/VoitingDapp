import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("VotingSystem", (m) => {
  const votingLogic = m.contract("VotingLogic");
  
  return { votingLogic };
});