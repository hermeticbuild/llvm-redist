# llvm-redist

`llvm-redist` republishes official LLVM source release archives in `.tar.zst` format.

Scope:
- take upstream LLVM source releases (`llvm-project-*.src.tar.xz`)
- publish equivalent source archives as `.tar.zst`
- keep version-aligned artifacts, including release candidates (`-rc`)

Why this exists:
- provide a fast-to-consume mirror format for LLVM source redistribution
- keep upstream version identity while offering a different compression/container variant
