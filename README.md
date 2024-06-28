# zTroy

A versatile libary.

The goal of this library is to create a general library of basic functional functions

> Now, this library is developing!

## Feature

`.ini` parse

## Install

zig version: `0.12.0` or higher!

1. Add to `build.zig.zon`

```sh
# It is recommended to replace the following branch with commit id
zig fetch --save https://github.com/jinzhongjia/zTroy/archive/main.tar.gz
# Of course, you can also use git+https to fetch this package!
```

2. Config `build.zig`

Add this:

```zig
// To standardize development, maybe you should use `lazyDependency()` instead of `dependency()`
// more info to see: https://ziglang.org/download/0.12.0/release-notes.html#toc-Lazy-Dependencies
const zTroy = b.dependency("zTroy", .{
    .target = target,
    .optimize = optimize,
});

// add module
exe.root_module.addImport("tory", zTroy.module("troy"));
```

## Document

Waiting to be added!