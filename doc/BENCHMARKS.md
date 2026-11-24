# Benchmarks

These are measurements on one machine, under the conditions below. They
are not a verdict on either side.

`zig build bench` decodes the same inputs with the port and the original,
one feature per row, on one thread, and prints the table below:

```sh
zig build bench [-- --samples 11 --rounds 1 --filter <text>]
```

Each sample times enough decodes to last at least 50 ms of the benchmark
thread's CPU time; two warm-up samples come first, and a row reports the
median of 11 samples, with the range (slowest minus fastest, over the
median). The sides take turns sample by sample, the first side rotating, so
both see the same load. `--rounds N` runs the whole table N times and keeps
each side's best median. Every decode's output is kept behind a compiler
barrier, and the two sides' outputs are compared: a row whose bytes differ
says so. None did.

## Inputs

One photograph, jpeg-decoder's `tests/reftest/images/mjpeg.png` (960 x
720, RGB), decoded once and written at start-up:

- by stb_image_write (stb at the pinned commit): PNG RGB, RGBA and grey,
  JPEG at quality 95 (4:4:4) and 85 (4:2:0) and grey at 90, BMP 24 and 32
  bits, TGA raw and RLE, and HDR of the photo's squared values;
- by small writers in `bench/bench.zig`: 16-bit, Adam7 and 8-bit paletted
  PNGs (std's deflate, filters 0 to 4 in turn), PSD raw and PackBits with
  alpha blended over white as Photoshop stores it, PNM 8 and 16 bits, and a
  zlib stream of the RGB pixels;
- from the test corpora: jpeg-decoder's `progressive3.jpg` and
  `ycck.jpg`, and image-rs's `large-gif-anim-combine.gif`.

RGBA and 16-bit inputs carry made-up alpha and low bits, so no channel is
constant.

## Machine and flags

Measured on 12 November 2026, at commit `ac97ea4`, with `--rounds 3`, on
an AMD Ryzen 9 9950X3D (16 cores, 32 threads) under Linux 7.3.3 (CachyOS).
Other builds were running: the one-minute load average was between 6 and
20 during the run. Thread CPU time leaves out time spent
waiting, but other threads on the same core still slow a sample; the
ranges show how much.

- **The port:** Zig 0.17.0, ReleaseFast, for the machine's own CPU
  (`znver5`), allocating with the C allocator.
- **The original:** stb_image 2.30 (`a7d4c21`), built by the clang that
  Zig 0.17.0 carries (22.1.8), for the same CPU, at `-O3 -std=c99
  -ffp-contract=off -fno-fast-math -fno-sanitize=undefined`, linked
  statically. "original" is the build with its SSE2 paths, as upstream
  builds for x86-64; "original, no SIMD" adds `STBI_NO_SIMD` and is timed
  for the JPEG rows only, where the SIMD code is.
- **Both:** no fused multiply-adds, which the tests need for equal float
  outputs; `malloc` and `free` from glibc 2.44.

## Results

Mpix/s of output (MB/s for zlib); "time, port / original" is the port's
median time over the original's, so below 1 is faster.

| feature | port | range | original | range | time, port / original | original, no SIMD | time, port / no SIMD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| png rgb | 115.0 | 0.4% | 89.6 | 0.2% | 0.78 | | |
| png rgba | 99.9 | 0.6% | 80.0 | 2.9% | 0.80 | | |
| png grey | 261.7 | 0.5% | 184.5 | 0.4% | 0.71 | | |
| png rgb 16-bit | 64.7 | 2.8% | 54.6 | 1.0% | 0.84 | | |
| png rgb adam7 | 104.7 | 0.2% | 83.6 | 1.5% | 0.80 | | |
| png palette | 533.4 | 0.4% | 329.3 | 0.6% | 0.62 | | |
| png rgb to rgba | 109.7 | 0.5% | 89.5 | 1.2% | 0.82 | | |
| png rgb to float | 36.9 | 0.1% | 33.5 | 0.2% | 0.91 | | |
| jpeg 4:4:4 | 299.7 | 0.6% | 208.8 | 0.4% | 0.70 | 125.2 | 0.42 |
| jpeg 4:2:0 | 598.4 | 0.4% | 310.4 | 0.3% | 0.52 | 206.7 | 0.35 |
| jpeg 4:2:0 to rgba | 586.3 | 0.3% | 563.6 | 0.6% | 0.96 | 206.7 | 0.35 |
| jpeg grey | 621.0 | 0.5% | 321.1 | 0.4% | 0.52 | 210.9 | 0.34 |
| jpeg progressive | 114.1 | 1.7% | 110.3 | 1.1% | 0.97 | 76.0 | 0.67 |
| jpeg ycck | 137.2 | 1.4% | 101.0 | 1.7% | 0.74 | 66.6 | 0.49 |
| bmp 24-bit | 23205.9 | 2.8% | 1008.8 | 9.1% | 0.04 | | |
| bmp 32-bit | 18590.6 | 2.4% | 856.8 | 4.1% | 0.05 | | |
| bmp 24-bit to rgba | 7107.1 | 0.2% | 922.2 | 3.1% | 0.13 | | |
| tga raw | 15792.3 | 0.7% | 4489.9 | 0.6% | 0.28 | | |
| tga rle | 400.1 | 4.6% | 301.8 | 7.4% | 0.75 | | |
| tga raw to rgba | 5746.3 | 0.3% | 3598.8 | 0.3% | 0.63 | | |
| tga raw to grey | 6961.2 | 2.3% | 3616.1 | 0.7% | 0.52 | | |
| psd raw | 611.6 | 1.0% | 391.8 | 3.0% | 0.64 | | |
| psd rle | 454.0 | 0.5% | 396.3 | 17.2% | 0.87 | | |
| psd raw to rgb | 593.8 | 0.7% | 387.0 | 2.2% | 0.65 | | |
| hdr float | 226.2 | 7.8% | 178.5 | 6.5% | 0.79 | | |
| hdr to 8-bit | 43.1 | 1.0% | 41.2 | 1.1% | 0.95 | | |
| pnm 8-bit | 23728.8 | 1.5% | 23575.6 | 2.0% | 0.99 | | |
| pnm 16-bit | 13259.5 | 5.6% | 13181.7 | 4.6% | 0.99 | | |
| gif first frame | 416.0 | 4.6% | 331.9 | 13.1% | 0.80 | | |
| gif every frame | 510.2 | 15.0% | 399.8 | 11.0% | 0.78 | | |
| zlib inflate | 370.7 | 2.9% | 304.0 | 3.1% | 0.82 | | |
| png rgb via reader | 110.5 | 3.0% | 85.7 | 3.6% | 0.78 | | |
| png rgb via file | 112.3 | 0.7% | 87.7 | 0.2% | 0.78 | | |
| jpeg 4:2:0 via reader | 581.7 | 4.4% | 307.6 | 5.6% | 0.53 | | |
| jpeg 4:2:0 via file | 582.2 | 0.4% | 308.2 | 0.2% | 0.53 | | |
| bmp 24-bit via reader | 4869.9 | 0.3% | 762.3 | 0.6% | 0.16 | | |
| bmp 24-bit via file | 2668.0 | 2.8% | 688.5 | 1.0% | 0.26 | | |
| psd raw via reader | 438.2 | 0.7% | 370.8 | 2.5% | 0.85 | | |
| psd raw via file | 395.6 | 0.5% | 350.3 | 2.1% | 0.89 | | |
| psd rle via reader | 394.6 | 0.4% | 338.4 | 4.2% | 0.86 | | |
| psd rle via file | 367.0 | 0.9% | 309.9 | 2.0% | 0.84 | | |

## Second machine: the remaining passes (24 November 2026)

Measured at commit `3f17cdf` (branch `review/remaining-passes`) against
`5543dc2` (`main` with the PIC rows added), on a cloud virtual machine:
an Intel Xeon (Emerald Rapids) at 2.1 GHz, 4 virtual CPUs, Linux 6.18,
Ubuntu 24.04 (glibc 2.39), with other builds running. Flags as above,
for the machine's own CPU (`emeraldrapids`). The two builds' benchmarks
ran in turn, three times each, every row 11 samples; the table gives
port time over the original SSE2 build's, the median of the three runs
and their spread (lowest to highest). No row's bytes differed.

The kept changes are the HDR and PIC rows. The PSD raw rows and the TGA
and PSD RLE rows moved with the merge of the float-load fix, which
changes no PSD or TGA code: from the commit just before that merge to
the one after it, psd raw went 0.23 to 0.36 and psd rle 0.52 to 0.36, in
two interleaved runs. Other rows moved by up to 0.05 either way. On this
machine two rows are slower than the original, before and after: jpeg
4:2:0 to rgba (1.27) and tga raw to rgba (1.35); jpeg progressive (0.98)
and pnm (1.00) are level. On the first machine these rows were 0.96,
0.63, 0.97 and 0.99.

| feature | before | spread | after | spread |
| --- | ---: | ---: | ---: | ---: |
| png rgb | 0.86 | 0.84 to 0.86 | 0.85 | 0.85 to 0.86 |
| png rgba | 0.90 | 0.88 to 0.92 | 0.92 | 0.91 to 0.92 |
| png grey | 0.72 | 0.72 to 0.75 | 0.74 | 0.74 to 0.74 |
| png rgb 16-bit | 0.92 | 0.92 to 0.93 | 0.97 | 0.97 to 0.99 |
| png rgb adam7 | 0.85 | 0.84 to 0.85 | 0.86 | 0.86 to 0.86 |
| png palette | 0.68 | 0.67 to 0.68 | 0.67 | 0.66 to 0.68 |
| png rgb to rgba | 0.88 | 0.85 to 0.89 | 0.87 | 0.85 to 0.90 |
| png rgb to float | 0.80 | 0.79 to 0.81 | 0.79 | 0.79 to 0.82 |
| jpeg 4:4:4 | 0.83 | 0.82 to 0.84 | 0.81 | 0.79 to 0.82 |
| jpeg 4:2:0 | 0.69 | 0.69 to 0.69 | 0.68 | 0.67 to 0.68 |
| jpeg 4:2:0 to rgba | 1.29 | 1.28 to 1.29 | 1.27 | 1.27 to 1.27 |
| jpeg grey | 0.70 | 0.69 to 0.71 | 0.68 | 0.68 to 0.70 |
| jpeg progressive | 1.03 | 1.01 to 1.03 | 0.98 | 0.96 to 0.99 |
| jpeg ycck | 0.83 | 0.82 to 0.86 | 0.83 | 0.82 to 0.84 |
| bmp 24-bit | 0.07 | 0.07 to 0.08 | 0.07 | 0.07 to 0.07 |
| bmp 32-bit | 0.07 | 0.07 to 0.08 | 0.08 | 0.07 to 0.08 |
| bmp 24-bit to rgba | 0.27 | 0.27 to 0.27 | 0.28 | 0.28 to 0.28 |
| tga raw | 0.46 | 0.46 to 0.47 | 0.46 | 0.44 to 0.47 |
| tga rle | 0.91 | 0.91 to 0.92 | 0.76 | 0.76 to 0.76 |
| tga raw to rgba | 1.33 | 1.33 to 1.34 | 1.35 | 1.33 to 1.36 |
| tga raw to grey | 0.72 | 0.71 to 0.73 | 0.73 | 0.72 to 0.74 |
| psd raw | 0.22 | 0.22 to 0.23 | 0.31 | 0.31 to 0.32 |
| psd rle | 0.50 | 0.44 to 0.50 | 0.36 | 0.36 to 0.36 |
| psd raw to rgb | 0.24 | 0.23 to 0.25 | 0.37 | 0.35 to 0.37 |
| hdr float | 0.73 | 0.72 to 0.73 | 0.66 | 0.65 to 0.68 |
| hdr to 8-bit | 0.82 | 0.82 to 0.83 | 0.81 | 0.80 to 0.81 |
| pnm 8-bit | 1.00 | 0.97 to 1.01 | 1.00 | 0.99 to 1.00 |
| pnm 16-bit | 1.00 | 1.00 to 1.01 | 1.00 | 0.98 to 1.00 |
| pic raw | 1.12 | 1.08 to 1.13 | 0.23 | 0.23 to 0.23 |
| pic rle | 0.92 | 0.91 to 0.92 | 0.62 | 0.62 to 0.63 |
| gif first frame | 0.52 | 0.51 to 0.53 | 0.52 | 0.51 to 0.52 |
| gif every frame | 0.46 | 0.45 to 0.49 | 0.45 | 0.44 to 0.45 |
| zlib inflate | 0.85 | 0.84 to 0.86 | 0.85 | 0.85 to 0.86 |
| png rgb via reader | 0.83 | 0.83 to 0.83 | 0.84 | 0.84 to 0.85 |
| png rgb via file | 0.84 | 0.84 to 0.85 | 0.84 | 0.84 to 0.85 |
| jpeg 4:2:0 via reader | 0.70 | 0.70 to 0.70 | 0.68 | 0.68 to 0.69 |
| jpeg 4:2:0 via file | 0.70 | 0.70 to 0.71 | 0.69 | 0.69 to 0.69 |
| bmp 24-bit via reader | 0.15 | 0.15 to 0.16 | 0.14 | 0.14 to 0.27 |
| bmp 24-bit via file | 0.25 | 0.25 to 0.28 | 0.25 | 0.24 to 0.25 |
| psd raw via reader | 0.62 | 0.60 to 0.63 | 0.64 | 0.63 to 0.70 |
| psd raw via file | 0.58 | 0.57 to 0.62 | 0.65 | 0.63 to 0.65 |
| psd rle via reader | 0.63 | 0.62 to 0.63 | 0.59 | 0.58 to 0.60 |
| psd rle via file | 0.56 | 0.56 to 0.57 | 0.52 | 0.51 to 0.52 |

## Known biases and slower rows

- **JPEG.** Much of the port's lead on RGB output is the original's
  scalar conversion to three channels, which its SSE2 code leaves out; to
  RGBA, which the SSE2 code converts, the two are close (0.96).
  Progressive JPEG (0.97) is the closest row: its decoding is the port's
  scalar Huffman code against the original's.
- **Memory, reader and file loads.** The rows above, and every row whose
  name does not say otherwise, load from memory. The rows named "via
  reader" load through a `std.Io.Reader` over the bytes, against the
  original's callbacks over the same bytes; those named "via file" load
  from an in-memory file, against the original's `FILE` on the same
  descriptor (the original also opens and closes a `FILE` for each
  decode, a few microseconds). Both sides then read through a 128-byte
  buffer, so the port's fast paths that take a whole row from memory do
  not apply; it copies rows and planes from that buffer in pieces, as
  the original reads them byte by byte.
- **Allocation.** The port's zlib output is shrunk to its length at the
  end (`realloc`), and PNG reads IDAT data in 1 MiB pieces; the original
  does neither.
- **One machine, one input size.** Other images, sizes and CPUs give other
  ratios; small images weigh the fixed costs more.
- **Load.** The machine was busy with other work during this run.
