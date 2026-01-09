# Platform Frontend - Multiplayer Infrastructure

**Version:** 1.0  
**Purpose:** Reusable frontend infrastructure for 1-4 player real-time multiplayer games  
**Status:** ✅ 100% REUSABLE - Do not modify for game-specific logic

---

## Core Philosophy

This frontend provides **complete multiplayer UI infrastructure** that is game-agnostic. All authentication flow, waiting room, session management, and WebSocket communication are handled here. Game-specific UI belongs in `game/FRONTEND.md`.

**Key Principle:** Platform handles WHO is playing and HOW they connect. Game handles WHAT they see during gameplay.

---

## Tech Stack

- **Framework:** React 18 + TypeScript
- **Build Tool:** Vite
- **State Management:** Zustand
- **Styling:** Tailwind CSS
- **Real-time:** Socket.io-client
- **Routing:** React Router
- **Deployment:** Render.com (static site)

---

## File Structure

```
frontend/src/
├── pages/
│   ├── EntryPage.tsx            # ✅ Name + avatar picker
│   ├── WaitingRoomPage.tsx      # ✅ Lobby with invite link
│   ├── GamePage.tsx             # 🔄 Main gameplay (see game/FRONTEND.md)
│   └── GameEndPage.tsx          # ✅ Victory/results screen
├── components/
│   ├── auth/
│   │   ├── AvatarPicker.tsx     # ✅ Avatar selection grid
│   │   └── NameInput.tsx        # ✅ Display name input
│   ├── game/
│   │   ├── GameBoard.tsx        # 🔄 GAME-SPECIFIC (see game/FRONTEND.md)
│   │   ├── ScoreBar.tsx         # ✅ Player scores display
│   │   └── CountdownOverlay.tsx # ✅ 3-2-1 countdown
│   └── ui/
│       ├── ThemeToggle.tsx      # ✅ Dark mode toggle
│       └── Button.tsx           # ✅ Reusable button
├── store/
│   ├── authStore.ts             # ✅ Player session state
│   ├── gameStore.ts             # 🔄 GAME-SPECIFIC (see game/FRONTEND.md)
│   └── themeStore.ts            # ✅ Theme preference
├── services/
│   ├── authService.ts           # ✅ HTTP API calls
│   └── socketService.ts         # ✅ WebSocket client
└── utils/
    ├── shareUtils.ts            # ✅ WhatsApp/SMS sharing
    └── constants.ts             # ✅ App-wide constants
```

**Legend:**
- ✅ = 100% reusable, never modify
- 🔄 = Game-specific, replace per game

---

## Routing Structure

**React Router Setup:**

```typescript
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<EntryPage />} />           {/* ✅ Platform */}
        <Route path="/waiting" element={<WaitingRoomPage />} /> {/* ✅ Platform */}
        <Route path="/game" element={<GamePage />} />        {/* 🔄 Game-specific */}
        <Route path="/end" element={<GameEndPage />} />      {/* ✅ Platform */}
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
  );
}
```

**Route Protection:**
```typescript
// Redirect to entry if no session
useEffect(() => {
  const session = authStore.getState().session;
  if (!session) {
    navigate('/');
  }
}, []);
```

---

## Core Services

### 1. Auth Service (`services/authService.ts`)

**Purpose:** Handle HTTP API calls for authentication.

**API Base URL:**
```typescript
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';
```

#### Methods:

##### `createSession(displayName: string, avatarId: string)`
**Purpose:** Create new game as host

```typescript
const response = await fetch(`${API_BASE_URL}/api/auth/create-session`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  credentials: 'include',  // CRITICAL: Sends/receives cookies
  body: JSON.stringify({ displayName, avatarId })
});

const data = await response.json();
// Returns: { playerId, gameCode, session: {...} }
```

##### `joinGame(displayName: string, avatarId: string, gameCode: string)`
**Purpose:** Join existing game

```typescript
const response = await fetch(`${API_BASE_URL}/api/auth/join-game`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  credentials: 'include',  // CRITICAL: Sends/receives cookies
  body: JSON.stringify({ displayName, avatarId, gameCode })
});

const data = await response.json();
// Returns: { playerId, session: {...} }
```

##### `verifySession()`
**Purpose:** Check if session is valid (on page load)

