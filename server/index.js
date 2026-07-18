const express = require("express");
const http = require("http");
const crypto = require("crypto");
const { WebSocketServer } = require("ws");
const { categories, products } = require("./data/products");

const app = express();
app.use(express.json());

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

const memberColors = ["#22C55E", "#3B82F6", "#A855F7", "#F59E0B", "#EF4444", "#06B6D4"];

/** @type {Map<string, {id:string,name:string,code:string,colorHex:string,sharedCartId:string|null}>} */
const users = new Map();
/** @type {Map<string, {id:string,code:string}>} code -> userId lookup done by scanning users (small dataset) */

/** @type {Map<string, {id:string,name:string,memberIds:string[],items:Array<{productId:string,qty:number,addedById:string,addedAt:number}>}>} */
const carts = new Map();

/** cartId -> Set<ws> */
const rooms = new Map();

function genId() {
  return crypto.randomBytes(9).toString("base64url");
}

function genCode() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let code;
  do {
    code = Array.from({ length: 6 }, () => chars[crypto.randomInt(chars.length)]).join("");
  } while ([...users.values()].some((u) => u.code === code));
  return code;
}

function findUserByCode(code) {
  return [...users.values()].find((u) => u.code === code.toUpperCase());
}

function publicUser(u) {
  return { id: u.id, name: u.name, code: u.code, colorHex: u.colorHex, sharedCartId: u.sharedCartId };
}

function cartMembers(cart) {
  return cart.memberIds.map((id) => publicUser(users.get(id))).filter(Boolean);
}

function broadcastToRoom(cartId, message) {
  const room = rooms.get(cartId);
  if (!room) return;
  const json = JSON.stringify(message);
  for (const ws of room) {
    if (ws.readyState === ws.OPEN) ws.send(json);
  }
}

function broadcastCartState(cartId) {
  const cart = carts.get(cartId);
  if (!cart) return;
  broadcastToRoom(cartId, { type: "cart:state", cart, members: cartMembers(cart) });
}

function broadcastEvent(cartId, payload) {
  broadcastToRoom(cartId, { type: "cart:event", ...payload });
}

// ---------- REST ----------

app.post("/api/users", (req, res) => {
  const name = (req.body?.name || "").trim();
  if (!name) return res.status(400).json({ error: "name is required" });
  const user = {
    id: genId(),
    name,
    code: genCode(),
    colorHex: memberColors[0],
    sharedCartId: null,
  };
  users.set(user.id, user);
  res.json({ user: publicUser(user) });
});

app.get("/api/users/:id", (req, res) => {
  const user = users.get(req.params.id);
  if (!user) return res.status(404).json({ error: "not found" });
  res.json({ user: publicUser(user) });
});

app.get("/api/products", (req, res) => {
  res.json({ categories, products });
});

app.post("/api/connect", (req, res) => {
  const { userId, code } = req.body || {};
  const self = users.get(userId);
  if (!self) return res.status(404).json({ error: "No user with that code" });

  if (self.code === (code || "").toUpperCase()) {
    return res.status(400).json({ error: "That's your own code 🙂" });
  }

  const other = findUserByCode(code || "");
  if (!other) return res.status(404).json({ error: "No user with that code" });

  if (self.sharedCartId && self.sharedCartId === other.sharedCartId) {
    const cart = carts.get(self.sharedCartId);
    return res.json({ user: publicUser(self), cart, members: cartMembers(cart), note: "Already connected" });
  }

  if (self.sharedCartId && other.sharedCartId) {
    return res.status(409).json({ error: `${other.name} is already in another Home Cart` });
  }

  let cart, joiner;
  if (!self.sharedCartId && !other.sharedCartId) {
    cart = { id: genId(), name: "Home Cart", memberIds: [], items: [] };
    carts.set(cart.id, cart);
    addMemberToCart(cart, self);
    addMemberToCart(cart, other);
    joiner = other;
  } else {
    const existingOwner = self.sharedCartId ? self : other;
    joiner = self.sharedCartId ? other : self;
    cart = carts.get(existingOwner.sharedCartId);
    addMemberToCart(cart, joiner);
  }

  broadcastCartState(cart.id);
  broadcastEvent(cart.id, { actorId: joiner.id, actorName: joiner.name, eventType: "join" });

  res.json({ user: publicUser(self), cart, members: cartMembers(cart) });
});

