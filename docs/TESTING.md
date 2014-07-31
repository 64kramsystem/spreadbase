Files
=====

- the `elements` suites test the abstract concept classes (document, table, etc.)
- the `codecs` suites have functional testing (encode -> decode cycle) of each code, plus UTs for codec-specific functionalities
- `spec_helpers.rb` are a few constants and methods useful for testing

Methodology
===========

The general workflow is to write specific UTs, then extend the functional test(s), then test on files generated with Libreoffice (from Libreoffice-built to spreadbase, from spreadbase-built to Libreoffice, and from Libreoffice-build to spreadbase to Libreoffice), using the `utils` scripts.
