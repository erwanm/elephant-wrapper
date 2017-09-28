
This is a modified version of the Elephant tokenizer system:
- [[original repository|https://github.com/ParallelMeaningBank/elephant]]
- [[original website|http://gmb.let.rug.nl/elephant]]
- [[Paper by the original authors|http://aclweb.org/anthology/D/D13/D13-1146.pdf]]

This version tries to improve usability of the system, in particular we try to make training a new model easier.
We propose a few additional scripts
To install elephant simply type

$ make ; make install

this will compile the external tools wapiti and elman and copy the
executables files in /usr/local/bin . To change the destination directory
the variable PREFIX in the Makefile has to be edited.

After installation, elephant is invoked like in these examples:

(PTB-style output)
$ echo 'Good morning Mr. President.' | elephant -m models/english

(IOB output format)
$ echo 'Good morning Mr. President.' | elephant -m models/english -f iob

It is also possible to run elephant from the source directory without need
to install it, by just typing

$ make

and invoking the executable from the current directory, e.g.

$ echo 'Good morning Mr. President.' | ./elephant -m models/english/

Included in the distribution there are the models for sentence and word boundary
detection of English, Dutch and Italian.

License

[[Elephant|http://gmb.let.rug.nl/elephant]] is published under the [[BSD 2 Clauses license|https://opensource.org/licenses/BSD-2-Clause]]: 

Copyright (c) 2009-2013  CNRS
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
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
