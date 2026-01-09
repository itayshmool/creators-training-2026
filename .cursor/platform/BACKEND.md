# Platform Backend - Multiplayer Infrastructure

**Version:** 1.0  
**Purpose:** Reusable backend infrastructure for 1-4 player real-time multiplayer games  
**Status:** ✅ 100% REUSABLE - Do not modify for game-specific logic

---

## Core Philosophy

This backend provides **complete multiplayer infrastructure** that is game-agnostic. All room management, player sessions, WebSocket connections, and authentication are handled here. Game-specific logic belongs in `game/BACKEND.md`.

**Key Principle:** Platform handles WHO is playing and HOW they connect. Game handles WHAT they're playing.

---

## Tech Stack

- **Runtime:** Node.js + TypeScript
- **Framework:** Express.js
- **Real-time:** Socket.io (WebSocket)
- **Auth:** JWT (HTTP-only cookies)
- **Storage:** In-memory (Map-based, no database)
- **Deployment:** Render.com

---

## File Structure

```
backend/src/
├── app.ts                    # Express app setup & CORS
├── index.ts                  # Server entry + Socket.io initialization
├── services/
│   └── gameService.ts        # ✅ Room & player state management
├── websocket/
│   └── gameHandler.ts        # ✅ WebSocket event handlers  
├── controllers/
│   └── authController.ts     # ✅ HTTP auth endpoints
├── utils/
│   ├── auth.ts              # ✅ JWT helpers
│   └── gameLogic.ts         # 🔄 GAME-SPECIFIC (see game/BACKEND.md)
└── types/
    ├── game.types.ts        # 🔄 GAME-SPECIFIC (see game/BACKEND.md)
    └── index.ts             # ✅ Shared platform types
```

**Legend:**
- ✅ = 100% reusable, never modify
- 🔄 = Game-specific, replace per game

---

## Core Services

### 1. GameService (`services/gameService.ts`)

**Purpose:** Central manager for all game rooms and player state.

**Core Data Structure:**
```typescript
private rooms: Map<string, GameRoom> = new Map();
```

All game state lives in memory. No database required for MVP.

#### Reusable Methods (NEVER modify these):

| Method | Signature | Purpose |
|--------|-----------|---------|  
| `createRoom(hostInfo)` | `(PlayerInfo) => GameRoom` | Creates new room with 6-char code |
| `getRoom(gameCode)` | `(string) => GameRoom \| null` | Retrieves room by code |
| `joinRoom(gameCode, playerInfo)` | `(string, PlayerInfo) => GameRoom` | Adds player (max 4) |
| `updateSocketId(...)` | `(gameCode, playerId, socketId) => GameRoom` | Updates on reconnect |
| `markPlayerDisconnected(...)` | `(gameCode, playerId) => void` | Marks offline |
| `removeIfStillDisconnected(...)` | `(gameCode, playerId) => void` | Removes after grace period |
| `updatePlayerActivity(...)` | `(gameCode, playerId) => void` | Updates timestamp |
| `removePlayer(...)` | `(gameCode, playerId) => void` | Removes permanently |
| `deleteRoom(gameCode)` | `(string) => void` | Deletes empty room |
| `cleanupDeadRooms()` | `() => void` | Cleans abandoned rooms |

#### Host Management

**Auto Host Transfer:**
- If host leaves, next player becomes host automatically
- Silent transfer, no user intervention needed
- If host wants to close room, all players removed

**Host Privileges:**
- Only host can start the game
- Host controls game lifecycle

#### Room Lifecycle

```
1. Host creates room → Status: "waiting"
2. Players join (1-4 total)
3. Host starts game → Countdown begins
4. Game activates → Status: "active"
5. Game ends → Status: "finished"
6. All players leave → Room deleted
```

#### Reconnection System

**3-Tier Disconnect Handling:**

1. **Immediate (0-5s):** Network glitch, ignore
2. **Grace Period (5s-3min):** Player marked disconnected, can rejoin
3. **Timeout (3min+):** Player removed from room

