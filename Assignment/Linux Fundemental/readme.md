# Linux Fundamentals — Homework

**Environment:** WSL2 (Ubuntu) on Windows

---

## Task 1 — Soft Link and Hard Link

```bash
ln original.txt hardlink.txt      # hard link
ln -s original.txt softlink.txt   # soft link
ls -li                            # shows inode numbers
rm original.txt                   # the test
```

**What I learnt:**

Every file has a name and an inode, and they're separate things. The name is just a label; the inode is where the data actually lives.

A hard link is a second name pointing at the same inode — `ls -li` showed both files with the **same inode number** and the link count going from 1 to 2. A soft link is its own small file that just stores a path as text, so it has a different inode and shows up as `softlink.txt -> original.txt`.

Deleting the original is what makes the difference obvious. The hard link still printed the full content, while the soft link gave `No such file or directory` and turned red in the terminal. So `rm` doesn't really delete a file — it removes one name and drops the link count. The data only goes when the last name is gone.

When I recreated a file with the original name, the soft link started working again on its own. That confirmed it only ever tracked the *name*, never the data.

Also: hard links can't point at directories (`hard link not allowed for directory`) or cross filesystems, but soft links can do both.

---

## Task 2 — adduser vs useradd

```bash
sudo useradd testuser1     # low-level
sudo adduser testuser2     # recommended on Ubuntu
sudo passwd -S <user>      # L = locked, P = password set
```

**What I learnt:**

I thought these were the same command with two names. They're not — `useradd` is the actual binary, and `adduser` on Ubuntu is a Perl script that calls `useradd` underneath and handles the setup for you.

`useradd` ran completely silently, which made me think it had failed. It worked, but it left the account half-built: no `/home/testuser1` directory, shell set to `/bin/sh`, and the password Locked. Trying to log in gave a "cannot change directory" warning.

`adduser` was interactive — it asked for a password and user details, and its output showed it creating the home directory and copying files from `/etc/skel`. The result had a proper `/home` directory, `/bin/bash` as the shell, and a working password. Logging in worked with no warnings.

`/etc/skel` was new to me — it's a template folder whose contents (`.bashrc`, `.profile`) get copied into every new user's home. That's why one account had a working shell config and the other didn't.

**Which is preferred:** `adduser` on Ubuntu, for anything interactive. But `useradd` exists on every distro (RHEL/CentOS don't have `adduser`) and never prompts, so it's the right one inside scripts where a prompt would hang everything. For DevOps I'll probably use `useradd -m -s /bin/bash` more often.

---

## Task 3 — journalctl

```bash
journalctl -n 20              # last 20 entries
journalctl -u ssh             # logs for one service
journalctl -b                 # current boot only
journalctl -p err             # errors and worse
journalctl --since "5 minutes ago"
journalctl -f                 # follow live
```

**What I learnt:**

I only knew about `cat` and `tail` on files in `/var/log/`. `journalctl` is a different model — systemd keeps one binary, indexed journal holding everything (kernel, services, applications), and you query it instead of hunting through separate files.

Because it's structured rather than plain text, filtering actually works properly. `-u ssh` was the most useful one: I restarted ssh deliberately and could see my own `Stopping` and `Started` entries appear with fresh timestamps. If a service won't start, `systemctl status` gives you a few lines but `journalctl -u <service>` gives the whole story.

`--since` accepts plain English like `"5 minutes ago"` or `yesterday`, which I didn't expect. Priority levels run `emerg → alert → crit → err → warning → notice → info → debug`, and asking for one includes everything more severe.

**WSL gotcha:** journalctl won't work at all until systemd is enabled. `ps -p 1 -o comm=` has to print `systemd`, not `init`. If it says `init`, add `[boot]` / `systemd=true` to `/etc/wsl.conf` and run `wsl --shutdown` from PowerShell — not from inside WSL, since it can't shut itself down.

I also used `--no-pager` on everything so output printed straight out instead of opening in `less`.

---

## Task 4 — Command Cheat Sheet

```bash
ls -ltr                       # sort by time, newest last
chmod 755 file                # rwx r-x r-x
cut -d: -f1 /etc/passwd       # field 1, split on ':'
awk -F: '{print $1}' /etc/passwd
sed 's/old/new/' file
df -h / du -sh                # disk free / directory size
sleep 60 & ; jobs ; kill %1   # background job control
tar -czf x.tar.gz dir/        # create
tar -tzf x.tar.gz             # list
ping -c 3 google.com
```

**What I learnt:**

`ls -ltr` was new and genuinely useful — sorts by time with the newest at the bottom, so in a busy directory you immediately see what changed last.

`chmod` finally made sense once I ran `ls -l` before and after and watched `-rw-r--r--` become `-rwxr-xr-x`. The three digits are owner/group/others, where read = 4, write = 2, execute = 1. So 755 is 4+2+1 for the owner and 4+1 for everyone else.

`cut`, `awk` and `sed` overlap but aren't the same. `cut` grabs a field, `awk` does the same but can do far more, `sed` substitutes text. Running all three against `/etc/passwd` side by side is what made the difference clear.

`df` vs `du` confused me at first — `df` is about the filesystem and how full the disk is, `du` is about a specific directory's size.

`tar` flags stopped being random once I read them as words: **c**reate, lis**t**, e**x**tract, plus `z` for gzip and `f` for "filename follows". So `-czf` is create-gzip-file.

Small things: `mv` handles both moving and renaming (there's no separate rename command), and `ping` needs `-c 3` on Linux or it runs forever, unlike Windows where it stops on its own.

---

## Overall

The links task changed how I picture files — the name and the data are separate, and `rm` just removes a name.

The users task showed that two commands doing "the same job" can behave very differently, and the convenient one isn't always the right one for scripts.

`journalctl` felt the most directly useful for real DevOps work — being able to ask "what did this one service log in the last ten minutes" in one command beats searching through log files.

The only real problem I hit was WSL-specific: systemd being off by default, which breaks journalctl entirely until you fix it.