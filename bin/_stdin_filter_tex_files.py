#!/usr/bin/env python3
import sys

'''
Assume that we're processing the output of inotifywait.
Specifically, lines like:
- `MODIFY test-render.synctex(busy)`
- `MODIFY test-render.pdf`
- `CLOSE_WRITE:CLOSE test-render.mw`
- `MODIFY test-render.fls`

For a list of bad file extensions, we want to avoid printing those out
so they don't get processed as change events.

So we can just check if each line's characters after `.` are in a set of bad file extensions.

### test script:

(echo 'a.a'; sleep 1; echo 'a.pdf'; echo 'b.b'; sleep 1; echo 'c.pdf'; echo 'done') | ./bin/_stdin_filter_tex_files.py

'''

BAD_FILE_EXTENSIONS = {
    'mw', 'fls', 'synctex(busy)', 'synctex', 'pdf', 'aux', 'out', 'gz', 'log', 'fdb_latexmk'
}


def main():
    ''' Take stdin and only print lines that don't end in bad file extensions. '''
    for line in sys.stdin:
        ext = line.rstrip().rsplit('.')[-1]
        if ext not in BAD_FILE_EXTENSIONS:
            # sys.stderr.write(f">>>> PRINTING {line}")
            print(line, file=sys.stdout, flush=True)
        else:
            # sys.stderr.write(f"SKIPPING !!!! {line}")
            pass


if __name__ == "__main__":
    main()