**Implementation:**
```typescript
// On disconnect:
setTimeout(() => {
  gameService.markPlayerDisconnected(gameCode, playerId);
  io.to(gameCode).emit('player_disconnected', { playerId });
}, 5000); // 5 second buffer

setTimeout(() => {
  gameService.removeIfStillDisconnected(gameCode, playerId);
}, 180000); // 3 minute grace period
```

---

### 2. WebSocket Handler (`websocket/gameHandler.ts`)

**Purpose:** Manages all real-time Socket.io events.

#### Platform Events (100% Reusable)

| Event | Direction | Payload | Purpose |
|-------|-----------|---------|---------|  
| `connection` | Client → Server | `socket` | New socket connected |
| `join_room_socket` | Client → Server | `{ gameCode, playerId }` | Join room via WebSocket |
| `leave_room` | Client → Server | `{ gameCode, playerId }` | Explicit leave |
| `disconnect` | Client → Server | Auto | Socket disconnected |
| `player_joined` | Server → Client | `Player` | Notify someone joined |
| `player_left` | Server → Client | `{ playerId }` | Notify someone left |
| `player_disconnected` | Server → Client | `{ playerId }` | Connection lost |
| `player_reconnected` | Server → Client | `{ playerId }` | Player back online |
| `room_closed` | Server → Client | `{}` | Host ended game |

#### Game-Specific Events (Defined in game/BACKEND.md)

| Event | Direction | Purpose |
|-------|-----------|---------|  
| `start_game` | Client → Server | Host starts game |
| `game_state_update` | Server → Client | Sync game state |
| *Custom events* | Both | Game-specific actions |

#### Auto-Reconnection on Page Load

**Critical Feature:** Players auto-rejoin on page refresh

```typescript
io.on('connection', (socket) => {
  // Read JWT from cookie
  const cookies = cookie.parse(socket.request.headers.cookie || '');
  const token = cookies.session;
  
  if (token) {
    const payload = verifyToken(token);
    const { playerId, gameCode } = payload;
    
    // Auto-reconnect player
    const room = gameService.updateSocketId(gameCode, playerId, socket.id);
    
    if (room) {
      socket.join(gameCode);
      io.to(gameCode).emit('player_reconnected', { playerId });
    }
  }
});
```

**Why this works:**
- JWT stored in HTTP-only cookie
- Cookie sent automatically with WebSocket connection
- Server reads cookie and restores session

#### Socket Room Pattern

**Always use Socket.io rooms for broadcasts:**

```typescript
// Join socket room (matches game code)
socket.join(gameCode);

// Broadcast to all players in room
io.to(gameCode).emit('event_name', data);

// Broadcast to all EXCEPT sender
socket.to(gameCode).emit('event_name', data);

// Send to specific socket
io.to(socketId).emit('event_name', data);
```

---

### 3. Authentication System

**Philosophy:** Zero friction - no passwords, no registration.

#### Auth Controller (`controllers/authController.ts`)

**Endpoints:**

##### POST `/api/auth/create-session`
**Purpose:** Host creates new game or solo player starts

**Request:**
```typescript
{
  displayName: string;  // 3-12 characters
  avatarId: string;     // "1" to "8"
}
```

**Response:**
```typescript
{
  playerId: string;     // UUID
  gameCode: string;     // 6-char uppercase
  session: {
    playerId: string;
    gameCode: string;
    displayName: string;
    avatarId: string;
    isHost: true
  }
}

Set-Cookie: session=<JWT>; HttpOnly; SameSite=Strict; Secure (in prod)
```

##### POST `/api/auth/join-game`
**Purpose:** Player joins existing game

**Request:**
```typescript
{
  displayName: string;
  avatarId: string;
  gameCode: string;     // 6-char code from host
}
```

**Response:**
```typescript
{
  playerId: string;
  session: {
    playerId: string;
    gameCode: string;
    displayName: string;
    avatarId: string;
    isHost: false
  }
}

Set-Cookie: session=<JWT>; HttpOnly; SameSite=Strict
```

##### GET `/api/auth/verify-session`
**Purpose:** Check if session is valid (page refresh)

**Request:** Cookie header with JWT

**Response:**
```typescript
{
  valid: boolean;
  session?: {
    playerId: string;
    gameCode: string;
    displayName: string;
    avatarId: string;
    isHost: boolean;
  }
}
```

