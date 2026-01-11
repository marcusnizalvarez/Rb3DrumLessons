#!/bin/bash

# Rock Band 3 Pro Drum Lessons Reference Video: https://www.youtube.com/watch?v=y17RgQUOrcA

# FILES EXPLAINED:
# 1.csv     : AllLessons.csv, but splitted for each Exercise Group and re-scaled to start at time 0 
# 2.mid     : Converted 1.csv into musical .mid file
# 3.mid     : Converted musical .mid into chart-like .mid
# 4.csv     : 3.mid file unwrapped as .csv to be edited, like adding events and so
# 5.csv     : The modified .csv file with events added
# notes.mid : Final product, wrapped 5.csv into .mid again
# song.ini  : Meta info for the game

# Step1
Rscript script-EachLesson-split.R

# Step2
for NAME in $(cat names.list); do
  csvmidi EachLesson/$NAME/1.csv EachLesson/$NAME/2.mid
done

# Step3 (requires: pip install mido)
for NAME in $(cat rockband3-exercises/names.list); do
  python script-mid-to-mid.py rockband3-exercises/EachLesson/$NAME/2.mid rockband3-exercises/EachLesson/$NAME/3.mid
done

# Step4
for NAME in $(cat names.list); do
  midicsv EachLesson/$NAME/3.mid EachLesson/$NAME/4.csv
done

# Step5
Rscript script-AddEvents.R

# Step6
for NAME in $(cat names.list); do
  csvmidi EachLesson/$NAME/5.csv EachLesson/$NAME/notes.mid
done

# Step7
for NAME in $(cat names.list); do
  SONGNAME=$(echo $NAME | sed -E 's/_/ /g' | sed -E 's/([0-9]+)/\1./g')
  EXERCISE=$(echo $NAME | sed -E "s|([0-9]+)_.*|\1|g")
  SCORE=$(((1+(10#$EXERCISE-1)*5+9)/10))
  cat song-template.ini | \
    sed -E "s/__SONGNAME__/$SONGNAME/g" | \
    sed -E "s/__SCORE__/$SCORE/g" > EachLesson/$NAME/song.ini
done
