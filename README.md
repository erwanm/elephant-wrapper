
**Elephant Wrapper version 0.2.2**


# Overview

This software is a wrapper for the [Elephant tokenizer](http://gmb.let.rug.nl/elephant) ([github repo here](https://github.com/ParallelMeaningBank/elephant)). Besides providing a few pre-trained tokenizers, [Elephant](http://gmb.let.rug.nl/elephant) can train a new tokenizer using Conditional Random Fields ([Wapiti](https://wapiti.limsi.fr/) implementation) and optionally Recurrent Neural Networks ([Grzegorz Chrupala's 'Elman' implementation](https://bitbucket.org/gchrupala/elman), based on [Tomas Mikolov's Recurrent Neural Networks Language Modeling Toolkit](https://github.com/mspandit/rnnlm).

This wrapper aims at improving the usability of the original [Elephant](http://gmb.let.rug.nl/elephant) system. In particular, scripts are provided to facilitate the task of training a new model:

- `untokenize.pl` converts files in .conllu format from the [Universal Dependencies 2.1](http://universaldependencies.org/) corpora to the IOB format (required for training a tokenizer);
- `generate-patterns.pl` generates Wapiti patterns automatically;
- `cv-tokenizers-from-UD-corpus.sh` runs cross-validation experiments with multiple pattern files, in order to select the optimal pattern for a dataset;
- `train-multiple-tokenizers.sh` streamlines the process of training tokenizers for multiple datasets provided in the same format, like the [Universal Dependencies 2.1](http://universaldependencies.org/) corpora.
- The models trained from the Universal Dependencies 2.0 datasets; this means that this software include tokenizers for 50 languages (see usage below).



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
but this can be changed by assigning another path to `PREFIX`,
e.g. `make install PREFIX=/usr/local/bin/`.



## Usage

### Applying a tokenizer

#### Examples

~~~~
echo "Hello my old friend, why you didn't call?" | tokenize.sh en
~~~~

~~~~
tokenize.sh fr <my-french-text.txt
~~~~

#### Print a list of available language codes

~~~~
tokenize.sh -P
~~~~

#### Other options

~~~~
tokenize.sh -h
~~~~




### Training a tokenizer

#### Train an Elman language model and then train a Wapiti model

With `corpus.conllu` the input data (`conllu` format as in Universal Dependencies 2 data):

~~~~
train-lm-from-UD-corpus.sh corpus.conllu elman.lm
train-tokenizer-from-UD-corpus.sh -e corpus.conllu patterns/code7.txt my-output-dir
~~~~


#### Other options

For more details, most scripts in the `bin` directory display a usage message when executed with option `-h`.

# Experiments

## Download the UD 2.1 corpus

Download the data from https://lindat.mff.cuni.cz/repository/xmlui/handle/11234/1-2515.

## Generating a tokenizer for every corpus in the UD 2.1 data

The following command was used to generate the tokenizers provided in `models`. For every dataset, 96 patterns are tested using 5-fold cross-validation, then the optimal pattern (maximum accuracy) is used to train the final tokenizer.

With directory `ud-treebanks-v2.1` containing the datasets in the Universal Dependencies 2.1 data:

~~~
train-multiple-tokenizers.sh -e -m 0 -g 3,8,1,2,2,1 ud-treebanks-v2.1/ tokenizers # very long!
generate-iso639-codes-file.sh ud-treebanks-v2.1/ >tokenizers/iso639-codes.txt
~~~

This experiment can be replicated using the script `bin/experiments/01-train-full-UD2.sh` (which also takes care of downloading and extracting the UD2 data).



# Changelog

## Unreleased

- [changed] updated README documentation.
- [added] option to generate individual commands by dataset in `train-multiple-tokenizers.sh`, so that tasks can be run in parallel. 
- [removed] the ISO language codes are no longer generated in `train-multiple-tokenizers.sh`, it has to be called independently.

## 0.2.1

- [fixed] https://github.com/erwanm/elephant-wrapper/issues/33.

## 0.2.0

- [added] pattern files generation.
- [added] cross-validation for multiple patterns.
- [added] word-based evaluation.

# License

Please see file LICENSE.txt in this repository for details.

- [Elephant](http://gmb.let.rug.nl/elephant) and [Wapiti](https://wapiti.limsi.fr/) are both published under the [BSD 2 Clauses license](https://opensource.org/licenses/BSD-2-Clause).
-  - [Grzegorz Chrupala's 'Elman'](https://bitbucket.org/gchrupala/elman) is (c) Grzegorz Chrupala (no licensing information found). 'Elman' is a variant of [Tomas Mikolov's Recurrent Neural Networks Language Modeling Toolkit](https://github.com/mspandit/rnnlm), which is published under the [BSD 3 Clauses license](https://opensource.org/licenses/BSD-3-Clause).
- elephant-wrapper (this repository) is published under the GPLv3 license.




