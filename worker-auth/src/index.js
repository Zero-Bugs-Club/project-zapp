import { SignJWT, jwtVerify } from "jose";

const encoder = new TextEncoder();
const TOKEN_LIFETIME = "8h";
const PASSWORD_ITERATIONS = 100000;
const DUMMY_SALT = "0123456789abcdef0123456789abcdef";

function getClientIp(request) {
  return (
    request.headers.get("CF-Connecting-IP") ||
    request.headers.get("X-Forwarded-For")?.split(",")[0]?.trim() ||
    "127.0.0.1"
  );
}

function corsHeaders(request, env) {
  const origin = request.headers.get("Origin");
  const allowed = (env?.ALLOWED_ORIGIN || "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);

  const isLocalhost =
    origin && /^https?:\/\/(localhost|127\.0\.0\.1)(:[0-9]+)?$/i.test(origin);

  const isAllowed =
    !origin ||
    allowed.includes("*") ||
    allowed.includes(origin) ||
    isLocalhost;

  const allowOrigin = isAllowed ? (origin || "*") : (allowed[0] || "*");

  return {
    "Access-Control-Allow-Origin": allowOrigin,
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin",
  };
}

function json(data, status = 200, extraHeaders = {}) {
  const headers = {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    ...extraHeaders,
  };

  return new Response(JSON.stringify(data), { status, headers });
}

function fail(message, status = 400, extraHeaders = {}) {
  return json({ error: message }, status, extraHeaders);
}

function withCors(response, request, env) {
  const headers = new Headers(response.headers);
  const cors = corsHeaders(request, env);
  for (const [key, value] of Object.entries(cors)) {
    headers.set(key, value);
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

async function readJson(request) {
  const contentType = request.headers.get("Content-Type") || "";
  if (!contentType.toLowerCase().includes("application/json")) {
    return null;
  }

  try {
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

async function checkRateLimit(key, maxAttempts, windowSeconds, env) {
  const now = Math.floor(Date.now() / 1000);
  const resetAt = now + windowSeconds;

  try {
    const existing = await env.DB.prepare(
      "SELECT attempts, reset_at FROM rate_limits WHERE key = ?"
    )
      .bind(key)
      .first();

    if (!existing || existing.reset_at <= now) {
      await env.DB.prepare(
        "INSERT INTO rate_limits (key, attempts, reset_at) VALUES (?, 1, ?) " +
          "ON CONFLICT(key) DO UPDATE SET attempts = 1, reset_at = excluded.reset_at"
      )
        .bind(key, resetAt)
        .run();
      return { allowed: true, remaining: maxAttempts - 1 };
    }

    if (existing.attempts >= maxAttempts) {
      const waitSeconds = Math.max(1, existing.reset_at - now);
      return { allowed: false, waitSeconds };
    }

    await env.DB.prepare(
      "UPDATE rate_limits SET attempts = attempts + 1 WHERE key = ?"
    )
      .bind(key)
      .run();

    return { allowed: true, remaining: maxAttempts - (existing.attempts + 1) };
  } catch (err) {
    console.warn("Rate limit check error:", err);
    return { allowed: true, remaining: 1 };
  }
}

async function resetRateLimit(key, env) {
  try {
    await env.DB.prepare("DELETE FROM rate_limits WHERE key = ?").bind(key).run();
  } catch {}
}

function validUsername(value) {
  return typeof value === "string" && /^[a-zA-Z0-9_]{3,20}$/.test(value.trim());
}

function validEmail(value) {
  if (typeof value !== "string" || value.length > 254) return false;
  return /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/.test(
    value.trim()
  );
}

function validPhone(value) {
  return typeof value === "string" && /^[0-9]{10}$/.test(value.trim());
}

function validName(value) {
  return (
    typeof value === "string" &&
    value.trim().length >= 2 &&
    value.trim().length <= 100 &&
    /^[a-zA-Z\s.'-]+$/.test(value.trim())
  );
}

function validPassword(value) {
  return (
    typeof value === "string" &&
    value.length >= 8 &&
    value.length <= 128 &&
    /[A-Z]/.test(value) &&
    /[a-z]/.test(value) &&
    /[0-9]/.test(value) &&
    /[^A-Za-z0-9]/.test(value)
  );
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
    hex.match(/.{2}/g).map((byte) => parseInt(byte, 16))
  );
}

function randomHex(length) {
  return bytesToHex(crypto.getRandomValues(new Uint8Array(length)));
}

async function passwordHash(password, saltHex) {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(password),
    "PBKDF2",
    false,
    ["deriveBits"]
  );

  const bits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      hash: "SHA-256",
      salt: hexToBytes(saltHex),
      iterations: PASSWORD_ITERATIONS,
    },
    key,
    256
  );

  return bytesToHex(new Uint8Array(bits));
}

function constantTimeEqual(a, b) {
  if (typeof a !== "string" || typeof b !== "string") return false;
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
      }
    );

    const user = await env.DB.prepare(
      `SELECT id, name, email, phone_number, username, role, status
       FROM users
       WHERE id = ?`
    )
      .bind(payload.sub)
      .first();

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

  if (user.role !== "ADMIN") {
    throw new Error("FORBIDDEN");
  }

  return user;
}

