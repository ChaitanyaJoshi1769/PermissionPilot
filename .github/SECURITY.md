# Security Policy

We take security seriously. This policy explains how to report vulnerabilities and what to expect.

## Supported Versions

| Version | Status | Security Updates |
|---------|--------|------------------|
| 1.0.0 | ✅ Current | Yes |
| < 1.0.0 | ❌ Deprecated | No |

We support the current major version with security updates. Older versions are unsupported.

---

## Reporting a Vulnerability

### Do NOT
❌ Open a public GitHub issue for security vulnerabilities  
❌ Disclose the vulnerability publicly  
❌ Share details in discussions or chat  

### Do
✅ Email us privately: **security@permissionpilot.app**  
✅ Include version affected  
✅ Provide clear reproduction steps  
✅ Allow time for a fix before disclosure  

---

## Report Template

```
Subject: [SECURITY] Vulnerability Report

Description:
[Clear explanation of the vulnerability]

Affected Versions:
[Which versions are impacted?]

Steps to Reproduce:
1. ...
2. ...
3. ...

Expected Behavior:
[What should happen]

Actual Behavior:
[What actually happens]

Impact:
[Severity and potential consequences]

Proof of Concept:
[Code/screenshot showing the issue, if applicable]
```

---

## Response Timeline

| Time | Action |
|------|--------|
| 24h | Acknowledge receipt |
| 3–7d | Confirm vulnerability assessment |
| 7–30d | Release security patch |
| 30–90d | Public disclosure (with your credit) |

For critical vulnerabilities, timelines may be faster.

---

## Vulnerability Assessment

We assess vulnerabilities by:
- **Severity**: Critical, High, Medium, Low
- **Impact**: How many users affected?
- **Exploitability**: How easy is it to exploit?
- **Complexity**: What's required to trigger the bug?

### Severity Levels

**🔴 Critical**
- Privilege escalation
- Code injection / RCE
- Authentication bypass
- Data leakage
→ Fix ASAP (target: 3–7 days)

**🟠 High**
- Significant security weakness
- Crashes or DoS potential
- Unintended information disclosure
→ Fix within 2 weeks

**🟡 Medium**
- Non-trivial security impact
- Requires specific user action
- Limited scope
→ Fix within 1 month

**🟢 Low**
- Minor security concern
- Requires unlikely conditions
- Limited impact
→ Fix in regular release cycle

---

## Disclosure Process

1. **Private Report** (You send details)
2. **Acknowledgment** (We confirm receipt)
3. **Analysis** (We verify and assess)
4. **Fix Development** (We patch the vulnerability)
5. **Testing** (Patch is verified)
6. **Release** (Public release of fixed version)
7. **Advisory** (Public disclosure with your credit)
8. **Credit** (Your name in release notes)

---

## Public Disclosure

After a fix is released:
- We publish a security advisory on GitHub
- Details are disclosed responsibly
- CVE ID is requested (for critical issues)
- Users are notified via release notes
- Reporters are credited (if they want)

---

## In Scope

We consider these security vulnerabilities:

✅ Code injection / RCE  
✅ Privilege escalation  
✅ Authentication/Authorization bypass  
✅ Information disclosure  
✅ Cryptographic weaknesses  
✅ Unsafe deserialization  
✅ Logic errors with security impact  
✅ Supply chain vulnerabilities  

---

## Out of Scope

We don't consider these security issues:

❌ Social engineering  
❌ Phishing  
❌ Physical security  
❌ DDoS  
❌ Brute force attacks  
❌ Non-exploitable bugs  
❌ "Security through obscurity"  
❌ Best practice recommendations (suggest as feature request)  

---

## Reward Program

We don't currently offer monetary bounties, but we provide:

✅ Public credit in release notes  
✅ "Security Researcher" badge (if desired)  
✅ Priority communication channel  
✅ Feature request consultation  
✅ Annual PermissionPilot swag (if productive reporter)  

Future bounties may be funded by sponsors.

---

## Security Best Practices

### For Users
1. Keep PermissionPilot updated
2. Grant only necessary permissions
3. Review policies regularly
4. Audit logs periodically
5. Report suspicious behavior

### For Developers
1. Always test for regressions
2. Consider security implications
3. Avoid unsafe patterns
4. Validate all inputs
5. Review dependencies

---

## Bug Bounty FAQ

**Q: Do you have a bug bounty program?**  
A: Not yet, but we're exploring options with sponsors.

**Q: What if I find a vulnerability but can't report privately?**  
A: Email security@permissionpilot.app. If that doesn't work, reach out via [Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions).

**Q: Can I publish my findings after a fix?**  
A: Yes, after the 90-day embargo and public disclosure.

**Q: Will you fix vulnerabilities outside supported versions?**  
A: We focus on the current version. Older versions may be unsupported.

---

## Additional Resources

- [Full Security Audit](../SECURITY.md) — Comprehensive threat model
- [Code of Conduct](../CODE_OF_CONDUCT.md) — Community standards
- [Responsible Disclosure](../SECURITY.md#responsible-disclosure-policy) — Our policy

---

## Thank You

Security researchers who responsibly disclose vulnerabilities make open source safer for everyone.

**Thank you for helping keep PermissionPilot secure.** 🙏

---

**Questions?** Email: security@permissionpilot.app
