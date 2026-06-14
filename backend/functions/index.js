const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.judgeDraft = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in before judging a draft.");
  }

  const room = request.data;
  const players = Array.isArray(room.players) ? room.players : [];
  const picks = Array.isArray(room.picks) ? room.picks : [];

  if (!players.length) {
    throw new HttpsError("invalid-argument", "Room has no players.");
  }

  const scores = players
    .map((player) => {
      const roster = picks.filter((pick) => pick.pickedByPlayerID === player.id);
      const stealBonus = roster.filter((pick) => pick.isSteal).length * 4;
      const score = Math.min(99, 74 + roster.length * 5 + stealBonus + Math.abs(hash(player.displayName || player.id) % 8));
      return {
        id: player.id,
        playerID: player.id,
        playerName: player.displayName || "Player",
        score,
        verdict: score > 90 ? "Room-commanding board with elite timing." : "Strong picks with a few debate starters."
      };
    })
    .sort((a, b) => b.score - a.score);

  const winner = scores[0];
  return {
    id: `result-${Date.now()}`,
    winnerPlayerID: winner.playerID,
    headline: `${winner.playerName} wins the draft.`,
    summary: "The judge rewarded cohesion, drama, and the courage to spend a life at the right moment.",
    teamScores: scores,
    funStats: [
      {
        id: "sleeper",
        title: "Biggest Sleeper",
        value: (picks[picks.length - 1] && picks[picks.length - 1].name) || "No sleeper emerged",
        symbol: "moon.fill"
      },
      {
        id: "questionable",
        title: "Most Questionable Pick",
        value: (picks[1] && picks[1].name) || "No chaos detected",
        symbol: "questionmark.circle.fill"
      },
      {
        id: "steal",
        title: "Top Steal",
        value: (picks.find((pick) => pick.isSteal) || {}).name || "No thefts, suspiciously polite",
        symbol: "bolt.fill"
      }
    ],
    createdAt: new Date().toISOString()
  };
});

function hash(value) {
  return String(value).split("").reduce((result, char) => ((result << 5) - result + char.charCodeAt(0)) | 0, 0);
}

