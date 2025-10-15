# Tech Notes

- `image` package remains pinned to the 4.x line, but we rely on legacy-style helpers (`unsharpMask`, `setPixelRgba`). A compatibility shim lives in `lib/core/img_compat.dart`; migrate callers and update to the latest API when we can invest in the adapter work.
