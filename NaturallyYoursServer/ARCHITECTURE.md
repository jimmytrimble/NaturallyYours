# System Architecture

## Authentication Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Naturally Yours iOS App                      │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │   Login      │  │   Sign Up    │  │  Guest Checkout    │   │
│  │   Screen     │  │   Screen     │  │     Screen         │   │
│  └──────┬───────┘  └──────┬───────┘  └────────┬───────────┘   │
│         │                  │                    │                │
└─────────┼──────────────────┼────────────────────┼────────────────┘
          │                  │                    │
          │    HTTPS/JSON    │                    │
          │                  │                    │
┌─────────▼──────────────────▼────────────────────▼────────────────┐
│                    Vapor Backend Server                           │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    Route Layer                            │   │
│  │  /api/auth/users/*   /api/auth/admins/*   /api/guest/*   │   │
│  └──────────────────────────────┬────────────────────────────┘   │
│                                 │                                 │
│  ┌──────────────────────────────▼────────────────────────────┐   │
│  │                  Middleware Layer                          │   │
│  │  • Session Middleware                                      │   │
│  │  • Authentication Middleware                               │   │
│  │  • Admin Role Middleware                                   │   │
│  └──────────────────────────────┬────────────────────────────┘   │
│                                 │                                 │
│  ┌──────────────────────────────▼────────────────────────────┐   │
│  │                  Controller Layer                          │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  │   │
│  │  │     User     │  │    Admin     │  │   Product     │  │   │
│  │  │  Controller  │  │  Controller  │  │  Controller   │  │   │
│  │  └──────────────┘  └──────────────┘  └───────────────┘  │   │
│  └──────────────────────────────┬────────────────────────────┘   │
│                                 │                                 │
│  ┌──────────────────────────────▼────────────────────────────┐   │
│  │                     Model Layer                            │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  │   │
│  │  │     User     │  │    Admin     │  │   Session     │  │   │
│  │  │    Model     │  │    Model     │  │    Model      │  │   │
│  │  └──────────────┘  └──────────────┘  └───────────────┘  │   │
│  └──────────────────────────────┬────────────────────────────┘   │
│                                 │                                 │
└─────────────────────────────────┼─────────────────────────────────┘
                                  │
                  Fluent ORM      │
                                  │
┌─────────────────────────────────▼─────────────────────────────────┐
│                      PostgreSQL Database                          │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐         │
│  │    users     │  │    admins    │  │   sessions    │         │
│  ├──────────────┤  ├──────────────┤  ├───────────────┤         │
│  │ id           │  │ id           │  │ key           │         │
│  │ name         │  │ name         │  │ data          │         │
│  │ email        │  │ email        │  │ expires_at    │         │
│  │ password_hash│  │ password_hash│  └───────────────┘         │
│  │ created_at   │  │ role         │                             │
│  │ updated_at   │  │ created_at   │                             │
│  └──────────────┘  │ updated_at   │                             │
│                    └──────────────┘                             │
└───────────────────────────────────────────────────────────────────┘
```

## User Authentication Flow

```
Customer App                    Vapor Server                Database
     │                               │                         │
     │─────Sign Up Request──────────>│                         │
     │  (name, email, password)      │                         │
     │                               │───Validate Input────────│
     │                               │───Hash Password─────────│
     │                               │───Check Duplicate──────>│
     │                               │<──No Duplicates─────────│
     │                               │───Create User──────────>│
     │                               │<──User Created──────────│
     │                               │───Create Session───────>│
     │                               │<──Session Created───────│
     │<────Auth Response + Cookie────│                         │
     │                               │                         │
     │─────Get Profile (/me)────────>│                         │
     │  (with session cookie)        │───Verify Session───────>│
     │                               │<──Session Valid─────────│
     │                               │───Get User Data────────>│
     │                               │<──User Data─────────────│
     │<────User Profile Data─────────│                         │
     │                               │                         │
```

## Admin Authentication & Authorization Flow

```
Admin App                       Vapor Server                Database
     │                               │                         │
     │─────Admin Login Request──────>│                         │
     │  (email, password)            │                         │
     │                               │───Validate Creds───────>│
     │                               │<──Admin Found───────────│
     │                               │───Verify Password───────│
     │                               │───Create Session───────>│
     │                               │<──Session Created───────│
     │<────Auth Response + Cookie────│                         │
     │                               │                         │
     │─────Create Product───────────>│                         │
     │  (with admin session)         │───Verify Session───────>│
     │                               │<──Session Valid─────────│
     │                               │───Check Role (Admin)────│
     │                               │───Is Moderator/Super────│
     │                               │───Create Product───────>│
     │                               │<──Product Created───────│
     │<────Product Response──────────│                         │
     │                               │                         │
     │─────Delete Admin─────────────>│                         │
     │  (with super admin session)   │───Verify Session───────>│
     │                               │<──Session Valid─────────│
     │                               │───Check Role────────────│
     │                               │───Is Super Admin?───────│
     │                               │───Delete Admin─────────>│
     │                               │<──Admin Deleted─────────│
     │<────Success Response──────────│                         │
     │                               │                         │
```

## Guest Checkout Flow

```
Customer App                    Vapor Server                Database
     │                               │                         │
     │───Browse Products (Public)───>│───Get Products─────────>│
     │                               │<──Product List──────────│
     │<───Product List───────────────│                         │
     │                               │                         │
     │───Add to Cart (Local)         │                         │
     │                               │                         │
     │───Guest Checkout─────────────>│                         │
     │  (email, cart, address)       │───Validate Email────────│
     │                               │───Create Order─────────>│
     │                               │<──Order Created─────────│
     │                               │───Process Payment───────│
     │                               │───Send Email────────────│
     │<───Order Confirmation─────────│                         │
     │                               │                         │
```

## Role-Based Access Control (RBAC)

```
┌─────────────────────────────────────────────────────────┐
│                    Admin Hierarchy                       │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │           Super Admin (Full Access)            │    │
│  │  • Create/Delete Admins                        │    │
│  │  • Edit Products & Prices                      │    │
│  │  • Edit App Layout                             │    │
│  │  • View Customer Data                          │    │
│  └─────────────────┬──────────────────────────────┘    │
│                    │                                     │
│         ┌──────────┴──────────┐                         │
│         │                     │                         │
│  ┌──────▼──────────┐  ┌──────▼──────────┐             │
│  │   Moderator     │  │    Support      │             │
│  │  • Edit Products│  │  • View Only    │             │
│  │  • Edit Prices  │  │  • Read Customer│             │
│  │  • Edit Layout  │  │    Data         │             │
│  └─────────────────┘  └─────────────────┘             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Security Layers

```
┌───────────────────────────────────────────────────────────┐
│                    Request Flow                            │
│                                                            │
│  iOS App Request                                           │
│       │                                                    │
│       ▼                                                    │
│  ┌─────────────────────────────────────────────────┐     │
│  │  1. HTTPS/TLS Encryption                        │     │
│  └──────────────────┬──────────────────────────────┘     │
│                     ▼                                      │
│  ┌─────────────────────────────────────────────────┐     │
│  │  2. Session Cookie Validation                   │     │
│  │     • Check if session exists                   │     │
│  │     • Verify session not expired                │     │
│  └──────────────────┬──────────────────────────────┘     │
│                     ▼                                      │
│  ┌─────────────────────────────────────────────────┐     │
│  │  3. Authentication Middleware                   │     │
│  │     • Verify user/admin is authenticated        │     │
│  │     • Load user/admin from database             │     │
│  └──────────────────┬──────────────────────────────┘     │
│                     ▼                                      │
│  ┌─────────────────────────────────────────────────┐     │
│  │  4. Authorization Middleware (Admin Routes)     │     │
│  │     • Check admin role                          │     │
│  │     • Verify permissions for action             │     │
│  └──────────────────┬──────────────────────────────┘     │
│                     ▼                                      │
│  ┌─────────────────────────────────────────────────┐     │
│  │  5. Controller Logic                            │     │
│  │     • Process request                           │     │
│  │     • Business logic                            │     │
│  │     • Database operations                       │     │
│  └──────────────────┬──────────────────────────────┘     │
│                     ▼                                      │
│  ┌─────────────────────────────────────────────────┐     │
│  │  6. Response                                    │     │
│  │     • Return JSON data                          │     │
│  │     • Set/Update cookies                        │     │
│  └─────────────────────────────────────────────────┘     │
│                                                            │
└───────────────────────────────────────────────────────────┘
```

## Password Security

```
User Password: "SecurePass123"
       │
       ▼
┌─────────────────────────────────────┐
│  Client-Side Validation              │
│  • Minimum 8 characters              │
│  • Contains uppercase                │
│  • Contains lowercase                │
│  • Contains number                   │
└──────────────┬───────────────────────┘
               │
               ▼
         Sent to Server
               │
               ▼
┌─────────────────────────────────────┐
│  Server-Side Validation              │
│  • Re-validate requirements          │
│  • Check password confirmation       │
└──────────────┬───────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Bcrypt Hashing (Cost Factor: 12)   │
│  • Salt generation                   │
│  • Hash computation                  │
│  • Result: $2b$12$xyz...             │
└──────────────┬───────────────────────┘
               │
               ▼
         Stored in Database
               │
         (Never store plain)
               │
         On Login Attempt
               │
               ▼
┌─────────────────────────────────────┐
│  Password Verification               │
│  • Retrieve hash from DB             │
│  • Compare with input password       │
│  • Bcrypt.verify()                   │
│  • Match = Success, else Fail        │
└─────────────────────────────────────┘
```

## Data Models Relationship

```
┌──────────────┐
│     User     │
│──────────────│
│ id (PK)      │───────┐
│ name         │       │
│ email (UQ)   │       │
│ password_hash│       │
│ created_at   │       │
│ updated_at   │       │
└──────────────┘       │
                       │  (Future)
                       │  One-to-Many
                       │
                       ▼
                  ┌──────────┐
                  │  Orders  │
                  │──────────│
                  │ id (PK)  │
                  │ user_id  │
                  │ total    │
                  │ status   │
                  └──────────┘

┌──────────────┐
│    Admin     │
│──────────────│
│ id (PK)      │
│ name         │
│ email (UQ)   │
│ password_hash│
│ role         │◄─── Enum: super_admin, moderator, support
│ created_at   │
│ updated_at   │
└──────────────┘


┌──────────────┐
│   Session    │
│──────────────│
│ key (PK)     │
│ data         │◄─── Stores user_id or admin_id
│ expires_at   │
└──────────────┘
```

This architecture provides:
- ✅ Clear separation of concerns
- ✅ Secure authentication flow
- ✅ Role-based access control
- ✅ Scalable design
- ✅ Easy to extend with new features