```typescript
const response = await fetch(`${API_BASE_URL}/api/auth/verify-session`, {
  method: 'GET',
  credentials: 'include'  // CRITICAL: Sends cookies
});

const data = await response.json();
// Returns: { valid: boolean, session?: {...} }
```

**Critical Rule:** Always use `credentials: 'include'` to send/receive JWT cookies.

---

### 2. Socket Service (`services/socketService.ts`)

**Purpose:** Manage WebSocket connection to backend.

**Singleton Pattern:**
```typescript
let socket: Socket | null = null;

export const socketService = {
  connect(): Socket {
    if (!socket) {
      socket = io(SOCKET_URL, {
        withCredentials: true,     // CRITICAL: Send cookies with WS
        transports: ['websocket', 'polling']
      });
    }
    return socket;
  },
  
  getSocket(): Socket | null {
    return socket;
  },
  
  disconnect(): void {
    if (socket) {
      socket.disconnect();
      socket = null;
    }
  }
};
```

**CRITICAL:** `withCredentials: true` is required for JWT auto-reconnection.

#### Platform Events (Reusable)

**Emitted by Client:**
```typescript
// Join room via WebSocket
socket.emit('join_room_socket', { gameCode, playerId });

// Leave room
socket.emit('leave_room', { gameCode, playerId });
```

**Received by Client:**
```typescript
// Player joined
socket.on('player_joined', (player: Player) => {
  // Update player list
});

// Player left
socket.on('player_left', ({ playerId }) => {
  // Remove from list
});

// Player disconnected (network issue)
socket.on('player_disconnected', ({ playerId }) => {
  // Show "reconnecting..." indicator
});

// Player reconnected
socket.on('player_reconnected', ({ playerId }) => {
  // Remove "reconnecting..." indicator
});

// Room closed by host
socket.on('room_closed', () => {
  // Navigate back to entry
  navigate('/');
});
```

#### Game Events (Defined in game/FRONTEND.md)

```typescript
// Countdown before game starts
socket.on('countdown', ({ count }) => {
  // Show 3, 2, 1...
});

// Game state updated
socket.on('game_state_update', (gameState) => {
  // Update game UI (see game/FRONTEND.md)
});
```

---

### 3. Auth Store (`store/authStore.ts`)

**Purpose:** Manage player session state using Zustand.

**State:**
```typescript
interface AuthState {
  session: Session | null;
  setSession: (session: Session | null) => void;
  clearSession: () => void;
}

interface Session {
  playerId: string;
  gameCode: string;
  displayName: string;
  avatarId: string;
  isHost: boolean;
}
```

**Implementation:**
```typescript
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      session: null,
      setSession: (session) => set({ session }),
      clearSession: () => set({ session: null })
    }),
    {
      name: 'auth-storage',  // LocalStorage key
    }
  )
);
```

**Usage in Components:**
```typescript
const { session, setSession } = useAuthStore();

// After login
setSession({
  playerId: data.playerId,
  gameCode: data.gameCode,
  displayName: 'Alice',
  avatarId: '1',
  isHost: true
});
```

---

### 4. Theme Store (`store/themeStore.ts`)

**Purpose:** Manage dark/light mode preference.

**State:**
```typescript
interface ThemeState {
  isDark: boolean;
  toggleTheme: () => void;
}
```

**Implementation:**
```typescript
export const useThemeStore = create<ThemeState>()(
  persist(
    (set) => ({
      isDark: false,
      toggleTheme: () => set((state) => ({ isDark: !state.isDark }))
    }),
    {
      name: 'theme-storage'
    }
  )
);
```

**Apply Theme:**
```typescript
useEffect(() => {
  if (isDark) {
    document.documentElement.classList.add('dark');
  } else {
    document.documentElement.classList.remove('dark');
  }
}, [isDark]);
```

---

## Environment Variables

**Required in `.env`:**

```bash
VITE_API_URL=http://localhost:3000           # Backend API URL
VITE_SOCKET_URL=http://localhost:3000        # WebSocket URL
```

**Production:**
```bash
VITE_API_URL=https://your-backend.onrender.com
VITE_SOCKET_URL=https://your-backend.onrender.com
```

