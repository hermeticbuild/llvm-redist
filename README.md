# llvm-redist

`llvm-redist` republishes official LLVM source release archives in `.tar.zst` format.

Scope:
- take upstream LLVM source releases (`llvm-project-*.src.tar.xz`)
- publish equivalent source archives as `.tar.zst`
- keep version-aligned artifacts, including release candidates (`-rc`)

Why this exists:
- provide a fast-to-consume mirror format for LLVM source redistribution
- keep upstream version identity while offering a different compression/container variant

Verify attestations:
- release artifacts are attested by GitHub Actions via the reusable builder workflow [`reusable-repack.yml`](/Users/corentinkerisit/code/github.com/hermeticbuild/llvm-redist/.github/workflows/reusable-repack.yml)
- verify a local artifact with:

```sh
tools/verify-attestation.sh out/llvm-project-21.1.8.src.tar.zst refs/heads/main
```

- equivalent raw `gh` command:

```sh
gh attestation verify out/llvm-project-21.1.8.src.tar.zst \
  --repo hermeticbuild/llvm-redist \
  --signer-workflow hermeticbuild/llvm-redist/.github/workflows/reusable-repack.yml \
  --source-ref refs/heads/main
```
