import subprocess

try:
    print("Fetching logs for 15 seconds...")
    process = subprocess.run(
        ["modal", "app", "logs", "kapallawd-ai"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=15,
        text=True,
        encoding='utf-8',
        errors='replace'
    )
    
    print("FINISHED NORMALLY")
    print(process.stdout[-3000:])
    print("STDERR:")
    print(process.stderr[-3000:])

except subprocess.TimeoutExpired as e:
    print("TIMEOUT REACHED - PRINTING WHAT WE GOT:")
    if e.stdout:
        print(e.stdout[-3000:])
    if e.stderr:
        print(e.stderr[-3000:])
except Exception as e:
    print(f"FAILED TO RUN: {e}")
