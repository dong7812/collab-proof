# /session-proof

Generate AI collaboration evidence for the current session, then export a shareable HTML proof.

## Steps (run in order)

1. Run `git log --oneline -10` and `git diff --stat HEAD~3..HEAD` via bash
2. Compute signal level using the rubric in the collab-proof skill
3. Show the signal level and Layer 02 frame findings to the user
4. Write the markdown artifacts (DECISIONS.md, session-history/, WORKLOG.md)
5. **Run the HTML renderer** — execute this bash command:
   ```
   python3 ~/.claude/skills/collab-proof/render.py
   ```
   If that fails (render.py not found), try: `python3 render.py`
6. Report all files written and show the `open <path>` command for the HTML

The user should see the full pipeline running: signal score → frames → artifacts → HTML path.
