# The LC4K Core Project

This project aims to provide synthesizable RTL VHDL models for Lattice ispMACH4000 devices.

## Overview

Code design generation is based on the reverse engineered fusemap definitions from [re4k](https://github.com/bcrist/re4k/). A python script assembles the core design from these building blocks:

* Pins
* Global routing pool (GRP)
* Generic logic blocks (GLB) with configuration of
  * Enhanced logic allocators
  * Macrocells
  * Output routing pools (ORP)

The result is a VHDL design per device type that accepts the fusemap as generic parameter.

Tests are provided to check equivalence between the original (golden) design and the generated LC4K core parametrized by the fusemap.

## Project setup

This repository uses [re4k](https://github.com/bcrist/re4k/) as a submodule. Clone lc4k_core with either commands:

```bash
$ git clone --recurse-submodules https://github.com/devsaurus/lc4k_core.git
```

```bash
$ git clone https://github.com/devsaurus/lc4k_core.git
$ cd lc4k_core
$ git submodule update --init --recursive
```

Also install the [simp_sexp](https://pypi.org/project/simp-sexp/) python package:

```bash
$ pip3 install simp_sexp
```

## Usage

### LC4K Core generator

Execute `make` in the `src/gen` folder. This lists the supported device types:

```
Generate core design files from CPLD fuse map documentation.

Make targets:
  LC4032ZC_TQFP48
  LC4032ZC_csBGA56
  LC4032ZE_TQFP48
  LC4032ZE_csBGA64
  LC4032x_TQFP44
  LC4032x_TQFP48
  LC4064ZC_TQFP100
  LC4064ZC_TQFP48
  LC4064ZC_csBGA132
  LC4064ZC_csBGA56
  LC4064ZE_TQFP100
  LC4064ZE_TQFP48
  LC4064ZE_csBGA144
  LC4064ZE_csBGA64
  LC4064ZE_ucBGA64
  LC4064x_TQFP100
  LC4064x_TQFP44
  LC4064x_TQFP48
  LC4128V_TQFP144
  LC4128ZC_TQFP100
  LC4128ZC_csBGA132
  LC4128ZE_TQFP100
  LC4128ZE_TQFP144
  LC4128ZE_csBGA144
  LC4128ZE_ucBGA132
  LC4128x_TQFP100
  LC4128x_TQFP128

  all   : Generate all above
  clean : Remove generated files
```

Select the desired target and execute e.g.

```bash
make LC4032ZC_TQFP48
```

to generate `lc4032zc_tqfp48_core.vhd`.

### Providing the fusemap

There are several approaches for how to integrate the core design and provide the fusemap as generic parameter.

#### JEDEC conversion

Each core design requires that the generic parameter `g_fusemap` is provided with a `std_logic_vector` of appropriate length and corresponds 1:1 to the contents of the JEDEC fusemap. In case of LC4032ZC_TQFP48, the vector contains 17200 bits.

Use `jed2vhdl.py` to convert a JEDEC file to a fusemap parameter:

```bash
$ python3 python/jed2vhdl.py <jedec file> <width> [-b] > vector
```

* `<width>` specifies how many bits shall be put into a single line of output. Just use the device's column width (172 in the example above), but any number should work
* `-b` optionally instructs the converter to omit `"&` characters. The result is a file containing only 0 and 1

#### By wrapper design

The lc*_core entity is instantiated in a wrapper that narrows down I/Os and sets the generic parameter `g_fusemap`.

Examples for this approach can be found in the `tests/` folder.

#### At synthesis time

[Ghdl](https://github.com/ghdl/ghdl) supports provisioning of generic parameters at the synthesis step. Refer to [synthesis option](https://ghdl.github.io/ghdl/using/Synthesis.html#synthesis-options) -g for details.

The payload for `-gg_fusemap=...` can be generated with

```bash
$ python3 python/jed2vhdl.py <jedec file> 1 -b > vector
```

## License

The LC4K Core project is provided under the terms of the GNU GENERAL PUBLIC LICENSE version 3. See `LICENSE` for details.
