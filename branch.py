from subprocess import call

files = []

with open("diff.txt") as f:
    files = f.readlines()

for file in files:
    file = file.strip()
    call(f"git checkout BNAME -- {file}")