# Required Methodology and Execution Phases

## Required methodology
1. First, map the repository structure and identify:
   - mobile app folders
   - web app folders
   - backend folders
   - config / infra / deployment files
   - package managers and lockfiles
2. Then produce a threat-oriented review of each component.
3. Then perform cross-component security analysis:
   - how frontend/mobile interact with backend
   - token lifecycle
   - session persistence
   - trust boundaries
   - API exposure
4. Then produce a consolidated risk register.
5. Then produce remediation steps in priority order.

---

Act as an enterprise application security reviewer performing a deep defensive audit on this entire repository.

This workspace contains a combined product stack that may include:
- Flutter / Dart mobile app
- React web app
- Node.js / JavaScript backend
- Shared infrastructure/configuration files

Your task is to perform a full, structured, evidence-based security review of the whole codebase.

Rules:
- Authorized defensive review only
- No offensive exploitation instructions
- No harmful payload generation
- Focus on risk identification, impact explanation, and remediation
- Be exhaustive and trace code paths across files
- Mark uncertain items as “Needs Verification”

## PHASE 1 — Repository discovery
- Identify all apps/services/modules
- Identify entry points
- Identify auth/session code
- Identify API routes and middleware
- Identify booking/reservation/business-critical flows
- Identify config/env/CI/deployment files
- Identify dependency manifests and lockfiles

## PHASE 2 — Attack surface mapping
- Map external inputs
- Map sensitive operations
- Map trust boundaries
- Map token/session lifecycle
- Map storage locations for secrets/tokens/PII
- Map file upload, search, filtering, admin, payment, booking, cancel, update flows if present

## PHASE 3 — Deep security review
Review for:
- Authentication flaws
- Authorization flaws / IDOR / privilege escalation
- Input validation gaps
- XSS / CSRF / SSRF / injection risks
- Unsafe file upload / path traversal patterns
- Hardcoded secrets
- Insecure crypto
- Weak token handling
- Logging/privacy leaks
- Dependency risks
- Dev/prod misconfiguration
- Mobile-specific security weaknesses
- Web-specific rendering/storage weaknesses
- Backend-specific middleware and API weaknesses
- Booking/business-logic abuse risks
- Warning signs and insecure code smells

## PHASE 4 — Cross-component correlation
- Check whether frontend/mobile rely on protections not enforced by backend
- Check whether client-provided fields can affect prices, roles, booking state, or ownership
- Check whether route guards exist only in UI
- Check for inconsistent validation across clients and server
- Check whether cancellation/refund/booking changes are ownership-protected server-side

## PHASE 5 — Reporting
Output:
1. Executive summary
2. Repository map
3. Findings by severity
4. Findings by functional area
5. Quick wins
6. Strategic hardening recommendations
7. Prioritized remediation roadmap

Start now with PHASE 1 and continue through all phases. If your analysis is too generic, go deeper. Re-open related files, trace imports, trace middleware usage, trace route protection coverage, and verify whether security assumptions are actually enforced server-side. Keep digging until you have repository-specific findings.
