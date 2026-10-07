# Bac2Win Security Audit Report

Date: 2026-07-06
Scope: local repository at `D:\Nouveau dossier\Bac2win_supabase_migration_ready\Bac2win_supabase`
Mode: parent-agent static review, no database/Supabase/auth/env changes.

## Executive Summary

This review found several real security issues that should be fixed before a public production launch.

Most important findings:

1. Public deployment likely exposes SQL migration files containing personal data.
2. The Netlify AI proxy is publicly callable and can burn the server-side Anthropic quota.
3. AI-generated HTML is inserted with `innerHTML` without sanitization.
4. No deployment security headers or CSP were found.
5. Third-party scripts are loaded without Subresource Integrity or local pinning.

## Limitations

The user requested a very long exhaustive scan. The current session rules did not permit spawning sub-agents unless explicitly requested, so this is a deep single-agent review, not a formal multi-agent exhaustive Codex Security scan.

No live Supabase/RLS mutation or database-side test was performed, per user constraints.

## Findings

### High: SQL files with personal data are probably publicly served

Affected files:

- `netlify.toml:2`
- `supabase-legacy-import.sql:6`
- `supabase-legacy-import.sql:10`
- `supabase-legacy-import.sql:14`

Evidence:

`netlify.toml` uses:

```toml
[build]
  publish = "."
```

This means root files are deployment content unless excluded by the host. The repository root contains `supabase-legacy-import.sql`, which includes real email addresses, legacy user ids, profile names, scores, history, and at least one imported image payload as a base64 data URL.

Impact:

If deployed as-is, visitors may be able to request `/supabase-legacy-import.sql` and download personal migration data.

Recommendation:

Do not publish the repository root. Move deployable static assets to a dedicated `public/` or `dist/` directory, or add Netlify rules excluding `*.sql`, migration files, local readmes, and internal artifacts. Remove personal data from files stored in the deploy tree.

### High: Public AI proxy has no authentication or rate limiting

Affected file:

- `functions/mathobac-ai.js:20`

Evidence:

The function accepts any `POST` and forwards requests to Anthropic using the server-side `ANTHROPIC_API_KEY`. It checks method and body size, but does not verify a logged-in user, origin, session, captcha, per-user quota, or rate limit.

Impact:

Anyone who discovers the endpoint can automate calls to `/.netlify/functions/mathobac-ai`, consume paid API quota, or degrade availability.

Recommendation:

Require authentication before proxying, enforce per-user/IP rate limits, restrict model values to an allowlist, clamp `temperature`, and reject overly large message arrays or unsupported content types.

### High: AI summary HTML is inserted without sanitization

Affected file:

- `index.html:6217`
- `index.html:6218`
- `index.html:6169`
- `index.html:6387`

Evidence:

The summary feature asks the model for "HTML simple", then stores and renders the model response directly:

```js
aiSummaryCache[id] = html;
document.getElementById('summary-content').innerHTML = html;
```

The imported document content is attacker-influenced. A prompt-injected document can try to make the model output `<img onerror=...>`, links with malicious handlers, or other active markup. The print feature later reuses the same `innerHTML`.

Impact:

Potential stored/self XSS in the user's browser context. If exploited, injected script could read localStorage data, Supabase session-adjacent app state, profile data, QCM history, imported file metadata, and call same-origin functions.

Recommendation:

Do not render model output as trusted HTML. Either render as text/Markdown through a strict renderer, or sanitize with an allowlist that permits only `h3`, `p`, `ul`, `li`, `strong` and strips all attributes, event handlers, URLs, scripts, styles, SVG, and iframes.

### Medium: Generated QCM preview renders AI JSON fields as HTML

Affected file:

- `index.html:9205`

Evidence:

Generated QCM fields `q.q` and `q.opts` are inserted into template HTML without `escapeHtml`.

Impact:

Lower than the summary issue because the prompt source is mostly fixed, but the response still comes from an external model and should not be trusted as HTML.

Recommendation:

Escape all generated question/option/explanation text before placing it in `innerHTML`, and validate the parsed JSON schema.

### Medium: Missing security headers and CSP

Affected files:

- `netlify.toml`
- no `_headers` file found

Evidence:

No `Content-Security-Policy`, `X-Frame-Options` / `frame-ancestors`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`, or HSTS config was found.

Impact:

The site has weaker browser-side containment. A CSP would materially reduce the impact of the AI-rendering XSS risk and third-party script compromise.

Recommendation:

Add Netlify security headers. Start with a report-only CSP if needed, then enforce. Include `frame-ancestors 'none'`, `X-Content-Type-Options: nosniff`, strict referrer policy, and a constrained script policy compatible with Supabase/CDNs or self-hosted scripts.

### Medium: Third-party scripts loaded without SRI or local pinning

Affected file:

- `index.html:3035`
- `index.html:6029`

Evidence:

The app loads Supabase from jsDelivr and Mammoth dynamically from cdnjs without `integrity` attributes. Mammoth is loaded by creating a script element.

Impact:

If a CDN asset or resolution path is compromised, malicious script runs in the app origin.

Recommendation:

Self-host these scripts or pin exact versions with SRI and `crossorigin="anonymous"`. A strict CSP should also limit allowed script sources.

### Low/Informational: Client-side admin bypass is limited to local mode

Affected file:

- `index.html:9804`

Evidence:

`devAdminBypassLogin` only activates for `file:`, `localhost`, or `127.0.0.1`. It writes a local admin user into localStorage, and current admin-only behavior appears limited to local feature unlocking.

Impact:

Not a public auth bypass from the code reviewed. Still, keep this visibly dev-only and ensure no future server-side privileged action trusts `role: 'admin'` from localStorage.

## Supabase/RLS Review

Reviewed `supabase-schema.sql`.

Positive:

- `profiles` and `user_data` have RLS enabled.
- `profiles` and `user_data` policies constrain select/insert/update to `auth.uid() = user_id`.
- `leaderboard` public read appears intentional.
- `legacy_netlify_data` select is constrained by authenticated JWT email.
- No service role key was found in `index.html`.

Caveat:

This was static review only. The remote database policies were not changed or tested live.

## Recommended Fix Order

1. Stop publishing root files and remove `supabase-legacy-import.sql` from public deploy scope.
2. Add auth/rate limiting to `functions/mathobac-ai.js`.
3. Sanitize or avoid `innerHTML` for AI summary output.
4. Escape generated QCM model fields before rendering.
5. Add Netlify security headers / CSP.
6. Self-host or SRI-pin third-party scripts.

## Verification Commands Run

- `rg --files`
- `Get-ChildItem -Force`
- targeted `Select-String` scans for Supabase, secrets, dangerous sinks, and headers
- review of `functions/mathobac-ai.js`
- review of `netlify.toml`
- review of `supabase-schema.sql`
- targeted review of AI import/rendering and auth/cloud persistence code in `index.html`
