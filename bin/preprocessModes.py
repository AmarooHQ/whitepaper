#!/usr/bin/env python3

import sys
from typing import Callable, Optional, Tuple, Union
from pathlib import Path
from datetime import datetime, timedelta
import click
from blessings import Terminal
from hashlib import sha256
import shutil

t = Terminal()

def get_hash_lsb(xs: str) -> int:
    return int.from_bytes(sha256(xs.encode("UTF8")).digest()[-3:], 'little')

TAG_ALL = "*"
RENDER_TODOS_REPLACE = "\\newcommand*{\\ErrorOnReleaseIfTODOs}{yes}"
PREPROCESS_START_FLAG = "% RELEASE-LINT-START"


EXPECTED_SEGMENT_TAGS = ["RELEASE", "DRAFT"]


@click.group()
def cli():
    pass


def release_label(d: Union[datetime, Callable[[], datetime]] = datetime.now):
    now = d if isinstance(d, datetime) else d()
    year, week, dow = now.isocalendar()
    week += 1  # weeks (1,2) // 2 -> 1 this way -- aligns to schedule
    THURS = 4  # for testing or w/e
    FRI = 5
    week += 0 if dow <= FRI else 1
    prefix = "" if dow == FRI and week % 2 == 1 else "pre-"
    return f"{prefix}{year}.{week // 2}"


@cli.command()
def print_release_label():
    n = datetime.now()
    dates = [n + timedelta(days=i) for i in range(-14, 15)]
    print('\n'.join(f"{list(d.isocalendar())}\t -> {release_label(d) if d != n else release_label() + ' (today)'}" for d in dates))


@cli.command()
@click.option('--git', required=True, help="git shorthash for entropy")
@click.option('--prepare-for')
def set_entropy(git: str, prepare_for: Optional[str]):
    xor_with = 0 if prepare_for is None else get_hash_lsb(prepare_for)
    with open('includes/refl_entropy', 'w') as f:
        entropy = int(git, 16) ^ xor_with
        f.write(f"\\providecommand\\EntropyIn{{{str(entropy)}}}")
    print(t.bold_green(f"Wrote entropy: {entropy}"))


def in_any_range(ranges: list[Tuple[int, int]], i: int):
    return any(low <= i <= high for (low, high) in ranges)


def cut_out(tag: str, contents: str, extra_line_nums=0):
    start_match = f"% BEGIN \\#\\#\\#"
    end_match = f"% END \\#\\#\\#"
    lines = contents.split('\n')

    def get_open_close(l: str, line_number=0):
        [_, be, _, tag] = l.split(' ', 3)
        if tag not in EXPECTED_SEGMENT_TAGS:
            raise Exception(f"Found unknown tag on line {line_number}:\n\ttag: `{tag}`")
        return (be, tag)

    def any_match(l: str):
        return l.startswith(start_match) or l.startswith(end_match)

    boundaries_all = list((get_open_close(l.strip(), line_number=i+extra_line_nums), i, l) for (i, l) in enumerate(lines) if any_match(l.strip()))
    boundaries = list(filter(lambda a: a[0][1] == tag.upper() or tag == TAG_ALL, boundaries_all))
    zipped_bounds_all = list(zip(boundaries[:-1], boundaries[1:]))

    # print("\n".join(map(str, zipped_bounds_all)))

    for (i, (((be, tag_), li1, l1), ((be2, tag2_), li2, l2))) in enumerate(zipped_bounds_all):
        if be == be2 or (tag_ != tag2_ and i % 2 == 0):
            sample = '\n'.join(lines[li1:li1+10])
            raise Exception(f"""Bad start/end tag combo (mismatching) at lines {li1 + extra_line_nums} and {li2 + extra_line_nums}.
  - Start tag: {be} | {tag_}
  - End tag: {be2} | {tag2_}

\tFile Sample at line {li1 + extra_line_nums}:

---
{sample}
---
""")

    zipped_bounds = list(b for (i, b) in enumerate(zipped_bounds_all) if i % 2 == 0)
    ranges = list((start, end) for ((_, start, _), (_, end, _)) in zipped_bounds)
    return "\n".join(l for (i, l) in enumerate(lines) if not in_any_range(ranges, i))


def process_file_contents_mode(mode: str, file_contents: str, extra_line_nums=0):
    if mode == "release":
        return cut_out("DRAFT", file_contents, extra_line_nums=extra_line_nums)
    if mode == "lint":
        return cut_out("*", file_contents, extra_line_nums=extra_line_nums)
    if mode == "draft":
        return file_contents
    raise Exception("no matching mode!")


def do_lint_check(file_contents: str):
    # NB: we don't need to split at \begin{document} because that comes after PREPROCESSOR_START_FLAG
    all_content_lines =  file_contents.split('\\end{document}')[0]
    f_no_comments = '\n'.join(l for l in all_content_lines.splitlines() if not l.startswith("%"))
    should_be_empty = f_no_comments.replace(' ', '').replace('\n', '')
    if len(should_be_empty) > 0:
        raise Exception(f"Lint check failed! Offending content:\n\n---\n{all_content_lines}\n---\n\nPlease ensure this content is within DRAFT or RELEASE section tags. Number offending chars: {len(all_content_lines)}\n")