#### JWT Implementation (`utils/auth.ts`)

**Token Payload:**
```typescript
{
  playerId: string;
  gameCode: string;
  displayName: string;
  avatarId: string;
  isHost: boolean;
  iat: number;         // Issued at
  exp: number;         // Expires (24 hours)
}
```

**Key Functions:**
```typescript
generateToken(payload: SessionPayload): string
verifyToken(token: string): SessionPayload | null
```

**Security Rules:**
- HTTP-only cookies (not accessible via JavaScript)
- 24-hour expiration
- Signed with strong secret (env var)
- No sensitive data in payload
- SameSite=Strict (CSRF protection)
- Secure flag in production

---

## Core Types (`types/index.ts`)

**Platform Types (100% Reusable):**

```typescript
// Player in a room
interface Player {
  id: string;                    // UUID
  displayName: string;           // 3-12 chars
  avatarId: string;              // "1"-"8"
  isHost: boolean;               // Host privileges
  socketId: string | null;       // Current socket ID
  connected: boolean;            // Online status
  lastActivity: Date;            // For timeout detection
}

// Game room container
interface GameRoom {
  gameCode: string;              // 6-char uppercase
  players: Player[];             // Max 4 players
  status: RoomStatus;            // Lifecycle state
  createdAt: Date;               // For cleanup
  gameState: any;                // Game-specific state (defined in game/BACKEND.md)
}

// Room lifecycle states
type RoomStatus = 
  | "waiting"     // Lobby, waiting for host to start
  | "countdown"   // 3-2-1 countdown before game
  | "active"      // Game in progress
  | "finished";   // Game ended

// Session data in JWT
interface SessionPayload {
  playerId: string;
  gameCode: string;
  displayName: string;
  avatarId: string;
  isHost: boolean;
}

// Player info for joining
interface PlayerInfo {
  displayName: string;
  avatarId: string;
}
```

---

## Environment Variables

**Required in `.env`:**

```bash
# Server
PORT=3000                                    # Backend port
NODE_ENV=development                         # development | production

# CORS
FRONTEND_URL=http://localhost:5173          # Frontend origin (Vite default)

# Auth
JWT_SECRET=your-super-secret-key-here       # Min 32 chars, strong random
```

**Production Overrides:**
```bash
NODE_ENV=production
FRONTEND_URL=https://your-app.onrender.com
PORT=10000  # Render assigns this
```

---

## Express App Setup (`app.ts`)

**Critical CORS Configuration:**

```typescript
import cors from 'cors';

app.use(cors({
  origin: process.env.FRONTEND_URL,    // Exact match only
  credentials: true,                    // CRITICAL: Allows cookies
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type']
}));
```

**Why credentials: true is critical:**
- Allows cookies to be sent with requests
- Required for JWT session persistence
- Must match `withCredentials: true` on frontend

**Cookie Parser:**
```typescript
import cookieParser from 'cookie-parser';
app.use(cookieParser());
```

---

## Server Initialization (`index.ts`)

**Socket.io Setup:**

