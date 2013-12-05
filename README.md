# Procera

This repo contains the DSL abstraction layer for defining processes.


## Contents
* perl/Compiler - translates DSL into a Workflow XML + required inputs list
* perl/Runner - runs Workflow XML given inputs
* perl/Tool - base functionality for all tools


## TODO
- compiler
    - sugar for addressing "A::B::C" with "B::C" or "C"
        - this is partly implemented, it currently requires the shortest form
    - forbid recursive imports
    - improve parsing error messages (probably with <reject> and <error>)
    - fix string escaping regular expressions (grammar and syntax)
    - improve syntax hilighting of errors
    - add array input/output support
- add workspace input to Tool
- add locking to Tool