async function signup(request, env) {
  const clientIp = getClientIp(request);
  const rateKey = `signup:ip:${clientIp}`;
  const rateLimit = await checkRateLimit(rateKey, 10, 600, env);
  if (!rateLimit.allowed) {
    return fail(
      `Too many registration requests. Please try again in ${rateLimit.waitSeconds} seconds.`,
      429,
      { "Retry-After": rateLimit.waitSeconds.toString() }
    );
  }

  const body = await readJson(request);
  if (!body) {
    return fail("Invalid request body. Expected JSON object with required signup fields.", 400);
  }

  const name = typeof body.name === "string" ? body.name.trim() : "";
  const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
  const phoneNumber = typeof body.phoneNumber === "string" ? body.phoneNumber.trim() : "";
  const username = typeof body.username === "string" ? body.username.trim() : "";
  const password = body.password;

  if (!validName(name)) {
    return fail("Enter a valid full name (2–100 alphabetic characters).", 400);
  }

  if (!validEmail(email)) {
    return fail("Enter a valid email address.", 400);
  }

  if (!validPhone(phoneNumber)) {
    return fail("Enter a valid 10-digit mobile phone number.", 400);
  }

  if (!validUsername(username)) {
    return fail(
      "Username must be 3–20 characters and contain only letters, numbers, or underscores.",
      400
    );
  }

  if (!validPassword(password)) {
    return fail(
      "Password must be 8–128 characters and include uppercase, lowercase, a number, and a special character.",
      400
    );
  }

  const existing = await env.DB.prepare(
    "SELECT username, email FROM users WHERE username = ? COLLATE NOCASE OR email = ? COLLATE NOCASE"
  )
    .bind(username, email)
    .first();

  if (existing) {
    if (existing.username.toLowerCase() === username.toLowerCase()) {
      return fail("This username is already taken. Please choose another.", 409);
    }
    return fail("An account with this email address already exists.", 409);
  }

  const salt = randomHex(16);
  const hash = await passwordHash(password, salt);
  const id = crypto.randomUUID();

  try {
    await env.DB.prepare(
      `INSERT INTO users
       (id, name, email, phone_number, username,
        password_hash, password_salt, role, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'USER', 'PENDING')`
    )
      .bind(id, name, email, phoneNumber, username, hash, salt)
      .run();
  } catch (err) {
    console.error("Database insert error during signup:", err);
    return fail(
      "Unable to register account. Check your details or try a different username/email.",
      409
    );
  }

  return json(
    {
      message: "Registration submitted successfully. Await administrator approval.",
      status: "PENDING",
      user: {
        id,
        username,
        role: "USER",
        status: "PENDING",
      },
    },
    201
  );
}

