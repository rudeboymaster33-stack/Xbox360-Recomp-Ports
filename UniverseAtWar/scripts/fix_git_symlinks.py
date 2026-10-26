"""Replace git symlinks that Windows checked out as small text files with real copies.

Git on Windows (without Developer Mode / core.symlinks) writes a symlink as a plain
file whose content is the link target path, e.g. libmspack/cabextract/mspack/lzxd.c
contains "../../libmspack/mspack/lzxd.c". The compiler then fails on that file.
Usage: python fix_git_symlinks.py <repo folder>   (also walks every submodule)
Safe to re-run: a file is only replaced while its content is still the link path."""
import os, shutil, subprocess, sys


def repos(root):
    for d, dirs, files in os.walk(root):
        if '.git' in dirs or '.git' in files:
            yield d
        if '.git' in dirs:
            dirs.remove('.git')


def fix_repo(repo):
    out = subprocess.run(['git', '-C', repo, 'ls-files', '-s'], capture_output=True,
                         text=True, encoding='utf-8', errors='replace').stdout
    fixed = 0
    for line in out.splitlines():
        meta, _, path = line.partition('\t')
        if not meta.startswith('120000'):
            continue
        link = os.path.join(repo, path)
        if not os.path.isfile(link) or os.path.islink(link) or os.path.getsize(link) > 1024:
            continue
        with open(link, 'r', encoding='utf-8', errors='replace') as f:
            target_rel = f.read().strip()
        target = os.path.normpath(os.path.join(os.path.dirname(link), target_rel))
        if not os.path.exists(target):
            print('  target missing:', path, '->', target_rel)
            continue
        os.remove(link)
        if os.path.isdir(target):
            shutil.copytree(target, link)
        else:
            shutil.copy2(target, link)
        fixed += 1
    if fixed:
        print('  %s: replaced %d symlink file(s)' % (repo, fixed))
    return fixed


def main():
    root = os.path.abspath(sys.argv[1])
    total = 0
    # Links can point at other links: repeat until nothing changes.
    for _ in range(5):
        n = sum(fix_repo(r) for r in repos(root))
        total += n
        if n == 0:
            break
    print('symlink fix: %d file(s) replaced' % total)


if __name__ == '__main__':
    main()
