
Elephant Wrapper version 0.1

# Overview

This software is a wrapper for the [Elephant tokenizer](http://gmb.let.rug.nl/elephant) ([github repo here](https://github.com/ParallelMeaningBank/elephant)). Besides providing a few pre-trained tokenizers, [Elephant](http://gmb.let.rug.nl/elephant) can train a new tokenizer using Conditional Random Fields ([Wapiti](https://wapiti.limsi.fr/) implementation) and optionally Recurrent Neural Networks ([Grzegorz Chrupala's 'Elman' implementation](https://bitbucket.org/gchrupala/elman), based on [Tomas Mikolov's Recurrent Neural Networks Language Modeling Toolkit](https://github.com/mspandit/rnnlm).

This version aims at improving the usability of the original system. In particular, scripts are provided to facilitate the task of training a new model. Among other things, we provide a script for converting files in .conllu format from the [Universal Dependencies 2.0](http://universaldependencies.org/) corpora to the IOB format (required for training a tokenizer). We also provide the models trained from the Universal Dependencies 2.0 datasets; this means that this software include tokenizers for 50 languages (see usage below).

This is a work in progress.

# Installation

## Obtaining this repository together with its dependencies

This git repository includes [submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules). This is why it is recommended to clone it with:

~~~~
git clone --recursive git@github.com:erwanm/elephant-wrapper.git
~~~~

Alternatively, the dependencies can be downloaded separately. In this case the executables should be accessible in the `PATH` environment variable.

## Compiling third-party components

Recommended way to compile and setup the environment:

~~~~
make
make install
export PATH=$PATH:$(pwd)/bin
~~~~

By default the executables are copied in the local `bin` directory,
but this can be changed this by assigning another path to `PREFIX`,
e.g. `make install PREFIX=/usr/local/bin/`.



## Usage

### Applying a tokenizer

Example:

~~~~
tokenize.sh en <my-english-text.txt
~~~~

To print a list of available language codes:

~~~~
tokenize.sh -P
~~~~

Various options are available, see:

~~~~
tokenize.sh -h
~~~~




### Training a tokenizer

Unfortunately this part of the documentation is not done yet!
Nevertheless, most scripts in the `bin` directory display a usage
message when executed with option `-h`, this should get you started.

# License

Please see file LICENSE.txt in this repository for details.

- [Elephant](http://gmb.let.rug.nl/elephant) and [Wapiti](https://wapiti.limsi.fr/) are both published under the [BSD 2 Clauses license](https://opensource.org/licenses/BSD-2-Clause).
-  - [Grzegorz Chrupala's 'Elman'](https://bitbucket.org/gchrupala/elman) is (c) Grzegorz Chrupala (no licensing information found). 'Elman' is a variant of [Tomas Mikolov's Recurrent Neural Networks Language Modeling Toolkit](https://github.com/mspandit/rnnlm), which is published under the [BSD 3 Clauses license](https://opensource.org/licenses/BSD-3-Clause).
- elephant-wrapper (this repository) is published under the GPLv3 license.