def replace_prepared_for(contents: str, prepared_for: Optional[str]) -> str:
    if prepared_for is None or len(prepared_for) < 2:
        return contents
    to_replace = "\\newcommand\\preparedfor{}"
    replace_with = f"\\newcommand\\preparedfor{{\\\\ \\scriptsize{{Prepared for {prepared_for}. \\\\ Not for distribution.}}}}"
    return contents.replace(to_replace, replace_with)


def read_file(file_path):
    with open(file_path, 'r') as f:
        return f.read()


def write_entire_file(file_path, contents):
    with open(file_path, 'w') as f:
        return f.write(contents)


@cli.command()
@click.argument('input_file_path', nargs=1) #, required=True, help="Relative path+filename for the document to preprocess")
@click.option('--mode', required=True, type=click.Choice(['release', 'draft', 'lint']))
@click.option('--output-dir', required=False, help="Relative path to output directory")
@click.option('--md-check/--no-md-check', default=True, is_flag=True)
@click.option('--allow-in-place/--no-allow-in-place', default=False)
@click.option('--print-output/--no-print-output', default=False)
@click.option('--lint-check/--no-lint-check', default=True)
@click.option('--prepare-for')
def process_tex(input_file_path: str, mode: str, output_dir: Optional[str], md_check: bool, allow_in_place: bool, print_output: bool, lint_check: bool, prepare_for: str):
    input_file = Path(input_file_path)
    file_ext = input_file.suffix
    file_name_w_ext = input_file.name
    input_dir = input_file.parent
    output_dir_path = Path(output_dir if output_dir else input_dir)

    if output_dir is None and not allow_in_place and not print_output and not mode == "lint":
        raise Exception("Must specify output file")
    if md_check and (file_ext not in ['.tex']):
        raise Exception(f"File (ext: {file_ext}) is not a .tex file!")

    file_contents = read_file(input_file)

    if PREPROCESS_START_FLAG not in file_contents:
        raise Exception(f"Unable to find flag indicating start of section to be preprocessed. Please add `%{PREPROCESS_START_FLAG}`")

    [unlinted_file_start, file_contents] = file_contents.split(PREPROCESS_START_FLAG, 1)

    processed_file_start = process_file_contents_mode(mode, unlinted_file_start) \
                            .replace('--RELEASE-LABEL--', release_label())
    output_contents = process_file_contents_mode(mode, file_contents, extra_line_nums=len(unlinted_file_start.splitlines())) \
                            .replace('% BEGIN \\#\\#\\# DRAFT\n', '\\hruleMarker{Begin DRAFT}\n') \
                            .replace('% END \\#\\#\\# DRAFT\n', '\\hruleMarker{End DRAFT}\n')
    output_file = output_dir_path / file_name_w_ext

    if mode == "lint":
        # this will always exit, but will throw an exception if it fails
        return do_lint_check(output_contents)

    if lint_check:
        # continue if this succeeds
        do_lint_check(process_file_contents_mode("lint", file_contents))

    processed_file_start2 = replace_prepared_for(processed_file_start, prepare_for)
    final_output = '\n'.join([processed_file_start2, output_contents])

    if print_output:
        print(final_output)
    else:
        write_entire_file(output_file, final_output)
    return


@cli.command()
@click.argument('pdf_path', nargs=1)
@click.option('--git', required=True, help="git shorthash")
@click.option('--prepare-for')
def copy_prepared_for(pdf_path, git: str, prepare_for: Optional[str]):
    if prepare_for:
        for_name = prepare_for.lower().strip().replace(' ', '-')
        if not for_name.replace('-', '').isalpha():
            print(t.bold_red(f"Tried to turn `{prepare_for}` in to a filename compatible string (`{for_name}`) but it seems to have other characters in it (not just alpha + dash). Erroring out."))
            sys.exit(71)
        new_path = f"amaroo-wp-{git}-{for_name}.pdf"
        print(t.bold_green(f"Copying {pdf_path} to {new_path}"))
        shutil.copy(pdf_path, new_path)


@cli.command()
@click.argument('input_file_path', nargs=1)
@click.option('--mode', required=True, type=click.Choice(['release', 'draft', 'lint']))
@click.option('--allow-in-place/--no-allow-in-place', default=False)
@click.option('--output-dir', required=False, help="Relative path to output directory")
@click.option('--print-output/--no-print-output', default=False)
def set_todos_render(input_file_path: str, output_dir: Optional[str], mode: str, allow_in_place: bool, print_output: bool):
    # Minor checks to ensure an output is provided
    if not allow_in_place and output_dir is None:
        raise Exception("Please specify one of: --allow-in-place or --output-dir")

    with open(input_file_path, 'r') as f:
        file_contents = f.read()

    if mode == "release":
        # Release mode is set the string to false
        file_contents = file_contents.replace(RENDER_TODOS_REPLACE, "")

    # We need to save the file
    input_file = Path(input_file_path)
    file_name_w_ext = input_file.name
    input_dir = input_file.parent
    output_dir_path = Path(output_dir if output_dir else input_dir)

    output_file = output_dir_path / file_name_w_ext

    # If debugging, print out
    if print_output:
        print(file_contents)
    else:
        with open(output_file, 'w') as f:
            f.write(file_contents)

    return


if __name__ == "__main__":
    cli()