**Access in code:**
```typescript
const API_URL = import.meta.env.VITE_API_URL;
const SOCKET_URL = import.meta.env.VITE_SOCKET_URL;
```

---

## Styling with Tailwind

**Mobile-First Approach:**

```typescript
<div className="
  flex flex-col          // Stack vertically
  p-4                    // Padding on all sides
  max-w-md               // Max width 448px
  mx-auto                // Center horizontally
  min-h-screen           // Full viewport height
  bg-white dark:bg-gray-900   // Theme support
">
  {/* Content */}
</div>
```

**Touch-Friendly Buttons:**
```typescript
<button className="
  min-h-[44px]           // iOS minimum touch target
  px-6 py-3              // Generous padding
  text-lg                // Readable text
  rounded-lg             // Rounded corners
  active:scale-95        // Press animation
  transition-transform   // Smooth animation
">
  Click Me
</button>
```

**Dark Mode Support:**
```typescript
// In tailwind.config.js
module.exports = {
  darkMode: 'class',   // Use class-based dark mode
  // ...
};

// In components
<div className="bg-white dark:bg-gray-900 text-black dark:text-white">
  Content
</div>
```

---

## Mobile Optimization

**Viewport Meta Tag:**
```html
<!-- index.html -->
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
```

**Prevent Pull-to-Refresh:**
```css
/* index.css */
body {
  overscroll-behavior: none;
}
```

**Safe Area for Notches:**
```css
.app {
  padding-top: env(safe-area-inset-top);
  padding-bottom: env(safe-area-inset-bottom);
}
```

---

## Deployment (Render.com)

**Static Site Configuration:**

```yaml
Build Command: npm install && npm run build
Publish Directory: dist
```

**Environment Variables:**
- `VITE_API_URL` - Backend API URL
- `VITE_SOCKET_URL` - WebSocket URL

**Build Output:**
```
dist/
├── index.html
├── assets/
│   ├── index-[hash].js
│   └── index-[hash].css
└── avatars/
    └── *.svg
```

---

## Critical Rules for AI

### ✅ DO (Platform Responsibilities):

- Handle auth flow (name, avatar, create/join)
- Display waiting room with player list
- Connect to WebSocket with auto-reconnection
- Show countdown before game
- Display scores during gameplay
- Handle session restoration on refresh
- Provide share functionality
- Manage routing between pages

### ❌ DON'T (Game Responsibilities):

- Render game board UI
- Handle game-specific input
- Display game-specific state
- Implement game rules or validation

**Game UI belongs in `game/FRONTEND.md`**

---

## Common Pitfalls

### Problem: Session not persisting on refresh

**Solution:** Ensure `credentials: 'include'` in all fetch calls:

```typescript
fetch(url, {
  credentials: 'include'  // CRITICAL
});
```

### Problem: WebSocket not auto-reconnecting

**Solution:** Ensure `withCredentials: true` in socket config:

```typescript
io(url, {
  withCredentials: true  // CRITICAL
});
```

### Problem: Players not seeing updates

**Solution:** Ensure socket event listeners are registered:

```typescript
useEffect(() => {
  socket.on('player_joined', handler);
  return () => socket.off('player_joined');  // Cleanup!
}, []);
```

---

## Integration with Game Logic

**Platform provides these hooks for game:**

```typescript
// In GamePage.tsx
useEffect(() => {
  const socket = socketService.getSocket();
  
  // Platform event (handled here)
  socket.on('player_disconnected', ({ playerId }) => {
    // Show indicator
  });
  
  // Game event (see game/FRONTEND.md)
  socket.on('game_state_update', (state) => {
    // Update game UI (game-specific)
  });
  
  return () => {
    socket.off('player_disconnected');
    socket.off('game_state_update');
  };
}, []);
```

**See `game/FRONTEND.md` for game-specific event handlers and UI.**

---

## Version

**Platform Frontend v1.0**  
Last Updated: January 2026  
Based on: Production SET game infrastructure

---

## Summary

This frontend provides:
- ✅ Complete auth flow
- ✅ Waiting room with invites
- ✅ WebSocket management
- ✅ Session persistence
- ✅ Mobile-first design
- ✅ Dark mode support
- ✅ Production-ready

**For game-specific UI, see:** `game/FRONTEND.md`