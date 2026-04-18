# Pullminder GitHub Action

> Automated PR risk scoring and policy enforcement as a GitHub Action.

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-Pullminder-blue)](https://github.com/marketplace/actions/pullminder)
[![License](https://img.shields.io/github/license/pullminder/action)](LICENSE)

## Quick start

```yaml
# .github/workflows/pullminder.yml
name: Pullminder
on: pull_request

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: pullminder/action@v1
```

## Authentication

The Pullminder API uses session-based authentication via GitHub OAuth. This is a cookie-based system designed for browser clients (the dashboard). The API does not issue API tokens for direct use.

## GitHub OAuth flow

The authentication flow works as follows:

1. **Initiate login** -- Direct the user to `GET /auth/github`. Pullminder redirects to GitHub's OAuth authorization page.
2. **GitHub callback** -- After the user authorizes, GitHub redirects back to `GET /auth/github/callback` with an authorization code. Pullminder exchanges the code for an access token and creates a session.
3. **Session cookie** -- Pullminder sets an HTTP-only session cookie on the response. All subsequent API requests must include this cookie.

No manual token handling is required when using the dashboard. The browser stores and sends the session cookie automatically.

## Checking the current session

To verify that a session is active and retrieve the authenticated user:

```
GET /auth/me
```

Returns the current user's profile (GitHub username, avatar, email) and the organizations they belong to. If the session is invalid or expired, the response is `401 Unauthorized`.

## Logging out

To end the current session:

```
POST /auth/logout
```

This invalidates the session cookie. The user must re-authenticate via the GitHub OAuth flow to access the API again.

## Authentication for the CLI

The Pullminder CLI does not use session-based auth. For platform commands that require authentication (such as syncing results with the dashboard), the CLI uses a `GITHUB_TOKEN` environment variable. See the [CLI installation guide](/cli/installation/) for details.

## Key points

- The API is session-based, not token-based. There are no API keys or bearer tokens.
- Session cookies are HTTP-only and secure. They cannot be read by client-side JavaScript.
- All API endpoints except `/auth/github`, `/auth/github/callback`, `/health`, `/badge/{token}`, and `/webhooks/github` require an active session.
- Sessions are scoped to the authenticated GitHub user. Organization access is determined by the user's GitHub organization memberships.

## Next steps

- [API endpoints](/api/endpoints/) -- complete reference for all REST endpoints
- [Webhooks](/api/webhooks/) -- GitHub webhook integration details

## API Endpoints

This is a reference for the Pullminder REST API. The base URL is `https://api.pullminder.com`. All organization-scoped routes use the path prefix `/api/orgs/{orgId}`.

:::note
This is a dashboard API, not a public API. Authentication is session-based via GitHub OAuth cookies. See the [Authentication](/api/authentication/) guide for details.
:::

## Auth

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/auth/github` | Initiate GitHub OAuth login flow |
| `GET` | `/auth/github/callback` | Handle GitHub OAuth callback |
| `POST` | `/auth/logout` | End the current session |
| `GET` | `/auth/me` | Get the authenticated user profile |

## Organizations

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/orgs` | List organizations the user belongs to |
| `GET` | `/api/orgs/{orgId}/` | Get organization details |
| `PATCH` | `/api/orgs/{orgId}/onboarding` | Update onboarding state |
| `DELETE` | `/api/orgs/{orgId}/` | Delete the organization |

## Repositories

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/orgs/{orgId}/repos` | List repositories in the organization |
| `PATCH` | `/api/orgs/{orgId}/repos/{repoId}` | Update repository settings (e.g., toggle active) |
| `POST` | `/api/orgs/{orgId}/repos/sync` | Sync repository list from GitHub |
| `POST` | `/api/orgs/{orgId}/repos/bulk-activate` | Activate multiple repositories at once |
| `GET` | `/api/orgs/{orgId}/repos/{repoId}/badge` | Get the badge configuration for a repository |
| `POST` | `/api/orgs/{orgId}/repos/{repoId}/badge` | Create a badge for a repository |
| `DELETE` | `/api/orgs/{orgId}/repos/{repoId}/badge` | Delete a repository badge |
| `GET` | `/api/orgs/{orgId}/repos/{repoId}/detected-frameworks` | List detected frameworks for a repository |
| `POST` | `/api/orgs/{orgId}/repos/{repoId}/rule-packs/{packId}/enable` | Enable an auto-detected rule pack |
| `DELETE` | `/api/orgs/{orgId}/repos/{repoId}/rule-packs/{packId}/enable` | Disable an auto-detected rule pack |

## Pull requests

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/orgs/{orgId}/prs` | List analyzed pull requests (supports filters) |
| `GET` | `/api/orgs/{orgId}/prs/{prId}` | Get pull request detail and risk breakdown |
| `GET` | `/api/orgs/{orgId}/prs/{prId}/reviews` | Get review analysis for a pull request |
| `GET` | `/api/orgs/{orgId}/prs/{prId}/coverage` | Get coverage data for a pull request |
| `GET` | `/api/orgs/{orgId}/prs/{prId}/reviewer-prompt` | Get the AI reviewer brief for a pull request |

## Rules

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/orgs/{orgId}/rules` | List installed rule packs |
| `POST` | `/api/orgs/{orgId}/rules/{slug}/install` | Install a rule pack from the registry |
| `DELETE` | `/api/orgs/{orgId}/rules/{slug}` | Uninstall a rule pack |
| `PATCH` | `/api/orgs/{orgId}/rules/{slug}` | Update rule pack settings (action, enabled state) |
| `POST` | `/api/orgs/{orgId}/rules/{slug}/upgrade` | Upgrade a rule pack to the latest version |
| `GET` | `/api/orgs/{orgId}/rules/{slug}/detail` | Get full detail for an installed rule pack |
| `GET` | `/api/orgs/{orgId}/rules/{slug}/overrides` | List per-repository overrides for a rule pack |
| `PUT` | `/api/orgs/{orgId}/rules/{slug}/overrides/{repoId}` | Set a per-repository override for a rule pack |

## Policies

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/orgs/{orgId}/policies` | List policies |
| `POST` | `/api/orgs/{orgId}/policies` | Create a policy |
| `PATCH` | `/api/orgs/{orgId}/policies/{policyId}` | Update a policy |
| `DELETE` | `/api/orgs/{orgId}/policies/{policyId}` | Delete a policy |

## Analytics

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/orgs/{orgId}/analytics/summary` | Aggregated analytics summary |
| `GET` | `/api/orgs/{orgId}/analytics/risk-trend` | Risk score trend over time |
| `GET` | `/api/orgs/{orgId}/analytics/top-categories` | Most common finding categories |
| `GET` | `/api/orgs/{orgId}/analytics/repo-breakdown/search` | Per-repository risk and finding breakdown |
| `GET` | `/api/orgs/{orgId}/analytics/review-time` | Review duration statistics |
| `GET` | `/api/orgs/{orgId}/analytics/patterns` | Recurring finding patterns |
| `GET` | `/api/orgs/{orgId}/analytics/reviewer-activity` | Per-reviewer activity and response times |
| `GET` | `/api/orgs/{orgId}/analytics/coverage-trend` | Code coverage trend over time |

## Reports

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/orgs/{orgId}/reports/baseline` | Get baseline analysis report |
| `GET` | `/api/orgs/{orgId}/reports/baseline/repos` | Get per-repository baseline data |

## Baseline scanning

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/orgs/{orgId}/baseline/scan` | Trigger a historical baseline scan |
| `GET` | `/api/orgs/{orgId}/baseline/status` | Check baseline scan progress |
| `GET` | `/api/orgs/{orgId}/baseline/summary` | Get baseline scan summary |

## Alerts

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/orgs/{orgId}/alerts` | List alerts (high-risk, policy blocks) |
| `POST` | `/api/orgs/{orgId}/alerts/read` | Mark alerts as read |

## Audit logs

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/orgs/{orgId}/audit` | List audit log entries for the organization |

## Settings

| Method | Path | Description |
|--------|------|-------------|
| `PATCH` | `/api/orgs/{orgId}/settings` | Update organization settings |
| `POST` | `/api/orgs/{orgId}/settings/test-webhook` | Send a test Slack webhook message |
| `PUT` | `/api/orgs/{orgId}/settings/registry` | Configure a custom rule registry |
| `DELETE` | `/api/orgs/{orgId}/settings/registry` | Remove the custom rule registry |
| `POST` | `/api/orgs/{orgId}/settings/registry/sync` | Sync rule packs from the custom registry |

## Retention

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/orgs/{orgId}/retention` | Get data retention policies |
| `PATCH` | `/api/orgs/{orgId}/retention` | Update retention policy for a resource type |

## Billing

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/orgs/{orgId}/checkout` | Create a checkout session |
| `GET` | `/api/orgs/{orgId}/subscription` | Get current subscription details |
| `POST` | `/api/orgs/{orgId}/subscription/cancel` | Cancel the subscription |
| `GET` | `/api/orgs/{orgId}/billing/history` | List payment history |
| `POST` | `/api/orgs/{orgId}/subscription/upgrade` | Upgrade to a higher plan |
| `POST` | `/api/orgs/{orgId}/subscription/downgrade` | Downgrade to a lower plan |
| `POST` | `/api/orgs/{orgId}/subscription/upgrade/preview` | Preview prorated cost of an upgrade |

## User

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/me/data-export` | Export all personal data |
| `DELETE` | `/api/me/account` | Delete the user account |

## Other

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/orgs/{orgId}/usage` | Get usage statistics |
| `GET` | `/api/orgs/{orgId}/stats` | Get organization stats (stat cards) |
| `GET` | `/api/orgs/{orgId}/search` | Search across PRs, repos, and findings |
| `GET` | `/api/orgs/{orgId}/category-meta` | Get metadata for finding categories |

## Registry (public)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/registry/rules` | List all available rule packs in the registry |

## Public endpoints

These endpoints do not require authentication:

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check |
| `GET` | `/badge/{token}` | Render a risk score badge image |
| `POST` | `/webhooks/github` | Receive GitHub webhook events |
| `GET` | `/api/checkout/confirm` | Billing checkout confirmation callback |
| `GET` | `/api/checkout/failure` | Billing checkout failure callback |
| `POST` | `/api/leads` | Submit a lead (rate limited) |
| `GET` | `/badges/score` | Score badge image |
| `GET` | `/badges/findings` | Findings badge image |
| `GET` | `/badges/policies` | Policies badge image |
| `GET` | `/badges/coverage` | Coverage badge image |

## CLI (token-authenticated)

These endpoints use `GITHUB_TOKEN` authentication instead of session cookies.

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/cli/score` | Get risk score for a PR |
| `GET` | `/api/v1/cli/brief` | Get reviewer brief for a PR |
| `GET` | `/api/v1/cli/config` | Get CLI configuration |
| `GET` | `/api/v1/cli/config/org` | Get organization-level CLI configuration |

## Next steps

- [Authentication](/api/authentication/) -- how session-based auth works
- [Webhooks](/api/webhooks/) -- GitHub webhook event handling

## Rate Limits

The Pullminder API enforces rate limits on all endpoints and returns structured JSON error responses. This page documents the limits, error format, and HTTP status codes you may encounter.

## Rate limits

Rate limiting is per-IP using fixed-window counters backed by Redis.

| Endpoint group | Limit |
|----------------|-------|
| API endpoints | 120 requests per minute per IP |
| Webhook endpoint (`/webhooks/github`) | 60 requests per minute per IP |

When a client exceeds the limit, the API returns `429 Too Many Requests` with the body `rate limit exceeded`.

If Redis is unavailable, rate limiting fails open -- requests are allowed through rather than rejected.

## Error response format

All API responses use a consistent JSON envelope.

**Success:**

```json
{
  "ok": true,
  "data": "..."
}
```

**Error:**

```json
{
  "ok": false,
  "error": "description of what went wrong"
}
```

The `error` field contains a human-readable description of the problem.

## HTTP status codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Bad request -- invalid parameters or malformed input |
| 401 | Unauthorized -- missing or invalid session cookie |
| 403 | Forbidden -- authenticated but insufficient permissions (e.g., not an org member), or missing CSRF token |
| 404 | Not found -- resource does not exist |
| 429 | Too many requests -- rate limit exceeded |
| 500 | Internal server error |
| 503 | Service unavailable -- database or Redis is down |

## CSRF protection

All mutating requests (`POST`, `PATCH`, `PUT`, `DELETE`) to authenticated endpoints require a valid `X-CSRF-Token` header. The token is provided in the session. Requests without a valid CSRF token receive `403 Forbidden`.

## Session expiry

Sessions have a 7-day maximum age and a 30-minute inactivity timeout. Once a session expires, the API returns `401 Unauthorized` and the user must re-authenticate via the [GitHub OAuth flow](/api/authentication/).

## Next steps

- [Authentication](/api/authentication/) -- session-based auth via GitHub OAuth
- [API endpoints](/api/endpoints/) -- complete reference for all REST endpoints
- [Webhooks](/api/webhooks/) -- GitHub webhook integration details

## Webhooks

Pullminder uses GitHub webhooks to receive pull request events in real time. When you install the Pullminder GitHub App, GitHub automatically configures the webhook. No manual setup is required.

## Inbound: GitHub to Pullminder

### Endpoint

```
POST /webhooks/github
```

This endpoint receives webhook payloads from GitHub. It is a public endpoint and does not require session authentication. Instead, every request is verified using the webhook signature.

### Supported events

Pullminder listens for pull request events with the following actions:

| Event action | What happens |
|-------------|-------------|
| `opened` | A new pull request is created. Pullminder fetches the diff and runs the full analysis pipeline. |
| `synchronize` | New commits are pushed to an open pull request. Pullminder re-analyzes the updated diff. |
| `reopened` | A previously closed pull request is reopened. Pullminder runs analysis again with the current diff. |

All other event types and actions are ignored.

### Analysis pipeline

When a supported event is received, Pullminder performs the following steps:

1. **Validate the signature** -- The `X-Hub-Signature-256` header is verified against the webhook secret to confirm the payload was sent by GitHub.
2. **Fetch the diff** -- Pullminder retrieves the full pull request diff from the GitHub API using the installed app credentials.
3. **Run analyzers** -- The diff is processed through all installed rule packs. Each pack evaluates the changes and produces findings.
4. **Calculate risk score** -- Findings are weighted by severity and category to produce an overall risk score from 0 to 100.
5. **Post PR comment** -- Pullminder posts a comment on the pull request with the risk score, findings summary, and reviewer brief.
6. **Set commit status** -- If any rule with the `block` action triggered, Pullminder sets a failing commit status to prevent merging. Otherwise, the status is set to passing.
7. **Generate alerts** -- If the risk score exceeds the organization's threshold or a block-action rule triggered, an alert is created in the dashboard (and sent to Slack, if configured).

### Signature verification

Every incoming webhook request must include a valid `X-Hub-Signature-256` header. Pullminder computes an HMAC-SHA256 digest of the raw request body using the webhook secret and compares it to the signature in the header. Requests with missing or invalid signatures are rejected with `401 Unauthorized`.

The webhook secret is configured automatically when the GitHub App is installed. You do not need to manage it manually.

## Outbound: Pullminder to Slack

If you have configured a Slack incoming webhook URL in your [dashboard settings](/dashboard/settings/), Pullminder sends notifications to your Slack channel when certain events occur.

### Alert format

Slack messages are sent for the following events:

| Event | When it fires |
|-------|--------------|
| **High-risk PR** | A pull request exceeds the organization's risk threshold |
| **Policy block** | A rule with the `block` action triggered, preventing merge |

Each Slack message includes:

- PR title and author
- Repository name
- Risk score
- Number of findings by severity
- Link to the PR detail page in the dashboard
- Link to the pull request on GitHub

### Testing the webhook

You can send a test message to your Slack channel from the dashboard settings page using the **Test webhook** button. This sends a sample alert payload so you can verify the channel and formatting before relying on it for real notifications.

## Next steps

- [Authentication](/api/authentication/) -- how session-based auth works
- [API endpoints](/api/endpoints/) -- complete reference for all REST endpoints
- [Dashboard settings](/dashboard/settings/) -- configure Slack and notification preferences

## Documentation

Full documentation is available at [docs.pullminder.com](https://docs.pullminder.com/api/authentication/).

## Security

To report a vulnerability, please email **security@pullminder.com**. See [SECURITY.md](https://github.com/pullminder/.github/blob/main/SECURITY.md) for the full policy.

## License

[Apache-2.0](LICENSE)

---

_This README is auto-generated from the [pullminder.com monorepo](https://github.com/upmate/pullminder.com). Last synced: 2026-04-18._
