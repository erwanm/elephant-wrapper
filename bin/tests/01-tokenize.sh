#!/bin/bash

text="Hello my old friend, why you didn't call?"
echo "Tokenizing en: \"$text\""
echo "$text" | tokenize.sh en
echo

text="Salut les amis! On s'amuse bien, n'est-ce pas ?"
echo "Tokenizing fr: \"$text\""
echo "$text" | tokenize.sh fr
echo

text="A no-deal Brexit would blow an £80bn hole in the public finances, with the leave-voting heartlands of the north-east and West Midlands worst affected, according to new detail from the government’s own secret economic analysis."
model="en"
echo "Tokenizing with en standard model: '$text'"
echo "$text" | tokenize.sh "$model"
echo


text="A no-deal Brexit would blow an £80bn hole in the public finances, with the leave-voting heartlands of the north-east and West Midlands worst affected, according to new detail from the government’s own secret economic analysis."
model="models/UD_English-PUD/elephant.elephant-model"
echo "Tokenizing with specific model '$model': '$text'"
echo "$text" | tokenize.sh "$model"
echo
