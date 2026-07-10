#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.14"
# dependencies = [
#     "bio>=1.8.1",
#     "pillow>=12.3.0",
#     "toytree>=3.0.11",
#     "numpy>=2.4.4",
#     "toyplot>=2.1.0"
# ]
# ///


import argparse
import dataclasses
from pathlib import Path

import numpy as np
import PIL.ImageColor
import toyplot as tp
import toytree
import toytree.mod
from Bio import SeqIO
from PIL import Image

NT_VAL_TO_COLOR = {
    1: "#EE7733",
    2: "#33BBEE",
    3: "#EE3377",
    4: "#0077BB",
    5: "#BBBBBB",
    0: "#FFFFFF",
}

NT_TO_NUM = {"A": 1, "T": 2, "C": 3, "G": 4, "-": 5, "": 0}
NUM_TO_NT = {v: k for k, v in NT_TO_NUM.items()}


@dataclasses.dataclass
class PlotParams:
    plot_title: str
    tree_width_prop: float = 0.5
    canvas_size: tuple[int, int] = (1000, 600)
    node_colours: str = "#2166AC"
    node_sizes: int = 8


@dataclasses.dataclass
class Sequences:
    names: list[str]
    seqs: list[list[str]]


def read_fasta_to_matrix(filepath: Path) -> Sequences:
    records = [list(str(_.seq)) for _ in SeqIO.parse(filepath.open("r"), "fasta")]
    names = [_.name for _ in SeqIO.parse(filepath.open("r"), "fasta")]

    return Sequences(seqs=records, names=names)


def transpose_sequences(sequences: Sequences) -> Sequences:
    column_array = []

    for col_idx in range(len(sequences.seqs[0])):
        this_col_array = []
        for sequence in sequences.seqs:
            this_col_array.append(sequence[col_idx])

        column_array.append(this_col_array)

    return Sequences(seqs=column_array, names=sequences.names)


def construct_heatmap(
    tree: toytree.ToyTree, msa: Sequences, baseline_seq_name: str
) -> np.ndarray:

    reordered_sequences = []

    for node in tree:
        if not node.is_leaf():
            pass
        if node.name in msa.names:
            seq_name_idx = msa.names.index(node.name)
            reordered_sequences.append(msa.seqs[seq_name_idx])

    reordered_sequences = reordered_sequences[::-1]

    baseline_seq_index = msa.names.index(baseline_seq_name)

    baseline_sequence = msa.seqs[baseline_seq_index]
    heat_grid = []

    for col_idx, col in enumerate(
        transpose_sequences(Sequences(names=[], seqs=reordered_sequences)).seqs
    ):
        col_array = []
        for col_char in col:
            if col_char == baseline_sequence[col_idx]:
                col_array.append(0)
            else:
                col_array.append(NT_TO_NUM[col_char])

        heat_grid.append(np.array(col_array))

    heatmap_image = np.array(heat_grid).T
    rgb_image: np.ndarray = np.zeros((*heatmap_image.shape, 3))

    for val, color in NT_VAL_TO_COLOR.items():
        rgb_image[heatmap_image == val] = PIL.ImageColor.getrgb(color)

    rgb_image = rgb_image.astype(np.uint8)

    return rgb_image


def resize_heatmap(
    heatmap: np.ndarray,
    heatmap_bounds: tuple[float, float, float, float],
    canvas_width: int,
    canvas_height: int,
) -> np.ndarray:
    panel_w_px = int((heatmap_bounds[1] - heatmap_bounds[0]) * canvas_width)
    panel_h_px = int((heatmap_bounds[3] - heatmap_bounds[2]) * canvas_height)

    # rgb must be uint8 here (you already do rgb = (rgb * 255).astype(np.uint8))
    img = Image.fromarray(heatmap, mode="RGB")

    img = img.resize((panel_w_px, panel_h_px), resample=Image.Resampling.NEAREST)
    return np.array(img)


