# Project Governance

PermissionPilot is governed by a simple, transparent model designed to empower contributors while maintaining quality and security.

## 🎯 Vision

Intelligent, private, transparent permission automation tools that users control—not corporations, not surveillance.

## 👥 Roles

### Maintainer
- **Chaitanya Joshi** (@ChaitanyaJoshi1769)
  - Stewards the project vision
  - Reviews and merges pull requests
  - Makes final decisions on disputes
  - Maintains security posture
  - Manages releases and roadmap prioritization

### Contributors
Anyone who submits issues, pull requests, or helps with documentation.

### Sponsors
Organizations or individuals who support the project financially.

---

## 📋 Decision Making

### Small Decisions (Bug fixes, docs, minor features)
- Maintainer reviews PR
- If code quality is good and doesn't break existing functionality: **merge**
- Contributor is thanked and credited

### Medium Decisions (New features, significant changes)
- **GitHub Discussion** is opened for public input (48 hours)
- Contributors can voice opinions
- Maintainer weighs feedback
- Decision is documented

### Large Decisions (Architecture changes, major roadmap shifts)
- **RFC (Request for Comments)** posted in GitHub Discussions
- 1 week public comment period
- Community input is weighted
- Final decision made by maintainer, documented with reasoning

### Dispute Resolution
If contributors disagree with a maintainer decision:
1. Re-discuss in GitHub Discussions
2. Maintainer provides written explanation of reasoning
3. Disagreement is documented but decision stands
4. Contributors can fork if fundamentally opposed

---

## 🔄 Contribution Process

### Issue Triage
- Issues are labeled by type (bug, feature, docs, etc.)
- Severity is assigned (critical, high, medium, low)
- "Good first issue" labels help new contributors find starting points

### Pull Request Review
1. **Automated checks**: CI/CD pipeline (build, test, lint)
2. **Code review**: Maintainer reviews for:
   - Correctness and test coverage
   - Security implications
   - Design alignment
   - Documentation
3. **Feedback loop**: Author addresses comments
4. **Approval**: Merged when ready

### Commit Standards
- Clear, imperative commit messages
- Reference issues when applicable
- Follows template in `.gitmessage`

### Release Process
1. Changes merge to main branch
2. Maintainer tags version (semantic versioning)
3. CI/CD automates:
   - Build & code signing
   - Notarization
   - Homebrew formula update
   - Release notes generation
4. Users notified of new release

---

## 📊 Roadmap

### Phases
- **Phase 1** (v1.0.0): ✅ Released — Core functionality
- **Phase 2** (v1.1-1.5): Q2 2024 — Browser extension, advanced policies
- **Phase 3** (v2.0): Q3 2024 — ML classifier, iOS companion
- **Phase 4** (v3.0+): Q4 2024+ — Enterprise features

### Prioritization
1. **Security & stability** (always highest priority)
2. **Community feedback** (feature requests, bug reports)
3. **Sponsor interests** (within reason, no exclusive features)
4. **Maintainer vision** (long-term direction)

### Community Input
- Sponsors can request feature consultations
- Community can vote on features via GitHub reactions (👍)
- Frequently-requested features get prioritized

---

## 🔒 Security & Safety

### Code Review Standards
- All code reviewed before merge
- Security implications assessed
- No hardcoded secrets or keys
- Dependency vulnerabilities checked

### No Privilege Escalation
- Will never add features that require root
- Will never bypass SIP or TCC
- Will never modify system security

### Responsible Disclosure
- Security researchers can report privately
- 90-day embargo before public disclosure
- Patches released ASAP (target: 7 days for critical)

See [SECURITY.md](SECURITY.md) for full policy.

---

## 📈 Success Metrics

We measure success by:

| Metric | Target |
|--------|--------|
| Test coverage | >80% of critical paths |
| Build success | 100% of main branch |
| Security audits | Annual minimum |
| Community issues response | <48 hours |
| Release cadence | 1–2 per month |
| Contributor growth | Month-over-month |

---

## 💬 Communication

### Communication Channels
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Q&A, ideas, announcements
- **GitHub Pull Requests**: Code review and collaboration
- **Email**: dev@permissionpilot.app for sensitive topics
- **Security**: security@permissionpilot.app for vulnerabilities

### Response Expectations
- Issues/PRs: Reviewed within 48 hours
- Discussions: Responded within 3 days
- Critical security reports: 24 hours
- General emails: 1 week

---

## 🤝 Contributor Recognition

We recognize contributions in multiple ways:

- **Git commit credits** (co-authored commits)
- **CONTRIBUTORS.md** file (maintained)
- **GitHub contributor graph** (automatic)
- **Release notes** (thank you section)
- **Sponsor page** (if sponsors)

---

## ⚖️ Code of Conduct

All participants agree to our [Code of Conduct](CODE_OF_CONDUCT.md):
- Be respectful
- Assume good intent
- Focus on ideas, not people
- Report violations to dev@permissionpilot.app

Violations are taken seriously and may result in temporary or permanent removal.

---

## 🔄 Governance Evolution

This governance model isn't permanent. As the project grows:
- We may establish a formal board
- We may distribute maintainer responsibilities
- We may adopt a steering committee
- Community input will guide any changes

For now, this simple model works. If it stops working, we'll evolve.

---

## FAQ

**Q: Can anyone become a maintainer?**  
A: If the community grows significantly, we may distribute responsibilities. But for now, the maintainer model works well.

**Q: What if the maintainer disappears?**  
A: The project is open source. The community can fork and continue. GitHub will also help with succession if needed.

**Q: How do you avoid burnout?**  
A: By setting clear boundaries (48-hour response times, not always-on). Sponsors help fund time. Community helps lighten the load.

**Q: Can I fork this?**  
A: Absolutely! The MIT license allows it. Just credit the original work.

---

## See Also

- [Contributing Guidelines](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Sponsorship Info](SPONSORSHIP.md)
- [Security Policy](SECURITY.md)

---

**Questions about governance?** [Start a discussion](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions/new/choose)
