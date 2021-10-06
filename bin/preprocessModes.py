#!/usr/bin/env python3

from typing import Optional, Tuple
from pathlib import Path
import click

TAG_ALL = "*"


@click.group()
def cli():
    pass


def in_any_range(ranges: list[Tuple[int, int]], i: int):
    return any(low <= i <= high for (low, high) in ranges)


def cut_out(tag: str, contents: str):
    start_match = f"%% BEGIN ###"
    end_match = f"%% END ###"
    lines = contents.split('\n')

    get_open_close = lambda l: (l.split(' ')[1], ' '.join(l.split(' ')[3:]))
    any_match = lambda l: l.startswith(start_match) or l.startswith(end_match)

    boundaries_all = list((get_open_close(l), i, l) for (i, l) in enumerate(lines) if any_match(l))
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


@cli.command()
@click.option('--mode', required=True, type=click.Choice(['release', 'draft', 'lint']))
@click.option('--file', required=True, help="Relative path+filename for the document to preprocess")
@click.option('--output-dir', required=False, help="Relative path to output directory")
@click.option('--md-check/--no-md-check', default=True, is_flag=True)
@click.option('--allow-in-place/--no-allow-in-place', default=False)
@click.option('--print-output/--no-print-output', default=False)
def process_md(mode: str, file: str, output_dir: Optional[str], md_check: bool, allow_in_place: bool, print_output: bool):
    input_file = Path(file)
    file_ext = input_file.suffix
    file_name_w_ext = input_file.name
    input_dir = input_file.parent
    output_dir_path = Path(output_dir if output_dir else input_dir)

    if output_dir is None and not allow_in_place and not print_output:
        raise Exception("Must specify output file")
    if md_check and (file_ext not in ['md', 'markdown']):
        raise Exception("File is not a markdown file!")

    with open(input_file, 'r') as f:
        file_contents = f.read()

    output_contents = process_file_contents_mode(mode, file_contents)
    output_file = output_dir_path / file_name_w_ext

    if print_output:
        print(output_contents)
    else:
        with open(output_file, 'w') as f:
            # f.write(file_contents)
            pass
    return

if __name__ == "__main__":
    cli()