```typescript
import { Server } from 'socket.io';
import { createServer } from 'http';

const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: process.env.FRONTEND_URL,
    credentials: true    // CRITICAL: Allows cookies
  }
});

// Initialize WebSocket handlers
initializeGameHandlers(io);

httpServer.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

---

## Error Handling Patterns

**Always use try-catch for async operations:**

```typescript
// HTTP endpoints
app.post('/api/auth/create-session', (req, res) => {
  try {
    // ... logic
    res.json(response);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// WebSocket handlers
socket.on('join_room_socket', (data) => {
  try {
    // ... logic
    io.to(gameCode).emit('player_joined', player);
  } catch (error) {
    console.error('Error:', error);
    socket.emit('error', { message: 'Failed to join room' });
  }
});
```

**Validation Rules:**
- Game code: 6 characters, uppercase alphanumeric
- Display name: 3-12 characters
- Avatar ID: "1" to "8"
- Room capacity: Max 4 players

---

## Room Cleanup System

**Automatic cleanup of dead rooms:**

```typescript
// Run every 5 minutes
setInterval(() => {
  gameService.cleanupDeadRooms();
}, 5 * 60 * 1000);
```

**Cleanup criteria:**
- No players in room
- Room older than 24 hours
- All players disconnected for 3+ minutes

---

## Logging Strategy

**Use consistent emoji-based logging:**

```
✅ Room created: ABC123 by Alice (status: waiting)
🏠 Bob joined room ABC123 (2/4 players)
⏳ Countdown started for room: ABC123
🎮 Game activated in room: ABC123
⚠️  Disconnect detected: Charlie (id123) from ABC123
✅ Reconnection success: Charlie reconnected after 12s
👋 Alice is leaving room ABC123
🗑️  Room ABC123 deleted (no players remaining)
```

**Always log:**
- Room creation/deletion
- Player join/leave/disconnect
- Game lifecycle changes
- Errors with context

---

## Deployment (Render.com)

**Backend Configuration:**

```yaml
Build Command: npm install && npm run build
Start Command: npm start
Environment Variables:
  - JWT_SECRET (strong random string)
  - FRONTEND_URL (your frontend URL)
  - NODE_ENV=production
```

**Important:**
- Render assigns PORT automatically
- Use `process.env.PORT || 3000`
- Enable WebSocket support in Render settings
- Set cookie Secure flag in production

---

## Testing Infrastructure

**Reusable Test Patterns:**

```typescript
// Room creation
describe('GameService - Room Management', () => {
  test('creates room with 6-char code', () => {
    const room = gameService.createRoom(hostInfo);
    expect(room.gameCode).toMatch(/^[A-Z0-9]{6}$/);
  });
});

// Reconnection
describe('WebSocket - Reconnection', () => {
  test('player reconnects after disconnect', async () => {
    // Disconnect player
    socket.disconnect();
    
    // Reconnect within grace period
    const newSocket = io(SERVER_URL);
    
    // Verify auto-rejoin
    expect(room.players[0].connected).toBe(true);
  });
});
```

---

## Critical Rules for AI

### ✅ DO (Platform Responsibilities):

- Handle room creation/deletion
- Manage player sessions
- Handle WebSocket connections
- Implement reconnection logic
- Manage host transfer
- Validate game codes
- Store session in JWT cookies
- Broadcast platform events (player_joined, player_left, etc.)

### ❌ DON'T (Game Responsibilities):

- Validate game moves
- Calculate scores
- Determine winners
- Generate game state
- Implement game rules
- Define game-specific types

**Game logic belongs in `game/BACKEND.md`**

---

## Common Pitfalls

### Problem: JWT not sent with WebSocket

**Solution:** Ensure cookies are configured correctly:

```typescript
// Backend CORS
cors({ origin: FRONTEND_URL, credentials: true })

// Socket.io CORS
io({ cors: { origin: FRONTEND_URL, credentials: true } })

// Frontend socket
io(URL, { withCredentials: true })
```

### Problem: Players not reconnecting after refresh

**Solution:** Check JWT cookie is HTTP-only and not expired:

```typescript
res.cookie('session', token, {
  httpOnly: true,
  sameSite: 'strict',
  maxAge: 24 * 60 * 60 * 1000,  // 24 hours
  secure: process.env.NODE_ENV === 'production'
});
```

### Problem: Room not found after refresh

**Solution:** In-memory storage is cleared on server restart. For production, consider Redis (post-MVP).

---

## Integration with Game Logic

**Platform provides these hooks for game:**

```typescript
// When game starts
socket.on('start_game', (data) => {
  // Platform handles countdown
  startCountdown(gameCode);
  
  // Game initializes state (see game/BACKEND.md)
  const initialGameState = initializeGame(room);
  room.gameState = initialGameState;
  
  // Broadcast to all players
  io.to(gameCode).emit('game_state_update', initialGameState);
});
```

**See `game/BACKEND.md` for game-specific event handlers.**

---

## Version

**Platform Backend v1.0**  
Last Updated: January 2026  
Based on: Production SET game infrastructure

---

## Summary

This backend provides:
- ✅ Room/lobby management
- ✅ WebSocket real-time sync
- ✅ Session-based auth (no passwords)
- ✅ Smart reconnection
- ✅ Host management
- ✅ Mobile-optimized
- ✅ Production-ready

**For game-specific logic, see:** `game/BACKEND.md`