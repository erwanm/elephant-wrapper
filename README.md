
# Overview

This is a wrapper for the [Elephant tokenizer](http://gmb.let.rug.nl/elephant) ([github repo here](https://github.com/ParallelMeaningBank/elephant)). Besides providing a few pre-trained tokenizers, [Elephant](http://gmb.let.rug.nl/elephant) can train a new tokenizer using Conditional Random Fields ([Wapiti](https://wapiti.limsi.fr/) implementation) and optionally Recurrent Neural Networks ([Tomas Mikolov's Recurrent Neural Networks Language Modeling Toolkit](https://github.com/mspandit/rnnlm) implementation)

This version tries to improve the usability of the original system. In particular, scripts are provided to facilitate the task of training a new model. Among other things, we provide a script for converting files in .conllu format from the [Universal Dependencies 2.0](http://universaldependencies.org/) corpora to the IOB format (required for training a tokenizer).

This is a work in progress. There should be a few additional scripts and documentation soon enough :)

# Installation

By default the executables are copied in the local `bin` directory, but this can be changed this by assigning another path to `PREFIX`.

~~~~
make
make install
~~~~

Recommended:

~~~~
export PATH=$PATH:$(pwd)/bin
~~~~
# Usage

Most scripts in the `bin` directory display a usage message visible when executing with option `-h` (or with no argument at all, that works too). Below is the output of the main scripts:

## train-lm-from-UD-corpus.sh

Use if you want to include features from the RNN language model with the tokenizer.

~~~~
Usage: train-lm-from-UD-corpus.sh [options] <UD conllu file> <output lm file>

  Options:
    -h this help
    -p <percentage training set> The rest is used as validation set;
       Default: 80.
    -t <nb threads>
~~~~

## bin/train-tokenizer-from-UD-corpus.sh

Main script for training the CRF model. You can pick a pattern file from the directory `patterns` (remark: future versions will include the options described in the original authors paper).

~~~~
Usage: train-tokenizer-from-UD-corpus.sh [options] <UD conllu file> <pattern file> <output model directory>

  Remark: <pattern file> should not contain the Elman features, they will be added
  automatically if option -e is provided.

  Options:
    -h this help
    -e <Elman LM file> use LM features
~~~~

## bin/apply-tokenizer-to-UD-corpus.sh

~~~~
Usage: apply-tokenizer-to-UD-corpus.sh [options] <UD conllu file> <elephant model directory> <output file>

  Options:
    -h this help
    -i output in IOB format and perform evaluation to <output file>.eval
~~~~

# License


## Elephant, Wapiti

[Elephant](http://gmb.let.rug.nl/elephant) and [Wapiti](https://wapiti.limsi.fr/) are both published under the [BSD 2 Clauses license](https://opensource.org/licenses/BSD-2-Clause): 

Copyright (c) 2009-2013  CNRS
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

## Tomas Mikolov's Recurrent Neural Networks Language Modeling Toolkit

Copyright (c) 2010-2012 Tomas Mikolov
Copyright (c) 2013 Cantab Research Ltd
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

- Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

- Neither name of copyright holders nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.


THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS"" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


## elephant-wrapper (this software)

(c) Trinity College Dublin, Adapt Centre and Erwan Moreau

License not decided yet, but it will definitely allow distribution and modification.


