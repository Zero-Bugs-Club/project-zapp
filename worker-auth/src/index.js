```javascript
import { SignJWT, jwtVerify } from "jose";

const encoder = new TextEncoder();
const TOKEN_LIFETIME = "8h";

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });
}

function fail(message, status = 400) {
  return json({ error: message }, status);
}

function corsHeaders(request, env) {
  const origin = request.headers.get("Origin");
  const allowed = (env.ALLOWED_ORIGIN || "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);

  return {
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Vary": "Origin",
    ...(origin && allowed.includes(origin)
      ? { "Access-Control-Allow-Origin": origin }
      : {}),
  };
}

function withCors(response, request, env) {
  const headers = new Headers(response.headers);
  for (const [key, value] of Object.entries(corsHeaders(request, env))) {
    headers.set(key, value);
  }
  return new Response(response.body, {
    status: response.status,
    headers,
  });
}

async function readJson(request) {
  try {
    const length = Number(request.headers.get("Content-Length") || 0);
    if (length > 10000) return null;

    const text = await request.text();
    if (text.length > 10000) return null;

    const value = JSON.parse(text);
    return value && typeof value === "object" && !Array.isArray(value)
      ? value
      : null;
  } catch {
    return null;
  }
}

function validUsername(value) {
  return typeof value === "string" &&
    /^[a-zA-Z0-9_]{3,20}$/.test(value);
}

function validEmail(value) {
  return typeof value === "string" &&
    value.length <= 254 &&
    /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value);
}

function validPassword(value) {
  return typeof value === "string" &&
    value.length >= 8 &&
    value.length <= 128 &&
    /[A-Z]/.test(value) &&
    /[a-z]/.test(value) &&
    /[0-9]/.test(value) &&
    /[^A-Za-z0-9]/.test(value);
}

function bytesToHex(bytes) {
  return Array.from(bytes)
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function hexToBytes(hex) {
  if (typeof hex !== "string" || !/^(?:[0-9a-f]{2})+$/i.test(hex)) {
    throw new Error("Invalid stored hash");
  }

  return new Uint8Array(
    hex.match(/.{2}/g).map((byte) => parseInt(byte, 16)),
  );
}

function randomHex(length) {
  const bytes = crypto.getRandomValues(new Uint8Array(length));
  return bytesToHex(bytes);
}

async function passwordHash(password, saltHex) {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(password),
    "PBKDF2",
    false,
    ["deriveBits"],
  );

  const bits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      hash: "SHA-256",
      salt: hexToBytes(saltHex),
      iterations: 600000,
    },
    key,
    256,
  );

  return bytesToHex(new Uint8Array(bits));
}

function constantTimeEqual(a, b) {
  if (a.length !== b.length) return false;
  let difference = 0;
  for (let i = 0; i < a.length; i++) {
    difference |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return difference === 0;
}

async function issueToken(user, env) {
  const secret = encoder.encode(env.JWT_SECRET);
  return new SignJWT({
    role: user.role,
    status: user.status,
    username: user.username,
  })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(user.id)
    .setIssuer("project-zapp")
    .setAudience("project-zapp-app")
    .setIssuedAt()
    .setExpirationTime(TOKEN_LIFETIME)
    .sign(secret);
}

async function requireUser(request, env) {
  const header = request.headers.get("Authorization") || "";
  const match = header.match(/^Bearer (.+)$/i);

  if (!match) throw new Error("UNAUTHORIZED");

  try {
    const { payload } = await jwtVerify(
      match[1],
      encoder.encode(env.JWT_SECRET),
      {
        issuer: "project-zapp",
        audience: "project-zapp-app",
      },
    );

    const user = await env.DB.prepare(
      `SELECT id, username, role, status
       FROM users WHERE id = ?`,
    ).bind(payload.sub).first();

    if (!user || user.status !== "APPROVED") {
      throw new Error("UNAUTHORIZED");
    }

    return user;
  } catch {
    throw new Error("UNAUTHORIZED");
  }
}

async function requireAdmin(request, env) {
  const user = await requireUser(request, env);
  if (user.role !== "ADMIN") throw new Error("FORBIDDEN");
  return user;
}

async function signup(request, env) {
  const body = await readJson(request);
  if (!body) return fail("Invalid request body.");

  const name = typeof body.name === "string" ? body.name.trim() : "";
  const email = typeof body.email === "string"
    ? body.email.trim().toLowerCase()
    : "";
  const phoneNumber = typeof body.phoneNumber === "string"
    ? body.phoneNumber.trim()
    : "";
  const username = typeof body.username === "string"
    ? body.username.trim()
    : "";
  const password = body.password;

  if (name.length < 2 || name.length > 100) {
    return fail("Enter a valid name.");
  }
  if (!validEmail(email)) return fail("Enter a valid email address.");
  if (!/^[0-9]{10}$/.test(phoneNumber)) {
    return fail("Enter a valid 10-digit phone number.");
  }
  if (!validUsername(username)) return fail("Invalid username.");
  if (!validPassword(password)) {
    return fail("Password does not meet the required strength.");
  }

  const salt = randomHex(16);
  const hash = await passwordHash(password, salt);
  const id = crypto.randomUUID();

  try {
    await env.DB.prepare(
      `INSERT INTO users
       (id, name, email, phone_number, username,
        password_hash, password_salt, role, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'USER', 'PENDING')`,
    ).bind(
      id,
      name,
      email,
      phoneNumber,
      username,
      hash,
      salt,
    ).run();
  } catch {
    // Do not reveal which account identifier already exists.
    return fail(
      "Unable to register. Check your details or try a different username/email.",
      409,
    );
  }

  return json({
    message: "Registration submitted. Await administrator approval.",
    status: "PENDING",
  }, 201);
}

async function login(request, env) {
  const body = await readJson(request);
  if (!body) return fail("Invalid request body.");

  const username = typeof body.username === "string"
    ? body.username.trim()
    : "";
  const password = body.password;

  if (!username || typeof password !== "string" || !password) {
    return fail("Enter a username and password.", 400);
  }

  const user = await env.DB.prepare(
    `SELECT id, username, password_hash, password_salt, role, status
     FROM users WHERE username = ? COLLATE NOCASE`,
  ).bind(username).first();

  if (!user) return fail("Invalid username or password.", 401);

  let computedHash;
  try {
    computedHash = await passwordHash(password, user.password_salt);
  } catch {
    return fail("Unable to authenticate this account.", 500);
  }

  if (!constantTimeEqual(computedHash, user.password_hash)) {
    return fail("Invalid username or password.", 401);
  }

  if (user.status === "PENDING") {
    return fail("Your account is awaiting administrator approval.", 403);
  }

  if (user.status !== "APPROVED") {
    return fail("This account is not approved for login.", 403);
  }

  const token = await issueToken(user, env);

  return json({
    token,
    user: {
      id: user.id,
      username: user.username,
      role: user.role,
      status: user.status,
    },
  });
}

async function me(request, env) {
  const user = await requireUser(request, env);
  return json({
    user: {
      id: user.id,
      username: user.username,
      role: user.role,
      status: user.status,
    },
  });
}

async function pendingUsers(request, env) {
  await requireAdmin(request, env);

  const result = await env.DB.prepare(
    `SELECT id, name, email, phone_number, username, created_at
     FROM users
     WHERE status = 'PENDING'
     ORDER BY created_at ASC`,
  ).all();

  return json({ users: result.results || [] });
}

async function reviewUser(request, env) {
  const admin = await requireAdmin(request, env);
  const body = await readJson(request);

  if (!body || typeof body.userId !== "string") {
    return fail("A valid userId is required.");
  }

  if (!["APPROVED", "REJECTED"].includes(body.status)) {
    return fail("Status must be APPROVED or REJECTED.");
  }

  if (body.userId === admin.id) {
    return fail("You cannot review your own account.", 400);
  }

  const result = await env.DB.prepare(
    `UPDATE users
     SET status = ?
     WHERE id = ? AND role = 'USER' AND status = 'PENDING'`,
  ).bind(body.status, body.userId).run();

  if (!result.meta.changes) {
    return fail("Pending user not found.", 404);
  }

  return json({ message: `Account ${body.status.toLowerCase()}.` });
}

async function route(request, env) {
  if (!env.DB || !env.JWT_SECRET) {
    return fail("Server authentication is not configured.", 503);
  }

  const url = new URL(request.url);
  const path = url.pathname;

  if (request.method === "POST" && path === "/api/signup") {
    return signup(request, env);
  }
  if (request.method === "POST" && path === "/api/login") {
    return login(request, env);
  }
  if (request.method === "GET" && path === "/api/me") {
    return me(request, env);
  }
  if (request.method === "GET" && path === "/api/admin/pending") {
    return pendingUsers(request, env);
  }
  if (request.method === "POST" && path === "/api/admin/review") {
    return reviewUser(request, env);
  }

  return fail("Endpoint not found.", 404);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: corsHeaders(request, env),
      });
    }

    let response;

    try {
      response = await route(request, env);
    } catch (error) {
      if (error.message === "UNAUTHORIZED") {
        response = fail("Authentication required.", 401);
      } else if (error.message === "FORBIDDEN") {
        response = fail("Administrator access required.", 403);
      } else {
        console.error("Authentication request failed:", error);
        response = fail("An internal server error occurred.", 500);
      }
    }

    return withCors(response, request, env);
  },
};
```