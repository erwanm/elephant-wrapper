Elman
=====

Elman is a version of Tomas Mikolov's rnnlm toolkit [1] adapted to
output the activations of the hidden units to be used as embeddings.
This implementation was used to extract text representations used for
the tweet normalization task in [2].

Use
---

The input format for both training and new data is one text per line,
with symbols separated by spaces. The model
data/twitter.big.elman.4.414000000 was trained on tweets, represented
as sequences of bytes. The tweets were not filtered in any way and
could be in any language. This model should work for languages
commonly found on Twitter such as English, Spanish, Chinese or
Indonesian. If you want to extract hidden layer activations with this
model from new text use the following command:

    elman -rnnlm data/twitter.big.elman.4.414000000 -test data/example.txt -print-hidden > output.txt

The file data/example contains input formatted as sequences of bytes
for the following two texts:

    Hello world
    Wassup?

The output will contain the activations of 400 units of the hidden
layer, one line per input symbol, with a blank line separating
input for each text.

References
----------

- [1] [RNNLM Toolkit](http://www.fit.vutbr.cz/~imikolov/rnnlm/)
- [2] [Grzegorz Chrupała. 2014. Normalizing tweets with edit scripts and
    recurrent neural embeddings. ACL.](http://anthology.aclweb.org/P/P14/P14-2111.pdf)