async function login(request, env) {
  const clientIp = getClientIp(request);
  const ipRateKey = `login:ip:${clientIp}`;
  const ipLimit = await checkRateLimit(ipRateKey, 15, 600, env);
  if (!ipLimit.allowed) {
    return fail(
      `Too many login attempts. Please wait ${ipLimit.waitSeconds} seconds before trying again.`,
      429,
      { "Retry-After": ipLimit.waitSeconds.toString() }
    );
  }

  const body = await readJson(request);
  if (!body) {
    return fail("Invalid request body. Enter username and password.", 400);
  }

  const username = typeof body.username === "string" ? body.username.trim() : "";
  const password = body.password;

  if (!username || typeof password !== "string" || !password) {
    return fail("Enter a username and password.", 400);
  }

  const userRateKey = `login:user:${username.toLowerCase()}`;
  const userLimit = await checkRateLimit(userRateKey, 5, 600, env);
  if (!userLimit.allowed) {
    return fail(
      `Too many failed login attempts for this account. Please wait ${userLimit.waitSeconds} seconds before trying again.`,
      429,
      { "Retry-After": userLimit.waitSeconds.toString() }
    );
  }

  const user = await env.DB.prepare(
    `SELECT id, username, password_hash, password_salt, role, status
     FROM users
     WHERE username = ? COLLATE NOCASE`
  )
    .bind(username)
    .first();

  if (!user) {
    // Timing mitigation: perform dummy PBKDF2 hash so response time is indistinguishable
    try {
      await passwordHash(password, DUMMY_SALT);
    } catch {}
    return fail("Invalid username or password.", 401);
  }

  let computedHash;
  try {
    computedHash = await passwordHash(password, user.password_salt);
  } catch {
    return fail("Unable to authenticate this account.", 500);
  }

  if (!constantTimeEqual(computedHash, user.password_hash)) {
    return fail("Invalid username or password.", 401);
  }

  // Credentials match: clear rate limit keys
  await resetRateLimit(userRateKey, env);
  await resetRateLimit(ipRateKey, env);

  if (user.status === "PENDING") {
    return fail("Your account is awaiting administrator approval.", 403);
  }

  if (user.status === "REJECTED") {
    return fail("Your account registration has been rejected by an administrator.", 403);
  }

  if (user.status !== "APPROVED") {
    return fail("This account is not approved for login.", 403);
  }

  const token = await issueToken(user, env);

  return json(
    {
      token,
      user: {
        id: user.id,
        username: user.username,
        role: user.role,
        status: user.status,
      },
    },
    200
  );
}

async function me(request, env) {
  const user = await requireUser(request, env);

  return json(
    {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone_number: user.phone_number,
        username: user.username,
        role: user.role,
        status: user.status,
      },
    },
    200
  );
}

async function pendingUsers(request, env) {
  await requireAdmin(request, env);

  const result = await env.DB.prepare(
    `SELECT id, name, email, phone_number, username, role, status, created_at
     FROM users
     WHERE status = 'PENDING' AND role = 'USER'
     ORDER BY created_at ASC`
  ).all();

  return json(
    { users: result.results || [] },
    200
  );
}

async function reviewUser(request, env) {
  const admin = await requireAdmin(request, env);
  const body = await readJson(request);

  if (!body || typeof body.userId !== "string" || !body.userId.trim()) {
    return fail("A valid userId is required.", 400);
  }

  const status = body.status;
  if (!["APPROVED", "REJECTED"].includes(status)) {
    return fail("Status must be APPROVED or REJECTED.", 400);
  }

  const userId = body.userId.trim();
  if (userId === admin.id) {
    return fail("You cannot review your own account.", 400);
  }

  const result = await env.DB.prepare(
    `UPDATE users
     SET status = ?
     WHERE id = ? AND role = 'USER' AND status = 'PENDING'`
  )
    .bind(status, userId)
    .run();

  if (!result.meta.changes) {
    return fail("Pending user not found or already reviewed.", 404);
  }

  return json(
    {
      message: `Account ${status.toLowerCase()} successfully.`,
      userId,
      status,
    },
    200
  );
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
    if (request.method === "OPTIONS") {
      const headers = corsHeaders(request, env);
      return new Response(null, { status: 204, headers });
    }

    try {
      const response = await route(request, env);
      return withCors(response, request, env);
    } catch (error) {
      if (error.message === "UNAUTHORIZED") {
        return withCors(fail("Authentication required.", 401), request, env);
      }

      if (error.message === "FORBIDDEN") {
        return withCors(fail("Administrator access required.", 403), request, env);
      }

      console.error("Authentication request failed:", error);

      return withCors(
        fail("An internal server error occurred.", 500),
        request,
        env
      );
    }
  },
};
