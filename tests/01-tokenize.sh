#!/bin/bash

text="Hello my old friend, why you didn't call?"
echo "Tokenizing en: \"$text\""
echo "$text" | tokenize.sh en

text="Salut les amis! On s'amuse bien, n'est-ce pas ?"
echo "Tokenizing fr: \"$text\""
echo "$text" | tokenize.sh fr
