-- ============================================================================
-- 1. USERS & AUTHENTICATION TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL COLLATE NOCASE UNIQUE,
    phone_number TEXT NOT NULL,
    username TEXT NOT NULL COLLATE NOCASE UNIQUE,
    password_hash TEXT NOT NULL,
    password_salt TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'USER'
        CHECK (role IN ('USER', 'ADMIN')),
    status TEXT NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_status
ON users(status);

CREATE INDEX IF NOT EXISTS idx_users_username
ON users(username);

-- ============================================================================
-- 2. COURSE REGISTRATIONS TABLE (Separated Structured Fields)
-- ============================================================================
CREATE TABLE IF NOT EXISTS courses (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    course_code TEXT NOT NULL,
    course_name TEXT NOT NULL,
    slot TEXT NOT NULL,
    venue TEXT NOT NULL,
    faculty_name TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_courses_user
ON courses(user_id);

CREATE INDEX IF NOT EXISTS idx_courses_code
ON courses(course_code);

-- ============================================================================
-- 3. USER TIMETABLE SLOTS TABLE (7-Day Matrix for Overlap Logic)
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_timetable_slots (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    slot_code TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    course_code TEXT NOT NULL,
    venue TEXT NOT NULL,
    faculty_name TEXT NOT NULL,
    is_busy INTEGER NOT NULL DEFAULT 1 CHECK (is_busy IN (0, 1)),
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_slots_user_day
ON user_timetable_slots(user_id, day_of_week);

CREATE INDEX IF NOT EXISTS idx_slots_code
ON user_timetable_slots(slot_code);

-- ============================================================================
-- 4. STUDY SQUADS / GROUPS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS groups (
    id TEXT PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    created_by TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_groups_code
ON groups(code);

-- ============================================================================
-- 5. GROUP MEMBERSHIPS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS group_members (
    id TEXT PRIMARY KEY,
    group_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'MEMBER' CHECK (role IN ('OWNER', 'ADMIN', 'MEMBER')),
    joined_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(group_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_group_members_group
ON group_members(group_id);

CREATE INDEX IF NOT EXISTS idx_group_members_user
ON group_members(user_id);

-- ============================================================================
-- 6. RATE LIMITING TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS rate_limits (
    key TEXT PRIMARY KEY,
    attempts INTEGER NOT NULL DEFAULT 1,
    reset_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_rate_limits_reset
ON rate_limits(reset_at);