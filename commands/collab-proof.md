# /collab-proof

Generate AI collaboration evidence for the current session, then export a shareable HTML proof.

## Steps (run in order)

1. Run `git log --oneline -10` and `git diff --stat HEAD~3..HEAD` via bash
2. Compute signal level using the rubric in the collab-proof skill
3. Show the signal level and Layer 02 frame findings to the user
4. **Collect token usage** — run the inline bash command from the collab-proof skill (Layer 03) and capture the output
5. Write the markdown artifacts (DECISIONS.md, session-history/, WORKLOG.md)
6. **Generate the HTML proof** — write `session-history/YYYY-MM-DD-HHMM-proof.html` directly as a self-contained HTML file including the token usage panel
7. Report all files written and show the `open <path>` command for the HTML

The user should see the full pipeline running: signal score → frames → token stats → artifacts → HTML path.
