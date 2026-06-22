# ICTEdgePro — Claude Collaboration Guide

## Project Overview
A prop firm trading dashboard using Supabase (auth + data) and TradingView charts. Single-file application: `index.html`.

**Live:** https://ict-edge-pro.vercel.app

## Key Architecture

### File Structure
- **index.html** — All HTML, CSS, JS in one file (~1500 lines)
- **supabase/schema.sql** — Database schema (profiles, trades, RLS policies)
- **.claude/launch.json** — Local dev server config (python -m http.server 3456)

### Authentication (Supabase REST API)
- **Endpoints:**
  - `POST /auth/v1/signup` → creates user + triggers profile auto-create
  - `POST /auth/v1/token?grant_type=password` → login, returns access_token
  - `POST /auth/v1/logout` → logout
- **Session Storage:** localStorage keys: `fs_token` (JWT), `fs_user` (JSON user object)
- **Safe wrappers:** `lsGet(k)`, `lsSet(k,v)`, `lsDel(k)` — all wrapped in try-catch (localStorage can be blocked in data: URLs)

### Screen Gating
- `GATED_SCREENS` object (line ~897): `{dashboard:true, progress:true, account:true, lockout:true}`
- `show(screen)` function (line ~1043): checks GATED_SCREENS, shows landing → auth if user not authenticated
- Auth screen: `.auth-screen{display:none}` + `.auth-screen.active{display:flex}` (CSS specificity fix)

### User Flow
1. **Unauthenticated:** See landing page, auth box on click
2. **After signup/login:** Auth box hides, user icon (👤) shows in nav top right
3. **Click user icon:** Go to Account settings
4. **Logout:** Icon disappears, auth box returns

## Recent Fixes (Session 2)

### 1. Auth Box Not Disappearing
- **Root cause:** CSS specificity — `.auth-screen{display:flex}` overrode `.screen{display:none}`
- **Fix:** Split into `.auth-screen{display:none}` + `.auth-screen.active{display:flex}`
- **Deployed:** Vercel commit "fix: hide auth screen when user logs in"

### 2. User Icon in Top Right
- **Added:** `.user-icon` CSS + HTML element in nav
- **Show on auth:** `showApp()` adds `.visible` class
- **Hide on logout:** `showAuthScreen()` removes `.visible` class
- **Click behavior:** Navigates to Account settings
- **Deployed:** Vercel commit "feat: add user icon in top right nav"

## Code Patterns to Follow

### localStorage Access
```js
var u = lsGet('fs_user');
lsSet('fs_token', token);
lsDel('fs_token');
```
**Never:** Direct `localStorage.getItem()` — use the safe wrappers.

### Auth Requests
```js
sbFetch('/auth/v1/signup', 'POST', {email, password})
  .then(function(r){
    currentUser = r.user;
    lsSet('fs_token', r.session.access_token);
    setTimeout(function(){showApp()}, 0);
  })
  .catch(function(e){
    var msg = document.getElementById('signup-msg');
    if(msg) msg.textContent = 'Error: ' + e.message;
  });
```
**Pattern:** `.then()` chains, not async/await. Errors caught and displayed to user.

### Screen Navigation
```js
show('dashboard');  // Checks GATED_SCREENS, redirects to auth if locked
```

### Supabase config
- URL: `https://kbmqpwbhwpagfqnghtiv.supabase.co`
- ANON_KEY: In top of script block (public key, safe to expose)
- All at top of file, easy to find

## Testing Checklist

- [ ] Signup → auth box disappears, user icon shows
- [ ] Click user icon → Account screen loads
- [ ] Account screen shows email + tier badge
- [ ] Logout → icon hides, auth box shows
- [ ] Page reload → session persists (localStorage)
- [ ] Click navbar tabs → gating works (redirects unauthenticated users to auth)

## Debug Tips

- **Console logs:** Prefixed with `[FUNCTION_NAME]` for tracing
- **localStorage blocked?** Try a HTTPS context (Vercel) or adjust browser settings
- **Auth failing?** Check Supabase dashboard: Authentication > Users, verify RLS policies in SQL Editor
- **CSS not applying?** Check specificity — class combinators stack (`.auth-screen.active` beats `.auth-screen`)

## Optional Next Steps

- Remove `console.log` debug statements from production code
- Add dark/light mode toggle
- Implement email verification flow
- Add password reset
- Test subscription tier switching (plan enum in profiles table)
