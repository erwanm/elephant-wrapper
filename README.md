
**Elephant Wrapper version 0.2.3**


# Overview

This software is a wrapper for the [Elephant tokenizer](http://gmb.let.rug.nl/elephant) ([github repo here](https://github.com/ParallelMeaningBank/elephant)). Besides providing a few pre-trained tokenizers, [Elephant](http://gmb.let.rug.nl/elephant) can train a new tokenizer using Conditional Random Fields ([Wapiti](https://wapiti.limsi.fr/) implementation) and optionally Recurrent Neural Networks ([Grzegorz Chrupala's 'Elman' implementation](https://bitbucket.org/gchrupala/elman), based on [Tomas Mikolov's Recurrent Neural Networks Language Modeling Toolkit](https://github.com/mspandit/rnnlm).

This wrapper aims at improving the usability of the original [Elephant](http://gmb.let.rug.nl/elephant) system. In particular, scripts are provided to facilitate the task of training a new model:

- `untokenize.pl` converts files in .conllu format from the [Universal Dependencies 2.x](http://universaldependencies.org/) corpora to the IOB format (required for training a tokenizer);
- `generate-patterns.pl` generates Wapiti patterns automatically;
- `cv-tokenizers-from-UD-corpus.sh` runs cross-validation experiments with multiple pattern files, in order to select the optimal pattern for a dataset;
- `train-multiple-tokenizers.sh` streamlines the process of training tokenizers for multiple datasets provided in the same format, like the [Universal Dependencies 2.x](http://universaldependencies.org/) corpora.
- The models trained from the Universal Dependencies 2.x datasets; this means that this software include tokenizers for 50 languages (see usage below).

More details can be found in [this paper](http://www.lrec-conf.org/proceedings/lrec2018/summaries/1072.html); you can cite it btw ;)


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

## Download the UD 2.x corpus

Download the data from https://lindat.mff.cuni.cz/repository/xmlui/handle/11234/1-2515 (UD version 2.1).

## Generating a tokenizer for every corpus in the UD 2.x data

The following command can be used to generate the tokenizers provided in `models`. For every dataset, 96 patterns are tested using 5-fold cross-validation, then the optimal pattern (according to maximum accuracy) is used to train the final tokenizer.

With directory `ud-treebanks` containing the datasets in the Universal Dependencies 2.x data:

~~~
advanced-training-UD.sh -s 0.8 -l -e -m 0 -g 3,8,1,2,2,1 ud-treebanks tokenizers
~~~

Runnning this process will easily take several days on a modern machine. A basic way to process datasets in parallel consists in using option `-d`, which only prints the individual command needed for each dataset. The output can be redirected to a file, then the file can be split into the required number of batches. For instance, the following shows how to split the UD 2.1 data, which contains 102 datasets, into 17 batches of 6 datasets:

~~~
advanced-training-UD.sh -d -s 0.8 -l -e -m 0 -g 3,8,1,2,2,1 ud-treebanks-v2.1/ tokenizers >all.tasks
split -d -l 6 all.tasks batch.
for f in batch.??; do (bash $f &); done
~~~

Remark: since the datasets have different sizes, some batches will probably take more time than others.

## Reproducing the experiments described in the LREC 18 paper

The directory `experiments` contains 4 directories, each containing the scripts which were used to perform one of the experiments described in the LREC 18 paper. Of course, these scripts can also be used as examples in order to make your own experiments.

### Intra-language experiment

Run this experiment with:
~~~
experiments/01-training-same-language/apply-to-all-datasets-groups.sh <output dir>
~~~

This will generate the results of the experiment for the predefined groups (files `experiments/01-training-same-language/*.datasets`). After the experiment, the final tables can be found in `<output dir>/<language>/perf.out`.

### Training size experiment

~~~
experiments/02-training-size/training-size-larger-datasets.sh -l experiments/02-training-size/regular-datasets.list <UD2.1 path> 20 10 <output dir>
~~~

This will perform the training stage followed by testing on the test set for 10 different sizes of training data (proportional increment), and for the 20 largest datasets found in `regular-datasets.list`.

Option `-c` can be used to specify a custom list of sizes (warning: you must make sure that the datasets are large enough).

If using option `-d` the commands will be printed. This is convenient to run the processes in parallel (see example for `advanced-training.sh` above).


### VMWE17 experiment

This shows how to tokenize a third-party resource (here Europarl) following a model trained on some input data. The input data must be provided in a format which gives both the tokens and the original text (e.g. `.conll`). Only the parts of the experiment about training tokenizers from the VMWE17 data and applying these tokenizers to Europarl data are covered here.

~~~
experiments/03-train-from-VMWE17-shared-task/train-tokenizers-from-vmwe17.sh <VMWE17 path> <output dir>
split -d -l 1 <output dir>/tasks batch.
for f in batch.??; do (bash $f &); done # Caution: very long!
~~~

- Requires the [VMWE17 data](https://gitlab.com/parseme/sharedtask-data) available in <VMWE17 path>.
- `train-tokenizers-from-vmwe17.sh` prints the commands to execute for every dataset.
- Remark: if you want to skip the training stage, the models can be found in `experiments/03-train-from-VMWE17-shared-task/vmwe-trained-models.tar.bz2`.

Finally the models can be applied to Europarl with:

~~~
experiments/03-train-from-VMWE17-shared-task/tokenize-europarl.sh <VMWE-trained models dir> <Europarl data dir> <output dir>
~~~

This script will print the commands to run as individual files in `<output dir>/tasks`.

- Option `-n` can be used to split Europarl into chunks which can then be processed in parallel.
- Warning: the script `tokenize-line-by-line.sh` used here is very unefficient (sorry!).



# Changelog

## 0.2.3

- [fixed] couple bugs, in particular https://github.com/erwanm/elephant-wrapper/issues/39
- [added] `experiments/00-general-perf`: script and results to reproduce the training of all the tokenizers from UD2.1 data (paper LREC 18).
- [added] `experiments/01-training-same-language`: scripts and results to reproduce the intra-language experiments (paper LREC 18).
- [added] `experiments/02-training-size`: scripts and results to reproduce the training size experiments (paper LREC 18).
- [added] `experiments/03-train-from-VMWE17-shared-task`: scripts, models and results to reproduce the part about Europarl tokenization of the VMWE17 Shared Task experiment (paper LREC 18).
- [added] Token-based precision and recall available as evaluation measures.
- [added] Script `tokenize-line-by-line.sh` (warning: very slow).

## 0.2.2

- [added] script advanced-training.sh to process an individual dataset with cross-validation to select the best model.
- [changed] updated pred-tokenized models: (1) better performance using optimal pattern for each dataset; (2) updating corpus to UD 2.1, with more languages/datasets
- [changed] updated version of UD data from 2.0 to 2.x in scripts and examples.
- [added] option `-d` to generate individual commands by dataset in `train-multiple-tokenizers.sh`, so that tasks can be run in parallel.
- [changed] updated README documentation.

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




