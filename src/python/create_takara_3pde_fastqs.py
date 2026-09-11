# /// script
# requires-python = ">=3.14"
# dependencies = [
#     "biopython>=1.88",
#     "typer>=0.27.2",
# ]
# ///


import gzip
from pathlib import Path
import random

from Bio import SeqIO
from Bio.Seq import Seq
import typer

app = typer.Typer()

@app.command()
def main(
    fastq_file_path_r1: Path,
    fastq_file_path_r2: Path,
    output_prefix: str,
    seed: int = 20260904,
) -> None:
    random.seed(seed)

    inline_indexes = ["CTAGCT", "CGATGT", "TGACCA",]

    # construct output file paths from output prefix
    fastq_r1_out_path = Path(output_prefix + "_R1_001.fastq.gz")
    fastq_r2_out_path = Path(output_prefix + "_R2_001.fastq.gz")

    # R1 files for Takara 3' DE libraries don't have any inline index or other barcode information
    # just copy these over using the output file prefix
    typer.echo("Copying R1 FASTQ file to output path", err=True,)
    fastq_file_path_r1.copy(fastq_r1_out_path)
    typer.echo(f"Copied '{fastq_file_path_r1!s}' -> '{fastq_r1_out_path!s}'.", err=True,)

    # add inline index to R2 file sequence
    typer.echo(f"Adding inline indexes to R2 file.", err=True,)
    with (
        gzip.open(fastq_file_path_r2, "rt") as fq_r2_in_handle,
        gzip.open(fastq_r2_out_path, "wt") as fq_r2_out_handle,
    ):
        for record in SeqIO.parse(fq_r2_in_handle, "fastq"):
            # prepend sequence with index and drop the last n bases from the sequence
            # this effectively acts like the first n bases were actually the in-line
            # there's no need here to do anything with the quality line
            inline_index = random.choice(inline_indexes)
            sequence_with_inline = inline_index + record.seq[:-len(inline_index)]
            record.seq = sequence_with_inline

            SeqIO.write(record, fq_r2_out_handle, "fastq")

    typer.echo(f"Wrote output R2 file to '{fastq_r2_out_path!s}'.")


if __name__ == "__main__":
    app()
