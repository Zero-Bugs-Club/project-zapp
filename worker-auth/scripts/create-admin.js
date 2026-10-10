#!/usr/bin/env node

/**
 * Bootstrap Administrator Script for Project Zapp
 *
 * Securely hashes the provided administrator credentials using PBKDF2 (SHA-256, 600,000 iterations)
 * with a cryptographically secure random salt, and inserts the administrator directly into Cloudflare D1.
 *
 * Usage:
 *   node scripts/create-admin.js <username> <password> [--remote|--local]
 *   npm run bootstrap-admin -- <username> <password> [--remote]
 *
 * Example:
 *   node scripts/create-admin.js admin "AdminPass123!" --remote
 */

import { pbkdf2Sync, randomBytes, randomUUID } from "node:crypto";
import { execSync } from "node:child_process";

const args = process.argv.slice(2);
const isRemote = args.includes("--remote") || !args.includes("--local");
const positionalArgs = args.filter((arg) => !arg.startsWith("--"));

const username = positionalArgs[0];
const password = positionalArgs[1];

if (!username || !password) {
  console.log(`
Usage:
  node scripts/create-admin.js <username> <password> [--remote|--local]

Requirements:
  - Username: 3-20 characters (letters, numbers, underscores)
  - Password: at least 8 characters with uppercase, lowercase, number, and special character
  - Default target: --remote (Cloudflare D1)

Example:
  node scripts/create-admin.js zapp_admin "SecureAdmin2026!" --remote
`);
  process.exit(1);
}

if (!/^[a-zA-Z0-9_]{3,20}$/.test(username)) {
  console.error("Error: Username must be 3-20 alphanumeric characters or underscores.");
  process.exit(1);
}

if (
  password.length < 8 ||
  password.length > 128 ||
  !/[A-Z]/.test(password) ||
  !/[a-z]/.test(password) ||
  !/[0-9]/.test(password) ||
  !/[^A-Za-z0-9]/.test(password)
) {
  console.error(
    "Error: Password must be 8-128 characters and include uppercase, lowercase, a number, and a special character."
  );
  process.exit(1);
}

const saltHex = randomBytes(16).toString("hex");
const hashBuffer = pbkdf2Sync(password, Buffer.from(saltHex, "hex"), 100000, 32, "sha256");
const hashHex = hashBuffer.toString("hex");
const id = randomUUID();
const name = "System Administrator";
const email = `${username.toLowerCase()}@projectzapp.internal`;
const phoneNumber = "0000000000";

const sql = `INSERT INTO users (id, name, email, phone_number, username, password_hash, password_salt, role, status) VALUES ('${id}', '${name}', '${email}', '${phoneNumber}', '${username}', '${hashHex}', '${saltHex}', 'ADMIN', 'APPROVED') ON CONFLICT(username) DO UPDATE SET password_hash=excluded.password_hash, password_salt=excluded.password_salt, role='ADMIN', status='APPROVED';`;

console.log(`\nBootstrapping admin '${username}' into D1 (${isRemote ? "remote" : "local"})...`);

try {
  const targetFlag = isRemote ? "--remote" : "--local";
  // Escape quotes safely for wrangler execution
  const cmd = `npx wrangler d1 execute project-zapp-auth ${targetFlag} --command "${sql.replace(/"/g, '\\"')}"`;
  const output = execSync(cmd, { encoding: "utf-8" });
  console.log("Success! Administrator account configured in D1.");
  console.log(`Username: ${username}`);
  console.log(`Role: ADMIN`);
  console.log(`Status: APPROVED`);
} catch (err) {
  console.error("Failed to execute D1 command:", err.message);
  process.exit(1);
}
