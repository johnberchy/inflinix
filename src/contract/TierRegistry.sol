// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Records the credit tier Inflinix recalled for an agent. Built for the Accred Hackathon.
contract TierRegistry {
    struct Record {
        address attester;
        string agentId;
        uint16 score;
        string tier;
        uint32 events;
        uint16 sessions;
        uint64 assessedAt;
    }

    Record[] public records;

    event TierAttested(uint256 indexed id, address indexed attester, string agentId, uint16 score, string tier);

    function attest(
        string calldata agentId,
        uint16 score,
        string calldata tier,
        uint32 events,
        uint16 sessions
    ) external returns (uint256 id) {
        id = records.length;
        records.push(Record(msg.sender, agentId, score, tier, events, sessions, uint64(block.timestamp)));
        emit TierAttested(id, msg.sender, agentId, score, tier);
    }

    function count() external view returns (uint256) {
        return records.length;
    }
}
