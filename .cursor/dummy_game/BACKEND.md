# Color Race - Backend Game Logic

**Game:** Color Race (Dummy Game for Workshop)  
**Purpose:** Simple multiplayer game to validate platform infrastructure  
**Complexity:** ⭐☆☆☆☆ (Very Simple - Perfect First Game)

---

## Game Overview

**Color Race** is a reaction-speed game where players compete to be the first to click the correct color button.

**Rules:**
- Host starts the game
- Server displays a color name (RED, BLUE, YELLOW, or GREEN)
- All players have 4 colored buttons
- First player to click the correct color gets +1 point
- Game plays 5 rounds
- Highest score wins

**Perfect for learning because:**
- ✅ Uses platform infrastructure (no changes needed)
- ✅ Simple game state (just scores + current color)
- ✅ Proves WebSocket sync works
- ✅ Tests "fastest player" detection
- ✅ Clear winner determination
- ✅ Can build in 30-60 minutes

---

## Integration with Platform

**What Platform Handles (DON'T write this code):**
- ✅ Room creation/joining
- ✅ Player authentication
- ✅ WebSocket connections
- ✅ Session management
- ✅ Reconnection logic
- ✅ Host management

**What Game Handles (YOU write this code):**
- 🎮 Game state initialization
- 🎮 Round management
- 🎮 Color randomization
- 🎮 Answer validation
- 🎮 Score tracking
- 🎮 Winner determination

**See `platform/BACKEND.md` for platform infrastructure details.**

---

## Game Types

**Add to `backend/src/types/game.types.ts`:**

```typescript
// Color options
export type Color = 'red' | 'blue' | 'yellow' | 'green';

// Game-specific state
export interface ColorRaceGameState {
  phase: GamePhase;
  currentColor: Color | null;     // The color players need to click
  round: number;                   // Current round (1-5)
  scores: Record<string, number>;  // playerId -> score
  roundWinner: string | null;      // playerId of round winner
}

// Game phases
export type GamePhase = 
  | 'waiting'        // Lobby (handled by platform)
  | 'countdown'      // 3-2-1 before game (handled by platform)
  | 'showing_color'  // Displaying color to click
  | 'round_result'   // Showing who won the round
  | 'finished';      // Game over

// Player answer submission
export interface PlayerAnswer {
  playerId: string;
  color: Color;
  timestamp: number;  // Server timestamp for tie-breaking
}
```

---

## Game Logic

**Create `backend/src/utils/colorRaceLogic.ts`:**

### 1. Initialize Game State

```typescript
export function initializeColorRaceGame(players: Player[]): ColorRaceGameState {
  const scores: Record<string, number> = {};
  
  // Initialize scores for all players
  players.forEach(player => {
    scores[player.id] = 0;
  });
  
  return {
    phase: 'showing_color',
    currentColor: getRandomColor(),
    round: 1,
    scores,
    roundWinner: null
  };
}
```

### 2. Random Color Generation

```typescript
const COLORS: Color[] = ['red', 'blue', 'yellow', 'green'];

export function getRandomColor(): Color {
  const randomIndex = Math.floor(Math.random() * COLORS.length);
  return COLORS[randomIndex];
}
```

### 3. Validate Answer

```typescript
export function validateAnswer(
  gameState: ColorRaceGameState,
  answer: PlayerAnswer
): boolean {
  // Check if it's the correct color
  return answer.color === gameState.currentColor;
}
```

### 4. Process Round

```typescript
export function processRound(
  gameState: ColorRaceGameState,
  answers: PlayerAnswer[]
): ColorRaceGameState {
  // Find correct answers
  const correctAnswers = answers.filter(answer => 
    answer.color === gameState.currentColor
  );
  
  if (correctAnswers.length === 0) {
    // No one answered correctly - no winner this round
    return nextRound(gameState, null);
  }
  
  // Find fastest correct answer (lowest timestamp)
  const fastest = correctAnswers.reduce((prev, current) => 
    current.timestamp < prev.timestamp ? current : prev
  );
  
  // Award point to fastest player
  gameState.scores[fastest.playerId]++;
  
  return nextRound(gameState, fastest.playerId);
}
```

### 5. Next Round

```typescript
function nextRound(
  gameState: ColorRaceGameState,
  winnerId: string | null
): ColorRaceGameState {
  const isLastRound = gameState.round >= 5;
  
  if (isLastRound) {
    return {
      ...gameState,
      phase: 'finished',
      roundWinner: winnerId
    };
  }
  
  return {
    ...gameState,
    phase: 'showing_color',
    currentColor: getRandomColor(),
    round: gameState.round + 1,
    roundWinner: winnerId
  };
}
```

### 6. Determine Winner

```typescript
export function determineWinner(
  gameState: ColorRaceGameState
): { winnerId: string; winnerScore: number } | null {
  const scores = gameState.scores;
  
  if (Object.keys(scores).length === 0) {
    return null;
  }
  
  // Find highest score
  let maxScore = -1;
  let winnerId = '';
  
  Object.entries(scores).forEach(([playerId, score]) => {
    if (score > maxScore) {
      maxScore = score;
      winnerId = playerId;
    }
  });
  
  return { winnerId, winnerScore: maxScore };
}
```

---

## WebSocket Events

**Add to `backend/src/websocket/gameHandler.ts`:**

### Server Events (Send to Clients)

```typescript
// New round started - show color
socket.emit('color_race:new_round', {
  round: number;
  color: Color;
  totalRounds: 5;
});

// Round result - who won
socket.emit('color_race:round_result', {
  winnerId: string | null;
  winnerName: string | null;
  scores: Record<string, number>;
});

// Game finished - final results
socket.emit('color_race:game_finished', {
  winnerId: string;
  winnerName: string;
  finalScores: Record<string, number>;
});
```

### Client Events (Receive from Clients)

```typescript
// Player submits their answer
socket.on('color_race:submit_answer', (data: {
  gameCode: string;
  playerId: string;
  color: Color;
}) => {
  // Validate answer
  // Update scores
  // Broadcast results
});
```

---

## Game Flow Implementation

**Add to `backend/src/websocket/gameHandler.ts`:**

```typescript
import { initializeColorRaceGame, validateAnswer, processRound, determineWinner } from '../utils/colorRaceLogic';

// Track answers for current round
const roundAnswers = new Map<string, PlayerAnswer[]>(); // gameCode -> answers

// Start game (called when host presses "Start Game")
socket.on('start_game', (data: { gameCode: string; playerId: string }) => {
  const room = gameService.getRoom(data.gameCode);
  if (!room) return;
  
  // Verify host
  const player = room.players.find(p => p.id === data.playerId);
  if (!player?.isHost) return;
  
  // Initialize game state
  room.gameState = initializeColorRaceGame(room.players);
  room.status = 'active';
  
  // Clear any previous answers
  roundAnswers.set(data.gameCode, []);
  
  // Start first round
  io.to(data.gameCode).emit('color_race:new_round', {
    round: 1,
    color: room.gameState.currentColor,
    totalRounds: 5
  });
  
  console.log(`🎮 Color Race started in room ${data.gameCode}`);
});

// Player submits answer
socket.on('color_race:submit_answer', (data: {
  gameCode: string;
  playerId: string;
  color: Color;
}) => {
  const room = gameService.getRoom(data.gameCode);
  if (!room || room.status !== 'active') return;
  
  const gameState = room.gameState as ColorRaceGameState;
  
  // Check if player already answered this round
  const answers = roundAnswers.get(data.gameCode) || [];
  if (answers.some(a => a.playerId === data.playerId)) {
    return; // Already answered
  }
  
  // Record answer with server timestamp
  const answer: PlayerAnswer = {
    playerId: data.playerId,
    color: data.color,
    timestamp: Date.now()
  };
  
  answers.push(answer);
  roundAnswers.set(data.gameCode, answers);
  
  // Check if all players have answered
  const activePlayers = room.players.filter(p => p.connected);
  if (answers.length >= activePlayers.length) {
    // Process round
    const updatedState = processRound(gameState, answers);
    room.gameState = updatedState;
    
    // Clear answers for next round
    roundAnswers.set(data.gameCode, []);
    
    // Get winner info
    const roundWinner = room.players.find(p => p.id === updatedState.roundWinner);
    
    // Broadcast round result
    io.to(data.gameCode).emit('color_race:round_result', {
      winnerId: updatedState.roundWinner,
      winnerName: roundWinner?.displayName || null,
      scores: updatedState.scores
    });
    
    // Check if game finished
    if (updatedState.phase === 'finished') {
      const winner = determineWinner(updatedState);
      const winnerPlayer = room.players.find(p => p.id === winner?.winnerId);
      
      io.to(data.gameCode).emit('color_race:game_finished', {
        winnerId: winner!.winnerId,
        winnerName: winnerPlayer!.displayName,
        finalScores: updatedState.scores
      });
      
      room.status = 'finished';
      console.log(`🏆 Color Race finished in room ${data.gameCode} - Winner: ${winnerPlayer?.displayName}`);
    } else {
      // Start next round after 2 seconds
      setTimeout(() => {
        io.to(data.gameCode).emit('color_race:new_round', {
          round: updatedState.round,
          color: updatedState.currentColor,
          totalRounds: 5
        });
      }, 2000);
    }
  }
});
```

---

## Testing Checklist

**Before workshop, verify:**

- [ ] 1 player can create game and play solo
- [ ] 2 players can join and compete
- [ ] Correct answer awards +1 point
- [ ] Wrong answer awards 0 points
- [ ] Fastest correct answer wins (test with simultaneous clicks)
- [ ] Game plays exactly 5 rounds
- [ ] Final scores display correctly
- [ ] Winner is determined by highest score
- [ ] Tie is handled (first tied player wins)
- [ ] Player disconnect doesn't break game
- [ ] Page refresh maintains connection

---

## Deployment Notes

**Environment Variables:**
Same as platform (no additional variables needed)

**Build Command:**
```bash
npm install && npm run build
```

**Start Command:**
```bash
npm start
```

---

## Workshop Teaching Points

**When building Color Race, emphasize:**

1. **Platform vs Game Separation:**
   - "Notice how we didn't touch room/auth code!"
   - "Platform handles WHO is playing, game handles WHAT they're playing"

2. **Game State Pattern:**
   - "All game state lives in `room.gameState`"
   - "Server is source of truth - clients just display"

3. **WebSocket Events:**
   - "We only added 3 game events: new_round, round_result, game_finished"
   - "Platform events (player_joined, etc) still work!"

4. **Fastest Player Detection:**
   - "Server timestamps prevent cheating"
   - "Network latency doesn't matter - server decides"

5. **Quick Win:**
   - "You just built a real multiplayer game in 1 hour!"
   - "Now let's build something more complex (Simon Says)..."

---

## Next Steps After Color Race

**Once Color Race works:**
1. ✅ Platform is validated
2. ✅ Participants understand pattern
3. ✅ Ready for Simon Says complexity
4. 🎯 Build Simon using same pattern

**Simon will add:**
- Sequences (multiple colors in order)
- Timeouts (time limits per round)
- Elimination (spectator mode)
- Progressive difficulty

**But the platform stays identical!**

---

## Summary

Color Race provides:
- ✅ Simplest possible multiplayer game
- ✅ Validates platform infrastructure
- ✅ Teaches game/platform separation
- ✅ Builds participant confidence
- ✅ <200 lines of game logic
- ✅ Can build in 30-60 minutes

**Total Code to Write:**
- `types/game.types.ts`: ~30 lines
- `utils/colorRaceLogic.ts`: ~80 lines
- `websocket/gameHandler.ts`: ~60 lines (additions)
- **Total: ~170 lines**

**Perfect workshop starter game!** 🎨🏁