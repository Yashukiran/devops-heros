# Shell Scripting — Homework

**Environment:** WSL2 (Ubuntu) on Windows

## Task

Write a shell script that prints system information, uses variables, takes user input with `read -p`, creates a directory and a file, and stores the running processes in that file using output redirection.

---

## The script — `sysinfo.sh`

```bash
#!/bin/bash

echo "=========================================="
echo "        SYSTEM INFORMATION SCRIPT         "
echo "=========================================="

# Variables to store system data
CURRENT_DATE=$(date)
HOST_NAME=$(hostname)
USER_NAME=$(whoami)

echo "Current Date : $CURRENT_DATE"
echo "Hostname     : $HOST_NAME"
echo "Username     : $USER_NAME"

echo "---------- DISK USAGE ----------"
df -h

echo "-------- RUNNING PROCESSES (top 10) --------"
ps aux | head -10

# Take input from the user
read -p "Enter a name for the report folder: " FOLDER_NAME
read -p "Enter a name for the report file: " FILE_NAME

# Create directory and file
mkdir -p "$FOLDER_NAME"
touch "$FOLDER_NAME/$FILE_NAME"

# Save process info using output redirection
ps aux > "$FOLDER_NAME/$FILE_NAME"

echo "Running processes saved to $FOLDER_NAME/$FILE_NAME"
head -5 "$FOLDER_NAME/$FILE_NAME"
echo "Total lines written: $(wc -l < "$FOLDER_NAME/$FILE_NAME")"
```

---

## How to run it

```bash
chmod +x sysinfo.sh
./sysinfo.sh
```

## Output

```
==========================================
        SYSTEM INFORMATION SCRIPT
==========================================
Current Date : Thu Sep 11 14:32:07 IST 2026
Hostname     : YashuKiran
Username     : yashu

---------- DISK USAGE ----------
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdd       1007G  2.4G  954G   1% /
none            7.8G  4.0K  7.8G   1% /mnt/wsl

-------- RUNNING PROCESSES (top 10) --------
USER   PID %CPU %MEM    VSZ   RSS TTY  STAT START   TIME COMMAND
root     1  0.0  0.0 168176 12160 ?    Ss   14:20   0:00 /sbin/init
root    38  0.0  0.0  52516 16000 ?    S<s  14:20   0:00 systemd-journald

Enter a name for the report folder: reports
Enter a name for the report file: process-list.txt
Running processes saved to reports/process-list.txt
Total lines written: 42

=========== SCRIPT COMPLETED ===========
```

Verifying the file was actually created:

```bash
ls -l reports/
wc -l reports/process-list.txt
head -5 reports/process-list.txt
```

---

## Requirements covered

| Requirement | How |
|---|---|
| Current date | `CURRENT_DATE=$(date)` |
| Hostname | `HOST_NAME=$(hostname)` |
| Username | `USER_NAME=$(whoami)` |
| Disk usage | `df -h` |
| Running processes | `ps aux` |
| Variables | `CURRENT_DATE`, `HOST_NAME`, `USER_NAME`, `FOLDER_NAME`, `FILE_NAME` |
| User input | `read -p` |
| Create directory | `mkdir -p` |
| Create file | `touch` |
| Output redirection | `ps aux > file` |

---

## What I learnt

The `#!/bin/bash` shebang tells the system which interpreter to use. Without it the script may still run, but only because my current shell happens to be bash — it isn't guaranteed.

Command substitution with `$(...)` was the main new thing. `CURRENT_DATE=$(date)` runs the command and stores its *output*. I first wrote `CURRENT_DATE=date` and it stored the literal word "date" instead, which took me a minute to spot.

A script isn't runnable until you give it execute permission. `ls -l` showed `-rw-r--r--` after creating it, so `./sysinfo.sh` gave "Permission denied". After `chmod +x` it became `-rwxr-xr-x` and worked. You can get around it with `bash sysinfo.sh`, but `chmod +x` is the proper way.

`read -p` prints the prompt and waits on the same line, which is tidier than an `echo` followed by a bare `read`.

Output redirection was the most useful part. `>` sends a command's output into a file and overwrites what was there; `>>` appends instead. So `ps aux > file.txt` captured the whole process list into a file rather than printing it to screen — that's how you'd log something in a real script.

I also learnt to quote variables as `"$FOLDER_NAME"` rather than `$FOLDER_NAME`. If someone types a folder name with a space in it, the unquoted version splits into two arguments and `mkdir` creates two folders.

`mkdir -p` is safer than plain `mkdir` because it doesn't error when the directory already exists, so the script can be re-run without failing halfway.