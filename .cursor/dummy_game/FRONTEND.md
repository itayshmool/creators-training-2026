# Color Race - Frontend Game UI

**Game:** Color Race (Dummy Game for Workshop)  
**Purpose:** Simple multiplayer UI to validate platform  
**Complexity:** ⭐☆☆☆☆ (Very Simple - Perfect First Game)

---

## Game Overview

**Color Race UI** displays 4 colored buttons and shows which color to click. First player to click correctly wins the round.

**UI Requirements:**
- ✅ 4 large colored buttons (Red, Blue, Yellow, Green)
- ✅ Display current color name ("Click RED!")
- ✅ Show round number (1/5, 2/5, etc.)
- ✅ Display real-time scores
- ✅ Show round winner
- ✅ Display final results

---

## Integration with Platform

**What Platform Provides (DON'T change this):**
- ✅ EntryPage (name + avatar selection)
- ✅ WaitingRoomPage (lobby with player list)
- ✅ GameEndPage (results screen)
- ✅ Socket connection
- ✅ Session management
- ✅ Routing

**What Game Provides (YOU build this):**
- 🎮 GamePage component
- 🎮 ColorButton component
- 🎮 Game state management (gameStore)
- 🎮 Game event listeners

**See `platform/FRONTEND.md` for platform infrastructure details.**

---

## Game Store

**Create `frontend/src/store/colorRaceStore.ts`:**

```typescript
import { create } from 'zustand';

export type Color = 'red' | 'blue' | 'yellow' | 'green';

interface ColorRaceState {
  // Game state
  phase: 'waiting' | 'playing' | 'round_result' | 'finished';
  currentColor: Color | null;
  round: number;
  totalRounds: number;
  scores: Record<string, number>;
  
  // Round result
  roundWinner: {
    playerId: string;
    displayName: string;
  } | null;
  
  // Final result
  gameWinner: {
    playerId: string;
    displayName: string;
    score: number;
  } | null;
  
  // Player's answer status
  hasAnswered: boolean;
  
  // Actions
  setCurrentColor: (color: Color, round: number) => void;
  setRoundResult: (winnerId: string | null, winnerName: string | null, scores: Record<string, number>) => void;
  setGameFinished: (winnerId: string, winnerName: string, scores: Record<string, number>) => void;
  markAnswered: () => void;
  resetGame: () => void;
}

export const useColorRaceStore = create<ColorRaceState>((set) => ({
  // Initial state
  phase: 'waiting',
  currentColor: null,
  round: 1,
  totalRounds: 5,
  scores: {},
  roundWinner: null,
  gameWinner: null,
  hasAnswered: false,
  
  // Set new round
  setCurrentColor: (color, round) => set({
    phase: 'playing',
    currentColor: color,
    round,
    hasAnswered: false,
    roundWinner: null
  }),
  
  // Set round result
  setRoundResult: (winnerId, winnerName, scores) => set({
    phase: 'round_result',
    roundWinner: winnerId && winnerName ? { playerId: winnerId, displayName: winnerName } : null,
    scores
  }),
  
  // Set game finished
  setGameFinished: (winnerId, winnerName, scores) => set({
    phase: 'finished',
    gameWinner: { playerId: winnerId, displayName: winnerName, score: scores[winnerId] },
    scores
  }),
  
  // Mark that player answered
  markAnswered: () => set({ hasAnswered: true }),
  
  // Reset for new game
  resetGame: () => set({
    phase: 'waiting',
    currentColor: null,
    round: 1,
    scores: {},
    roundWinner: null,
    gameWinner: null,
    hasAnswered: false
  })
}));
```

---

## Game Page Component

**Create `frontend/src/pages/GamePage.tsx`:**

```typescript
import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { useColorRaceStore } from '../store/colorRaceStore';
import { socketService } from '../services/socketService';
import { ColorButton } from '../components/game/ColorButton';
import { ScoreBar } from '../components/game/ScoreBar';

export const GamePage: React.FC = () => {
  const navigate = useNavigate();
  const { session } = useAuthStore();
  const { 
    phase, 
    currentColor, 
    round, 
    totalRounds, 
    scores,
    roundWinner,
    hasAnswered,
    setCurrentColor, 
    setRoundResult,
    setGameFinished,
    markAnswered 
  } = useColorRaceStore();

  useEffect(() => {
    if (!session) {
      navigate('/');
      return;
    }

    const socket = socketService.getSocket();
    if (!socket) return;

    // Listen for new round
    socket.on('color_race:new_round', (data: {
      round: number;
      color: string;
      totalRounds: number;
    }) => {
      setCurrentColor(data.color as Color, data.round);
    });

    // Listen for round result
    socket.on('color_race:round_result', (data: {
      winnerId: string | null;
      winnerName: string | null;
      scores: Record<string, number>;
    }) => {
      setRoundResult(data.winnerId, data.winnerName, data.scores);
    });

    // Listen for game finished
    socket.on('color_race:game_finished', (data: {
      winnerId: string;
      winnerName: string;
      finalScores: Record<string, number>;
    }) => {
      setGameFinished(data.winnerId, data.winnerName, data.finalScores);
      
      // Navigate to end screen after 3 seconds
      setTimeout(() => {
        navigate('/end');
      }, 3000);
    });

    return () => {
      socket.off('color_race:new_round');
      socket.off('color_race:round_result');
      socket.off('color_race:game_finished');
    };
  }, [session, navigate, setCurrentColor, setRoundResult, setGameFinished]);

  const handleColorClick = (color: Color) => {
    if (hasAnswered || phase !== 'playing') return;
    
    // Send answer to server
    socketService.emit('color_race:submit_answer', {
      gameCode: session!.gameCode,
      playerId: session!.playerId,
      color
    });
    
    markAnswered();
  };

  if (!session) return null;

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-600 to-blue-600 flex flex-col">
      {/* Score Bar */}
      <ScoreBar scores={scores} currentPlayerId={session.playerId} />
      
      {/* Main Game Area */}
      <div className="flex-1 flex flex-col items-center justify-center p-8">
        {/* Round Number */}
        <div className="text-white text-2xl font-bold mb-4">
          Round {round} / {totalRounds}
        </div>
        
        {/* Color Instruction */}
        {phase === 'playing' && currentColor && (
          <div className="text-white text-6xl font-bold mb-8 animate-pulse">
            Click {currentColor.toUpperCase()}!
          </div>
        )}
        
        {/* Round Result */}
        {phase === 'round_result' && (
          <div className="text-white text-4xl font-bold mb-8">
            {roundWinner 
              ? `${roundWinner.displayName} wins! 🎉` 
              : 'No winner this round'}
          </div>
        )}
        
        {/* Game Finished */}
        {phase === 'finished' && (
          <div className="text-white text-5xl font-bold mb-8 animate-bounce">
            🏆 Game Over! 🏆
          </div>
        )}
        
        {/* Color Buttons Grid */}
        <div className="grid grid-cols-2 gap-6 max-w-2xl w-full">
          <ColorButton 
            color="red" 
            onClick={() => handleColorClick('red')}
            disabled={hasAnswered || phase !== 'playing'}
          />
          <ColorButton 
            color="blue" 
            onClick={() => handleColorClick('blue')}
            disabled={hasAnswered || phase !== 'playing'}
          />
          <ColorButton 
            color="yellow" 
            onClick={() => handleColorClick('yellow')}
            disabled={hasAnswered || phase !== 'playing'}
          />
          <ColorButton 
            color="green" 
            onClick={() => handleColorClick('green')}
            disabled={hasAnswered || phase !== 'playing'}
          />
        </div>
        
        {/* Answer Status */}
        {hasAnswered && phase === 'playing' && (
          <div className="text-white text-xl mt-6">
            Waiting for other players...
          </div>
        )}
      </div>
    </div>
  );
};
```

---

## Color Button Component

**Create `frontend/src/components/game/ColorButton.tsx`:**

```typescript
import React from 'react';

type Color = 'red' | 'blue' | 'yellow' | 'green';

interface ColorButtonProps {
  color: Color;
  onClick: () => void;
  disabled?: boolean;
}

const colorStyles: Record<Color, string> = {
  red: 'bg-red-500 hover:bg-red-600 active:bg-red-700',
  blue: 'bg-blue-500 hover:bg-blue-600 active:bg-blue-700',
  yellow: 'bg-yellow-400 hover:bg-yellow-500 active:bg-yellow-600',
  green: 'bg-green-500 hover:bg-green-600 active:bg-green-700'
};

export const ColorButton: React.FC<ColorButtonProps> = ({ 
  color, 
  onClick, 
  disabled = false 
}) => {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`
        ${colorStyles[color]}
        text-white text-4xl font-bold
        rounded-2xl
        h-40 w-full
        transition-all duration-150
        active:scale-95
        disabled:opacity-50 disabled:cursor-not-allowed
        shadow-2xl
        ${!disabled && 'hover:scale-105'}
      `}
    >
      {color.toUpperCase()}
    </button>
  );
};
```

---

## Score Bar Component

**Adapt `frontend/src/components/game/ScoreBar.tsx`:**

```typescript
import React from 'react';
import { useAuthStore } from '../../store/authStore';

interface ScoreBarProps {
  scores: Record<string, number>;
  currentPlayerId: string;
}

export const ScoreBar: React.FC<ScoreBarProps> = ({ scores, currentPlayerId }) => {
  const { session } = useAuthStore();
  
  // Get all players from waiting room or session
  const players = Object.keys(scores).map(playerId => ({
    id: playerId,
    score: scores[playerId] || 0,
    isCurrentPlayer: playerId === currentPlayerId
  }));

  return (
    <div className="bg-white bg-opacity-20 backdrop-blur-sm p-4">
      <div className="flex gap-4 justify-center flex-wrap">
        {players.map(player => (
          <div
            key={player.id}
            className={`
              px-6 py-3 rounded-lg
              ${player.isCurrentPlayer 
                ? 'bg-yellow-400 text-gray-900' 
                : 'bg-white bg-opacity-30 text-white'}
              font-bold text-lg
            `}
          >
            {player.isCurrentPlayer ? 'YOU' : `Player ${player.id.slice(0, 4)}`}: {player.score}
          </div>
        ))}
      </div>
    </div>
  );
};
```

---

## Game End Page

**Adapt `frontend/src/pages/GameEndPage.tsx`:**

```typescript
import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { useColorRaceStore } from '../store/colorRaceStore';
import { Button } from '../components/ui/Button';

export const GameEndPage: React.FC = () => {
  const navigate = useNavigate();
  const { session } = useAuthStore();
  const { gameWinner, scores, resetGame } = useColorRaceStore();

  const handlePlayAgain = () => {
    resetGame();
    navigate('/waiting');
  };

  const handleBackToMenu = () => {
    resetGame();
    navigate('/');
  };

  if (!session || !gameWinner) {
    return null;
  }

  // Sort players by score
  const sortedPlayers = Object.entries(scores)
    .map(([playerId, score]) => ({ playerId, score }))
    .sort((a, b) => b.score - a.score);

  const isWinner = gameWinner.playerId === session.playerId;

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-600 to-blue-600 flex items-center justify-center p-4">
      <div className="bg-white rounded-3xl shadow-2xl p-8 max-w-md w-full">
        {/* Winner Announcement */}
        <div className="text-center mb-8">
          <div className="text-6xl mb-4">
            {isWinner ? '🏆' : '🎮'}
          </div>
          <h1 className="text-4xl font-bold mb-2">
            {isWinner ? 'You Won!' : 'Game Over'}
          </h1>
          <p className="text-xl text-gray-600">
            {gameWinner.displayName} is the champion!
          </p>
        </div>

        {/* Final Scores */}
        <div className="mb-8">
          <h2 className="text-2xl font-bold mb-4 text-center">Final Scores</h2>
          <div className="space-y-2">
            {sortedPlayers.map((player, index) => (
              <div
                key={player.playerId}
                className={`
                  flex items-center justify-between p-4 rounded-lg
                  ${index === 0 
                    ? 'bg-yellow-100 border-2 border-yellow-400' 
                    : 'bg-gray-100'}
                `}
              >
                <span className="font-semibold">
                  #{index + 1} {player.playerId === session.playerId ? 'YOU' : `Player ${player.playerId.slice(0, 4)}`}
                </span>
                <span className="text-2xl font-bold">
                  {player.score}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Actions */}
        <div className="space-y-3">
          <Button
            onClick={handlePlayAgain}
            className="w-full py-4 text-lg"
          >
            Play Again
          </Button>
          <Button
            onClick={handleBackToMenu}
            variant="outline"
            className="w-full py-4 text-lg"
          >
            Back to Menu
          </Button>
        </div>
      </div>
    </div>
  );
};
```

---

## Mobile Optimization

**Color buttons sizing:**
```typescript
// Minimum touch target: 44x44px (iOS guideline)
// Color buttons: 160px height (h-40) = perfect for mobile taps
// Grid gap: 24px (gap-6) = prevents accidental clicks
```

**Responsive layout:**
```typescript
// 2x2 grid on all screen sizes (simple and consistent)
// Full width on mobile, max-width on desktop
// Large text for visibility
```

---

## Testing Checklist

**Before workshop, verify:**

- [ ] 4 colored buttons display correctly
- [ ] Color instruction shows ("Click RED!")
- [ ] Round number displays (1/5, 2/5, etc.)
- [ ] Scores update in real-time
- [ ] Buttons disable after clicking
- [ ] "Waiting for other players..." shows after click
- [ ] Round winner announcement displays
- [ ] Game end screen shows correct winner
- [ ] Final scores sorted correctly
- [ ] Play Again button works
- [ ] Mobile layout looks good (test on phone)

---

## Workshop Teaching Points

**When building Color Race UI, emphasize:**

1. **State Management:**
   - "All game state managed by Zustand store"
   - "Server sends events, we update local state"
   - "UI is just a view of the state"

2. **WebSocket Events:**
   - "3 events: new_round, round_result, game_finished"
   - "useEffect with cleanup prevents memory leaks"
   - "Always remove event listeners on unmount"

3. **Disabled State:**
   - "Buttons disable after click - prevents duplicate submissions"
   - "Good UX shows 'waiting for others' feedback"

4. **Mobile-First:**
   - "Big buttons (160px height) for easy tapping"
   - "Responsive grid works on any screen size"
   - "Touch-friendly spacing prevents misclicks"

5. **Quick Win:**
   - "You built a complete multiplayer game UI!"
   - "Same pattern works for any game"
   - "Now let's add complexity with Simon Says..."

---

## Styling Tips

**Color button animations:**
```css
/* Smooth press animation */
active:scale-95

/* Hover effect (desktop only) */
hover:scale-105

/* Disabled state */
disabled:opacity-50 disabled:cursor-not-allowed
```

**Background gradients:**
```css
/* Main game background */
bg-gradient-to-br from-purple-600 to-blue-600

/* Score bar blur effect */
bg-white bg-opacity-20 backdrop-blur-sm
```

---

## Next Steps After Color Race

**Once Color Race UI works:**
1. ✅ Platform UI validated
2. ✅ Participants understand game page pattern
3. ✅ Ready for Simon Says UI complexity
4. 🎯 Build Simon using same pattern

**Simon will add:**
- Sequence display animation
- Timeout timer bar
- Elimination state (spectator mode)
- More complex button states

**But the routing/auth/lobby stays identical!**

---

## Summary

Color Race UI provides:
- ✅ Simplest possible game interface
- ✅ Validates platform routing/sockets
- ✅ Teaches state management
- ✅ Mobile-optimized
- ✅ <300 lines of code
- ✅ Can build in 30 minutes

**Total Code to Write:**
- `store/colorRaceStore.ts`: ~70 lines
- `pages/GamePage.tsx`: ~120 lines
- `components/game/ColorButton.tsx`: ~40 lines
- `pages/GameEndPage.tsx`: ~80 lines
- **Total: ~310 lines**

**Perfect workshop starter UI!** 🎨🏁