def build_tree_heatmap_plot(
    tree_file: Path,
    msa_file: Path,
    baseline_seq_name: str,
    plot_params: PlotParams,
) -> tp.Canvas:
    tree: toytree.ToyTree = toytree.mod.root(toytree.tree(tree_file), baseline_seq_name)

    msa = read_fasta_to_matrix(msa_file)

    heatmap = construct_heatmap(tree, msa, baseline_seq_name)

    ntips = tree.ntips
    canvas_width, canvas_height = plot_params.canvas_size

    canvas = tp.Canvas(
        width=canvas_width, height=canvas_height, style={"background-color": "white"}
    )

    tree_axes = canvas.cartesian(
        bounds=("2%", f"{int(plot_params.tree_width_prop * 100)}%", "5%", "95%"),
        padding=0,
        ymin=-0.5,
        ymax=ntips - 0.5,
    )
    tree.draw(
        axes=tree_axes,
        tip_labels=False,
        node_sizes=plot_params.node_sizes,
        node_colors=plot_params.node_colours,
        node_mask=tree.get_node_mask(
            show_tips=True, show_root=True, show_internal=False
        ).tolist(),
        scale_bar=True,
    )
    tree_axes.show = False

    heatmap_bounds_frac = (
        plot_params.tree_width_prop,
        0.95,
        0.05,
        0.95,
    )

    heatmap_stretched = resize_heatmap(
        heatmap, heatmap_bounds_frac, canvas_width, canvas_height
    )

    canvas.image(
        heatmap_stretched,
        bounds=(f"{int(plot_params.tree_width_prop * 100)}%", "95%", "5%", "95%"),
    )
    canvas.text(
        500,
        20,
        plot_params.plot_title,
        style={"font-size": "18px", "font-weight": "black"},
    )
    return canvas


def save(final_plot: tp.Canvas, output_file: Path) -> None:
    toytree.save(final_plot, output_file)


def run_cli() -> None:

    parser = argparse.ArgumentParser(
        prog="th-plot",
        description="Plots a tree and Highlighter plot side-by-side, rooting on the specified sequence.",
    )
    parser.add_argument("tree_file", type=Path, help="Path to the tree file.")
    parser.add_argument("msa_file", type=Path, help="Path to the MSA file.")
    parser.add_argument(
        "output_file",
        type=Path,
        help="Path to write the output image, with the image extension. svg, jpg, and png are supported.",
    )
    parser.add_argument(
        "root_sequence_name",
        type=str,
        help="Name of the sequence to use as the tree root and the 'baseline' sequence in the highlighter plot.",
    )
    parser.add_argument(
        "--plot-title",
        type=str,
        default="",
        help="Text to display at the top of the plot (default: empty).",
    )
    parser.add_argument(
        "--tree-width-prop",
        type=float,
        default=0.5,
        help="Tree width proportion (default: 0.5)",
    )
    parser.add_argument(
        "--canvas-size",
        type=int,
        nargs=2,
        default=[1000, 600],
        metavar=("WIDTH", "HEIGHT"),
        help="Canvas size as width and height (default: 1000 600)",
    )
    parser.add_argument(
        "--node-colours",
        type=str,
        default="#2166AC",
        help="Node colour as hex code (default: #2166AC (blue))",
    )
    parser.add_argument(
        "--node-sizes", type=int, default=8, help="Node size in pixels (default: 8)"
    )

    args = parser.parse_args()
    plot_params = PlotParams(
        plot_title=args.plot_title,
        tree_width_prop=args.tree_width_prop,
        canvas_size=tuple(args.canvas_size),
        node_colours=args.node_colours,
        node_sizes=args.node_sizes,
    )

    joint_plot = build_tree_heatmap_plot(
        args.tree_file, args.msa_file, args.root_sequence_name, plot_params
    )

    save(joint_plot, args.output_file)


if __name__ == "__main__":
    run_cli()