function addMemberToCart(cart, user) {
  if (cart.memberIds.includes(user.id)) return;
  const idx = cart.memberIds.length % memberColors.length;
  user.colorHex = memberColors[idx];
  user.sharedCartId = cart.id;
  cart.memberIds.push(user.id);
}

app.get("/api/carts/:id", (req, res) => {
  const cart = carts.get(req.params.id);
  if (!cart) return res.status(404).json({ error: "not found" });
  res.json({ cart, members: cartMembers(cart) });
});

// ---------- WebSocket ----------

wss.on("connection", (ws) => {
  ws.on("message", (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch {
      return;
    }

    const { type } = msg;

    if (type === "cart:join") {
      const { cartId, userId } = msg;
      if (!carts.has(cartId)) return;
      ws.cartId = cartId;
      ws.userId = userId;
      if (!rooms.has(cartId)) rooms.set(cartId, new Set());
      rooms.get(cartId).add(ws);
      broadcastCartState(cartId);
      return;
    }

    if (type === "cart:add") {
      const { cartId, userId, productId } = msg;
      const cart = carts.get(cartId);
      const product = products.find((p) => p.id === productId);
      if (!cart || !product) return;
      const existing = cart.items.find((i) => i.productId === productId);
      if (existing) {
        existing.qty += 1;
        broadcastCartState(cartId);
        broadcastEvent(cartId, { actorId: userId, actorName: nameOf(userId), eventType: "qty", productName: product.name, qty: existing.qty });
      } else {
        cart.items.push({ productId, qty: 1, addedById: userId, addedAt: Date.now() });
        broadcastCartState(cartId);
        broadcastEvent(cartId, { actorId: userId, actorName: nameOf(userId), eventType: "add", productName: product.name });
      }
      return;
    }

    if (type === "cart:updateQty") {
      const { cartId, userId, productId, qty } = msg;
      const cart = carts.get(cartId);
      if (!cart) return;
      const product = products.find((p) => p.id === productId);
      if (qty <= 0) {
        cart.items = cart.items.filter((i) => i.productId !== productId);
        broadcastCartState(cartId);
        broadcastEvent(cartId, { actorId: userId, actorName: nameOf(userId), eventType: "remove", productName: product?.name });
        return;
      }
      const item = cart.items.find((i) => i.productId === productId);
      if (!item) return;
      item.qty = qty;
      broadcastCartState(cartId);
      broadcastEvent(cartId, { actorId: userId, actorName: nameOf(userId), eventType: "qty", productName: product?.name, qty });
      return;
    }

    if (type === "cart:remove") {
      const { cartId, userId, productId } = msg;
      const cart = carts.get(cartId);
      if (!cart) return;
      const product = products.find((p) => p.id === productId);
      cart.items = cart.items.filter((i) => i.productId !== productId);
      broadcastCartState(cartId);
      broadcastEvent(cartId, { actorId: userId, actorName: nameOf(userId), eventType: "remove", productName: product?.name });
      return;
    }

    if (type === "cart:checkout") {
      const { cartId, userId } = msg;
      const cart = carts.get(cartId);
      if (!cart) return;
      cart.items = [];
      broadcastCartState(cartId);
      broadcastEvent(cartId, { actorId: userId, actorName: nameOf(userId), eventType: "checkout" });
      return;
    }
  });

  ws.on("close", () => {
    if (ws.cartId && rooms.has(ws.cartId)) {
      rooms.get(ws.cartId).delete(ws);
    }
  });
});

function nameOf(userId) {
  return users.get(userId)?.name ?? "Someone";
}

const PORT = 3001;
server.listen(PORT, () => {
  console.log(`Blinkit shared-cart server listening on :${PORT}`);
});
