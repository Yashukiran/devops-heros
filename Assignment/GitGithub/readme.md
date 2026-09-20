# Git / GitHub — Homework

**Environment:** WSL2 (Ubuntu) on Windows

---

## Task 1 — `git commit -a -m` vs `git commit -m`

```bash
git commit -m "message"       # commits only what is staged
git commit -a -m "message"    # stages all TRACKED changes, then commits
```

### What I tested

I modified a tracked file and ran `git commit -m` without `git add` first. It refused:

```
no changes added to commit (use "git add" and/or "git commit -a")
```

Then `git commit -a -m` on the same change worked straight away.

Then I created a brand new file and tried `git commit -a -m` again — the new file was not included, and `git status` still showed it as untracked afterwards. I had to `git add` it first.

### What I understood

Git has three places a change can sit: the working directory, the staging area (index), and the repository. `git add` moves a change from working directory to staging, `git commit` moves it from staging to the repository.

`git commit -m` only commits what is already staged. That's what makes partial commits possible — if I've edited five files but only want two in this commit, I stage those two and commit.

`git commit -a -m` is a shortcut that stages everything **already tracked** and commits in one step. The key limitation is that word "tracked". A file git has never seen is invisible to `-a`, so new files always need `git add` first.

So `-a` saves time on quick edits to existing files, but it's a blunt instrument — it sweeps up every modified tracked file, including ones I may not have wanted in that commit. For anything I care about being clean I'd stage deliberately.

---

## Task 2 — Cherry-pick

```bash
git log --oneline            # find the commit hash
git checkout main
git cherry-pick <hash>
```

### What I did

Made 3 commits on `main`, then created a `feature` branch and made 3 more commits there, each adding a different file. Used `git log --oneline` to find the hash of the middle commit ("Feature commit B").

Switched back to `main` — none of the feature files were there. Ran `git cherry-pick` with that one hash, and afterwards `featureB.txt` existed on main while `featureA.txt` and `featureC.txt` did not.

### What I understood

Cherry-pick takes the *changes introduced by one specific commit* and replays them onto the current branch. It isn't a merge — I'm not bringing the branch across, just one commit's worth of work.

The commit that lands on main is a **new commit with a new hash**, even though the content is identical. That makes sense once you know a hash is derived from the content plus the parent and metadata — different parent, different hash. So the same change now exists twice in the repo's history, in two separate commits.

The obvious real use is a hotfix. If a bug fix is sitting in a feature branch that isn't ready to merge, cherry-pick lets you pull just that fix into main without dragging half-finished work with it.

It can also hit conflicts, if the commit touches code that has changed on the target branch since. You resolve them the same way as a merge conflict, then `git cherry-pick --continue`.

The thing I'd watch out for is the duplicate history — if the branch gets merged normally later, that change is in there twice. Fine for a one-off fix, messy if you do it often.

---

## Commands used

| Command | Purpose |
|---|---|
| `git init` | Start a repository |
| `git add <file>` | Stage a change |
| `git commit -m` | Commit what's staged |
| `git commit -a -m` | Stage all tracked changes and commit |
| `git status` | See what's staged, modified, untracked |
| `git log --oneline` | Compact history with hashes |
| `git checkout -b <name>` | Create and switch to a branch |
| `git checkout <name>` | Switch branch |
| `git cherry-pick <hash>` | Apply one commit to the current branch |