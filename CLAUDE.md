# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Admin Scaffold (后台管理脚手架) is a Phoenix Framework-based admin management system with user authentication, dashboard, and RBAC (Role-Based Access Control) features. The project is in Chinese and English mixed context.

**Tech Stack:**
- Phoenix 1.8.3
- Elixir ~> 1.15
- PostgreSQL
- Phoenix LiveView 1.1.0
- Tailwind CSS + esbuild for assets
- Swoosh for email (configured but not fully set up)
- Bandit web server

## Essential Commands

### Setup and Development
```bash
# Initial setup (deps + database + assets)
mix setup

# Start development server
mix phx.server

# Start with IEx console
iex -S mix phx.server
```

### Database Operations
```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Reset database (drop + create + migrate + seed)
mix ecto.reset

# Generate new migration
mix ecto.gen.migration migration_name
```

### Testing and Quality
```bash
# Run tests
mix test

# Run single test file
mix test test/path/to/test_file.exs

# Run specific test by line number
mix test test/path/to/test_file.exs:42

# Format code
mix format

# Run Credo linter
mix credo

# Pre-commit checks (compile with warnings as errors, format, test)
mix precommit
```

### Asset Management
```bash
# Install asset tools
mix assets.setup

# Build assets for development
mix assets.build

# Build and minify assets for production
mix assets.deploy
```

## Architecture Overview

### Context-Based Architecture

The application follows Phoenix's context pattern with clear boundaries:

**1. Accounts Context** (`lib/admin_scaffold/accounts.ex`)
- Manages all user-related operations
- Handles authentication and authorization
- Contains User, Role, Permission, Menu, and Scope schemas
- Provides functions for user CRUD, authentication, and RBAC

**2. System Context** (schemas in `lib/admin_scaffold/system/`)
- Settings management (`Setting` schema)
- Audit logging (`AuditLog` schema)

### Authentication System

**Session-based authentication** with token management:
- `UserAuth` plug module (`lib/admin_scaffold_web/user_auth.ex`) handles all auth logic
- Session tokens stored in `users_tokens` table
- Remember-me cookie valid for 14 days
- Session reissue after 7 days for active users
- `fetch_current_scope_for_user` plug loads current user into conn

**Key auth functions:**
- `require_authenticated_user` - Pipeline for protected routes
- `log_in_user/3` - Creates session and sets cookies
- `log_out_user/1` - Clears session and tokens
- `on_mount: [{AdminScaffoldWeb.UserAuth, :require_authenticated}]` - LiveView mount hook

### RBAC System (Role-Based Access Control)

Multi-tenant capable with Scope support:

**Database Schema:**
- `users` - User accounts
- `roles` - Role definitions
- `permissions` - Permission definitions
- `menus` - Menu items for navigation
- `user_roles` - Many-to-many: users ↔ roles
- `role_permissions` - Many-to-many: roles ↔ permissions
- `role_menus` - Many-to-many: roles ↔ menus
- `scopes` - Tenant/organization isolation (referenced in User schema)

**Key Concepts:**
- Users can have multiple roles
- Roles contain multiple permissions
- Roles define which menus are accessible
- Scope field enables multi-tenancy (though not fully implemented yet)

### LiveView Structure

All main UI is LiveView-based (no traditional controllers except auth):

**Public Routes** (no auth required):
- `UserLive.Registration` - `/users/register`
- `UserLive.Login` - `/users/log-in`
- `UserLive.Confirmation` - `/users/log-in/:token`

**Protected Routes** (require authentication):
- `DashboardLive.Index` - `/dashboard` - Main dashboard with stats
- `UserLive.Index` - `/admin/users` - User management list
- `UserLive.Show` - `/admin/users/:id` - User details
- `UserLive.Settings` - `/users/settings` - User account settings
- `RoleLive.Index` - `/admin/roles` - Role management (with :new, :edit actions)
- `PermissionLive.Index` - `/admin/permissions` - Permission management

**LiveView Patterns:**
- Use `live_session` for grouping routes with shared auth requirements
- Form components in separate modules (e.g., `RoleLive.FormComponent`)
- Actions passed as live_action (`:index`, `:new`, `:edit`, `:show`)

### Router Configuration

Two main pipelines:
- `:browser` - Standard web requests with CSRF protection
- `:api` - JSON API (defined but not used yet)

Custom plug: `fetch_current_scope_for_user` loads user context

## Code Quality Standards

### Credo Configuration
- Strict mode enabled (`.credo.exs`)
- Max line length: 120 characters
- Module documentation required
- TODO tags allowed (exit_status: 0)
- FIXME tags flagged

### Formatting
- Standard Elixir formatter (`.formatter.exs`)
- Run `mix format` before committing

## Important Patterns

### Context Functions
- All business logic goes through context modules (e.g., `Accounts.create_user/1`)
- Never call `Repo` directly from controllers or LiveViews
- Use descriptive function names following Elixir conventions

### Error Handling
- Use `{:ok, result}` / `{:error, changeset}` tuples
- Changesets for validation errors
- Pattern match in LiveView to handle results

### Database Queries
- Import `Ecto.Query` in context modules
- Use `Repo.all/1`, `Repo.get/2`, `Repo.insert/1`, etc.
- Preload associations when needed

## Development Notes

### Email Configuration
- Swoosh is configured but uses `Local` adapter in dev
- Email confirmation tokens work but emails aren't sent
- Check `config/dev.exs` and `lib/admin_scaffold/mailer.ex`

### LiveDashboard
- Available in dev at `/dev/dashboard`
- Provides telemetry metrics and debugging tools
- Should be protected with auth in production

### Asset Pipeline
- Tailwind CSS for styling
- esbuild for JavaScript bundling
- Assets in `assets/` directory
- Compiled to `priv/static/`

### Testing
- Test database auto-created and migrated before tests
- Test helpers in `test/support/`
- Use `mix test` for full suite

## Common Workflows

### Adding a New LiveView Page
1. Create LiveView module in `lib/admin_scaffold_web/live/`
2. Add route in `router.ex` within appropriate `live_session`
3. Implement `mount/3` and `render/1` callbacks
4. Add to navigation if needed

### Adding a New Context
1. Create context module in `lib/admin_scaffold/`
2. Create schema modules in subdirectory
3. Generate migration with `mix ecto.gen.migration`
4. Implement CRUD functions in context
5. Add tests in `test/admin_scaffold/`

### Modifying Database Schema
1. Generate migration: `mix ecto.gen.migration descriptive_name`
2. Edit migration file in `priv/repo/migrations/`
3. Update corresponding schema module
4. Run `mix ecto.migrate`
5. Update tests and context functions as needed
