<!--
SPDX-FileCopyrightText: 2023 Technology Innovation Institute (TII)

SPDX-License-Identifier: CC-BY-SA-4.0
-->

# cpedict

This repository collects valid [CPE](https://en.wikipedia.org/wiki/Common_Platform_Enumeration) `product` and `vendor` names that appear in [NVD CPE dictionary](https://nvd.nist.gov/products/cpe). The [database](./data/cpes.csv) is updated on [daily basis](./.github/workflows/update-cpedict.yml). For all the entries in the [database](./data/cpes.csv), `cpe_version` is '2.3' and `part` is 'a' (application).


## Motivation

This repository provides a convenient way to obtain a complete database of valid combinations of CPE `product` and `vendor` names. Such database can be used, for instance, to build heuristics for locally mapping CPE vendor and product names.

## Third Party Resources

This repository builds upon data provided by [NVD](https://nvd.nist.gov/) either directly or via other redistributions of the NVD data, such as [nvd-json-data-feeds](https://github.com/fkie-cad/nvd-json-data-feeds). NVD API terms of use are available on the [NVD Developers website](https://nvd.nist.gov/developers/terms-of-use).

## License

This project is licensed under the Apache-2.0 license - see the [Apache-2.0.txt](LICENSES/Apache-2.0.txt) file for details.
