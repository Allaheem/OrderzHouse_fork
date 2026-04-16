# Reporting Format and Severity Model

## Severity model
Classify every finding as one of:
- Critical
- High
- Medium
- Low
- Informational
- Needs Verification

For every finding, provide:
1. Title
2. Severity
3. Component (Flutter / React / Backend / Config / Cross-cutting)
4. File path(s)
5. Evidence (quote or summarize the exact risky code behavior)
6. Why it matters
7. Realistic impact
8. Safe remediation guidance
9. Confidence level (High / Medium / Low)

## Required output structure

# 1. Executive Summary
- Overall security posture
- Top 5 most important risks
- What appears strong
- What appears weak

# 2. Repository Security Map
- Detected project areas
- Tech stack found
- Sensitive files/configs discovered
- Trust boundaries identified

# 3. Findings by Severity
## Critical
## High
## Medium
## Low
## Informational
## Needs Verification

# 4. Findings by Area
## Flutter / Mobile
## React / Web
## Backend / API
## Auth / Session / Access Control
## Dependencies / Supply Chain
## Configuration / DevOps
## Privacy / Sensitive Data
## Booking / Reservation / Business Logic

# 5. Quick Wins
- Fixes that can be done immediately with high value

# 6. Strategic Improvements
- Medium/long-term security hardening

# 7. Secure Refactor Suggestions
- Concrete code-level refactor ideas
- Mention exact files/functions where possible

# 8. Final Prioritized Remediation Plan
- Priority 0
- Priority 1
- Priority 2
- Priority 3

## Additional behavior requirements
- Search recursively and do not stop at the first issue.
- Correlate issues across files.
- If you find auth middleware, trace where it is and is not applied.
- If you find booking/reservation flows, trace the full lifecycle from client input to backend enforcement.
- If you find secrets, clearly distinguish real secret exposure vs placeholder/demo values.
- If a pattern is secure, briefly mention it as a positive finding.
- Be concise in summaries but detailed in findings.
- When possible, recommend the safest modern best practice for Flutter, React, and Node.js ecosystems.
- Prefer backend-enforced security over frontend-only assumptions.
- Call out anything that would fail a serious enterprise security review.
