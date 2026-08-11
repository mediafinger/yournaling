# AUTHN & AUTHZ

Here is an in-depth inspection of the current **Authentication (AUTHN)** and **Authorization (AUTHZ)** implementations, highlighting key issues and actionable recommendations for improvement.

---

## 1. Authentication (AUTHN) Analysis & Issues

### 🔍 Current Architecture
* **Mechanism**: Custom session cookie `session[:user_id]` storing Base64 `urlsafe_id`, managed by [Authentication](file:///Users/andy/Dropbox/www/yournaling/app/controllers/concerns/authentication.rb) and [Logins](file:///Users/andy/Dropbox/www/yournaling/app/controllers/concerns/logins.rb).
* **Password**: `has_secure_password :password, validations: false` with manual length validation.
* **Session Limiting**: [Logins concern](file:///Users/andy/Dropbox/www/yournaling/app/controllers/concerns/logins.rb) tracks `Login` records and keeps the 3 most recent sessions.

---

### ⚠️ Identified AUTHN Issues

#### 1. The `guest_user` Pattern Bypasses `authenticate`
* **The Problem**: In [authentication.rb](file:///Users/andy/Dropbox/www/yournaling/app/controllers/concerns/authentication.rb#L32-L37):
  ```ruby
  def authenticate(allow_guest: true)
    return if current_user.present? && (current_user.persisted? || allow_guest)
    redirect_to :login
  end
  ```
  Since `current_user` defaults to `User.new(name: "Guest")`, `current_user.present?` is **always true**, and `allow_guest` defaults to `true`.
* **Impact**: `before_action :authenticate` in `ApplicationController` **never triggers a redirect to login**, leaving all unauthenticated requests to pass through as a "Guest" user. Authentication enforcement is pushed entirely onto authorization policies.

#### 2. Device Tracking Tied to IP Addresses Causes Premature Logouts
* **The Problem**: In [login.rb](file:///Users/andy/Dropbox/www/yournaling/app/models/login.rb#L15), `device_id` is computed as:
  ```ruby
  Digest::SHA256.hexdigest("#{ip_address} #{user_agent}")
  ```
* **Impact for Travelers**: For a mobile/travel app (*Yournaling*), users constantly switch Wi-Fi networks and cellular connections. Every IP change generates a **new `device_id`**. With `NUMBER_OF_LOGIN_SESSIONS_TO_KEEP = 3`, connecting to 3 different Wi-Fi spots from the same laptop will prune older `Login` records and **forcefully log the user out** via `logout_if_login_record_has_been_deleted`.

#### 3. Database Hit in Routing Layer (`AdminConstraint`)
* **The Problem**: In [admin_constraint.rb](file:///Users/andy/Dropbox/www/yournaling/app/route_constraints/admin_constraint.rb#L8), `User.urlsafe_find(request.session[:user_id])` performs an uncached database query on **every single request** matching `/admin/*` before routing.
* **Impact**: Adds unnecessary database overhead on static assets, pings, and dashboard refreshes.

#### 4. Missing Standard Auth Lifecycle Workflows
* No password reset mechanism (forgot password token + mailer).
* No email verification flow.
* No explicit session expiration / rolling timeout (`expires_at`).

---

## 2. Authorization (AUTHZ) Analysis & Issues

### 🔍 Current Architecture
* **Framework**: **ActionPolicy** ([ApplicationPolicy](file:///Users/andy/Dropbox/www/yournaling/app/policies/application_policy.rb)) with `verify_authorized` in `ApplicationController`.
* **Context**: `user` (`Current.user`), `team` (`Current.team`), `member` (`Current.member`).
* **Roles**: Multi-role PostgreSQL array column (`Member#roles`: `owner`, `manager`, `editor`, `publisher`).

---

### ⚠️ Identified AUTHZ Issues

#### 1. Overly Permissive Default Rules in Base Policy
* **The Problem**: In [ApplicationPolicy](file:///Users/andy/Dropbox/www/yournaling/app/policies/application_policy.rb#L21-L31):
  ```ruby
  alias_rule :show?, :index?, to: :read?
  def read?
    guest? # => returns true
  end
  def create?
    logged_in? # => any logged-in user can create
  end
  ```
* **Impact**: Any newly created model that inherits from `ApplicationPolicy` without an explicit policy class will **allow unauthenticated guests to read all records** and **allow any logged-in user to create records**. Authorization should be *"Deny by Default"*.

#### 2. Metaprogramming Overhead on Model Instantiation
* **The Problem**: In [member.rb](file:///Users/andy/Dropbox/www/yournaling/app/models/member.rb#L90-L96) and [user.rb](file:///Users/andy/Dropbox/www/yournaling/app/models/user.rb#L38-L44):
  ```ruby
  # in after_initialize:
  VALID_ROLES.each do |role|
    self.class.send(:define_method, :"#{role}?") { roles.include?(role.to_s) }
  end
  ```
* **Impact**: `define_method` is executed on the class **every time an instance is initialized** (`after_initialize`). In a loop of 100 members, the methods are redefined 100 times, causing class cache invalidation and performance penalties.

#### 3. Flat Roles Lack Hierarchical Inheritance
* **The Problem**: `with_role?(:owner, :manager, :editor)` checks exact array membership. An `owner` does not automatically inherit permissions of `editor` or `publisher` unless every policy explicitly enumerates all higher roles.
* **Impact**: Verbose policies prone to accidental privilege gaps (e.g. forgetting to add `:owner` when defining who can edit an article).

---

## 3. Recommended Suggestions & Improvements

### 💡 AUTHN Improvements

```
 ┌─────────────────────────────────────────────────────────────┐
 │                  Modernized AUTHN Flow                      │
 ├─────────────────────────────────────────────────────────────┤
 │ 1. Separate Authenticated vs Public Controllers             │
 │    • Use require_authentication! in app namespace           │
 │    • Explicit allow_unauthenticated_access for public views │
 │ 2. Secure Random Session Tokens (Device-Independent)        │
 │    • session[:session_token] = SecureRandom.hex(32)         │
 │    • Login record stores token hash + IP (for audit only)   │
 │ 3. Password Reset & Verification Flow                       │
 │    • User#generate_password_reset_token (SolidQueue mailer) │
 └─────────────────────────────────────────────────────────────┘
```

1. **Adopt Explicit Authentication Filters**:
   - Replace the `allow_guest: true` bypass with explicit filters:
     ```ruby
     # app/controllers/application_controller.rb
     before_action :authenticate_user!

     # app/controllers/teams/pages_controller.rb (public)
     skip_before_action :authenticate_user!
     ```
2. **Decouple Device Sessions from IP Addresses**:
   - Use a persistent random `session_token` stored in the session cookie and hashed in the database (`Login#token_digest`).
   - Treat IP address and User-Agent purely as audit metadata (displaying "Last active from IP / Location") rather than a session identifier that invalidates connections on IP change.
3. **Session Expiry**:
   - Add `expires_at` or idle timeout (e.g. 30 days of inactivity) to `Login` records.

---

### 💡 AUTHZ Improvements

1. **Switch to "Deny by Default" Base Policy**:
   ```ruby
   # app/policies/application_policy.rb
   def read?
     false # Deny by default; child policies must explicitly allow
   end

   def create?
     false
   end
   ```
2. **Implement Role Hierarchy / Permission Matrix**:
   - Give `owner` and `manager` automatic superset capabilities:
     ```ruby
     # app/models/member.rb
     ROLE_HIERARCHY = {
       "owner"     => %w[owner manager editor publisher reader],
       "manager"   => %w[manager editor publisher reader],
       "editor"    => %w[editor reader],
       "publisher" => %w[publisher reader],
       "reader"    => %w[reader]
     }.freeze

     def has_permission?(permission)
       roles.any? { |r| ROLE_HIERARCHY[r]&.include?(permission.to_s) }
     end
     ```
3. **Remove `define_method` from `after_initialize`**:
   - Define role predicate methods statically at the class level once:
     ```ruby
     VALID_ROLES.each do |role|
       define_method(:"#{role}?") { roles.include?(role) }
     end
     ```
4. **Cache / Streamline `AdminConstraint`**:
   - Store an encrypted `is_admin` claim directly in the session or cache `user.admin?` lookup to eliminate DB queries on route matching.
