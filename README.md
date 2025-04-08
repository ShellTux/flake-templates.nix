# flake-templates.nix

My own custom flake templates

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

## Create a development environment using one of these templates

Initialize empty directory:

```shell
nix flake init --template github:ShellTux/flake-templates.nix#<ENV>
```

Create new directory:

```shell
nix flake new --template github:ShellTux/flake-templates.nix#<ENV> <PROJECT_NAME>
```

### Available environments


| Language/framework/tool          | Template                              |
| :------------------------------- | :------------------------------------ |
| [C]/[C++]                        | [`c-cpp`](./c-cpp/)                   |
| Empty (change at will)           | [`empty`](./empty)                    |
| [Go]                             | [`go`](./go/)                         |
| [Java]                           | [`java`](./java/)                     |
| [LaTeX]                          | [`latex`](./latex/)                   |
| [MATLAB]                         | [`matlab`](./matlab/)                 |
| [MATLAB/Octave]                  | [`matlab-octave`](./matlab-octave/)   |
| [Octave]                         | [`octave`](./octave/)                 |
| [Python]                         | [`python`](./python/)                 |
| [Rust]                           | [`rust`](./rust/)                     |
| [Shell]                          | [`shell`](./shell/)                   |
| [Zig]                            | [`zig`](./zig/)                       |

## Activate environment

Using nix:

```shell
nix develop
```

Using direnv

```shell
direnv allow
```
