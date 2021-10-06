#!/usr/bin/env python3

from typing import Optional, Tuple
from pathlib import Path
import click

TAG_ALL = "*"
RENDER_TODOS_REPLACE = "\\newcommand\\ShouldRenderTodos{1}"


@click.group()
def cli():
    pass


def in_any_range(ranges: list[Tuple[int, int]], i: int):
    return any(low <= i <= high for (low, high) in ranges)


def cut_out(tag: str, contents: str):
    start_match = f"% BEGIN ###"
    end_match = f"% END ###"
    lines = contents.split('\n')

    get_open_close = lambda l: (l.split(' ')[1], ' '.join(l.split(' ')[3:]))
    any_match = lambda l: l.startswith(start_match) or l.startswith(end_match)

    boundaries_all = list((get_open_close(l), i, l) for (i, l) in enumerate(lines) if any_match(l.strip()))
    boundaries = list(filter(lambda a: a[0][1] == tag.upper() or tag == TAG_ALL, boundaries_all))
    zipped_bounds_all = list(zip(boundaries[:-1], boundaries[1:]))

    for (i, (((be, tag_), li1, l1), ((be2, tag2_), li2, l2))) in enumerate(zipped_bounds_all):
        if be == be2 or (tag_ != tag2_ and i % 2 == 0):
            raise Exception(f"Bad start/end tag combo (mismatching) at lines {li1} and {li2}.\nStart tag: {l1}\nEnd tag: {l2}")

    zipped_bounds = list(b for (i, b) in enumerate(zipped_bounds_all) if i % 2 == 0)
    ranges = list((start, end) for ((_, start, _), (_, end, _)) in zipped_bounds)
    return "\n".join(l for (i, l) in enumerate(lines) if not in_any_range(ranges, i))


def process_file_contents_mode(mode: str, file_contents: str):
    if mode == "release":
        return cut_out("DRAFT", file_contents)
    if mode == "lint":
        return cut_out("*", file_contents)
    if mode == "draft":
        return file_contents
    raise Exception("no matching mode!")


def do_lint_check(file_contents: str):
    all_content_lines =  file_contents.split('\\begin{document}')[1].split('\\end{document}')[0]
    f_no_comments = '\n'.join(l for l in all_content_lines.splitlines() if not l.startswith("%"))
    should_be_empty = f_no_comments.replace(' ', '').replace('\n', '')
    if len(should_be_empty) > 0:
        raise Exception(f"Lint check failed! Offending content:\n\n---\n{all_content_lines}\n---\n\nPlease ensure this content is within DRAFT or RELEASE section tags. Number offending chars: {len(all_content_lines)}\n")


@cli.command()
@click.argument('input_file_path', nargs=1) #, required=True, help="Relative path+filename for the document to preprocess")
@click.option('--mode', required=True, type=click.Choice(['release', 'draft', 'lint']))
@click.option('--output-dir', required=False, help="Relative path to output directory")
@click.option('--md-check/--no-md-check', default=True, is_flag=True)
@click.option('--allow-in-place/--no-allow-in-place', default=False)
@click.option('--print-output/--no-print-output', default=False)
@click.option('--lint-check/--no-lint-check', default=True)
def process_tex(input_file_path: str, mode: str, output_dir: Optional[str], md_check: bool, allow_in_place: bool, print_output: bool, lint_check: bool):
    input_file = Path(input_file_path)
    file_ext = input_file.suffix
    file_name_w_ext = input_file.name
    input_dir = input_file.parent
    output_dir_path = Path(output_dir if output_dir else input_dir)

    if output_dir is None and not allow_in_place and not print_output and not mode == "lint":
        raise Exception("Must specify output file")
    if md_check and (file_ext not in ['.tex']):
        raise Exception(f"File (ext: {file_ext}) is not a .tex file!")

    with open(input_file, 'r') as f:
        file_contents = f.read()

    output_contents = process_file_contents_mode(mode, file_contents)
    output_file = output_dir_path / file_name_w_ext

    if mode == "lint":
        # this will always exit, but will throw an exception if it fails
        return do_lint_check(output_contents)

    if lint_check:
        # continue if this succeeds
        do_lint_check(process_file_contents_mode("lint", file_contents))

    if print_output:
        print(output_contents)
    else:
        with open(output_file, 'w') as f:
            f.write(file_contents)
    return


@cli.command()
@click.argument('input_file_path', nargs=1)
@click.option('--mode', required=True, type=click.Choice(['release', 'draft', 'lint']))
@click.option('--allow-in-place/--no-allow-in-place', default=False)
def set_todos_render(input_file_path: str, mode: str, allow_in_place: bool):
    # todo: chris
    pass


if __name__ == "__main__":
    cli()
