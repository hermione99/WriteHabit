# Firebase Indexes Required for DailyWrite

These indexes are required for the app to function properly. Create them in Firebase Console.

## How to Create Indexes

1. Go to https://console.firebase.google.com
2. Select your DailyWrite project
3. Click **Firestore Database** in left menu
4. Click **Indexes** tab
5. Click **Composite indexes**
6. Click **Add index** for each one below

---

## Required Indexes (6 total)

### 1. Daily Keywords (global_keywords)
**Purpose:** Get today's keyword by language

- **Collection:** `global_keywords`
- **Fields:**
  - `language` → Ascending
  - `date` → Ascending
- **Query scope:** Collection

---

### 2. User Drafts (essays)
**Purpose:** Get user's saved drafts

- **Collection:** `essays`
- **Fields:**
  - `authorId` → Ascending
  - `isDraft` → Ascending
  - `updatedAt` → Descending
- **Query scope:** Collection

---

### 3. Published Essays (essays)
**Purpose:** Get user's published essays

- **Collection:** `essays`
- **Fields:**
  - `authorId` → Ascending
  - `isDraft` → Ascending
  - `createdAt` → Descending
- **Query scope:** Collection

---

### 4. Public Feed (essays)
**Purpose:** Get public essays for the feed

- **Collection:** `essays`
- **Fields:**
  - `isPublic` → Ascending
  - `isDraft` → Ascending
  - `createdAt` → Descending
- **Query scope:** Collection

---

### 5. Writing Archive (essays)
**Purpose:** Get essays in date range for calendar

- **Collection:** `essays`
- **Fields:**
  - `authorId` → Ascending
  - `createdAt` → Descending
- **Query scope:** Collection

---

### 6. Used Keywords (global_keywords)
**Purpose:** Track keywords used in last 365 days

- **Collection:** `global_keywords`
- **Fields:**
  - `language` → Ascending
  - `date` → Descending
- **Query scope:** Collection

---

## Status Check

After creating, status will show:
- 🟡 **Building** (wait 2-5 minutes)
- 🟢 **Enabled** (ready!)

## Alternative: Direct Link from Error

When you run the app, if an index is missing, the console will show an error with a link like:
```
https://console.firebase.google.com/project/YOUR_PROJECT/database/firestore/indexes?create_composite=...
```

**Click that link** → it pre-fills everything → just click **Create**

---

## Quick Checklist

| # | Collection | Fields | Status |
|---|------------|--------|--------|
| 1 | global_keywords | language ↑, date ↑ | ☐ |
| 2 | essays | authorId ↑, isDraft ↑, updatedAt ↓ | ☐ |
| 3 | essays | authorId ↑, isDraft ↑, createdAt ↓ | ☐ |
| 4 | essays | isPublic ↑, isDraft ↑, createdAt ↓ | ☐ |
| 5 | essays | authorId ↑, createdAt ↓ | ☐ |
| 6 | global_keywords | language ↑, date ↓ | ☐ |

**Create all 6, then rebuild your app!**
