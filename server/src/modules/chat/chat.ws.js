/**
 * WebSocket cho chat real-time.
 * - Client kết nối tới ws(s)://host/ws?token=<JWT>.
 * - Server xác thực token -> userId, giữ map userId -> các socket đang mở.
 * - Khi có tin nhắn mới (lưu qua REST), gọi pushToUser(recipientId, payload)
 *   để đẩy tới phía nhận ngay lập tức.
 */
import { WebSocketServer } from 'ws';
import { verifyToken } from '../../utils/token.js';

/** userId -> Set<WebSocket> */
const clients = new Map();

function add(userId, ws) {
  if (!clients.has(userId)) clients.set(userId, new Set());
  clients.get(userId).add(ws);
}
function remove(userId, ws) {
  const set = clients.get(userId);
  if (!set) return;
  set.delete(ws);
  if (set.size === 0) clients.delete(userId);
}

/** Đẩy 1 payload JSON tới mọi socket đang mở của user. */
export function pushToUser(userId, payload) {
  const set = clients.get(userId);
  if (!set) return;
  const data = JSON.stringify(payload);
  for (const ws of set) {
    if (ws.readyState === ws.OPEN) ws.send(data);
  }
}

/** Gắn WebSocket server vào HTTP server (xử lý upgrade ở path /ws). */
export function attachChatWebSocket(httpServer) {
  const wss = new WebSocketServer({ noServer: true });

  httpServer.on('upgrade', (req, socket, head) => {
    const { pathname, searchParams } = new URL(req.url, 'http://localhost');
    if (pathname !== '/ws') return; // không phải chat -> bỏ qua

    const token = searchParams.get('token');
    let userId;
    try {
      userId = verifyToken(token || '').id;
    } catch {
      socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
      socket.destroy();
      return;
    }
    wss.handleUpgrade(req, socket, head, (ws) => {
      ws.userId = Number(userId);
      ws.isAlive = true;
      add(ws.userId, ws);
      ws.on('pong', () => (ws.isAlive = true));
      ws.on('close', () => remove(ws.userId, ws));
      ws.on('error', () => remove(ws.userId, ws));
      ws.send(JSON.stringify({ type: 'connected' }));
    });
  });

  // Heartbeat: đóng các socket chết sau mỗi 30s.
  const interval = setInterval(() => {
    for (const set of clients.values()) {
      for (const ws of set) {
        if (!ws.isAlive) {
          ws.terminate();
          continue;
        }
        ws.isAlive = false;
        ws.ping();
      }
    }
  }, 30000);
  wss.on('close', () => clearInterval(interval));

  return wss;
}
