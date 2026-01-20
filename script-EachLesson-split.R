library(tidyverse)
rm(list=ls())

In=read.csv('1-all_lessons.csv',header=F)
Times=In %>% 
  filter(str_detect(V3,'Marker_t')) %>% 
  filter(str_detect(V4,'Start',negate=T))
Times=data.frame(
  "from"=Times$V2,
  "to"=c(tail(Times$V2,-1),9999999),
  "LessonSet"=Times$V4 %>% str_replace_all('([A-Z]+?\\s[A-Z]+?)\\s(.*)','\\1') %>% str_trim(),
  "Lesson"=Times$V4 %>% str_replace_all('([A-Z]+?\\s[A-Z]+?)\\s(.*)','\\2') %>% str_trim()
)

# Get which lesson it belongs
x=sapply(1:nrow(In),function(i){
  x=In$V2[i]
  Which=which(Times$from<=x & Times$to>=x)
  if(length(Which)>1) Which=ifelse(str_detect(In$V3[i],'Note_off_c'),min(Which),max(Which))
  if(is_empty(Which)) return(0)
  return(Which)
})

In$LessonSet=sapply(x,function(xx){
  if(xx==0) return('MANDATORY')
  return(Times$LessonSet[xx])
})
In$Lesson=sapply(x,function(xx){
  if(xx==0) return('')
  return(Times$Lesson[xx])
})
In$LessonSet[str_detect(In$V3,'End_track')]="MANDATORY"
rm(Times,x)

LessonNames=unique(In %>% filter(Lesson!='') %>% .$Lesson)
LessonSetNames=unique(In %>% filter(LessonSet!='MANDATORY') %>% .$LessonSet)

# --- Set Offset (in ticks) 1000 = quarter note length
Offset=500

# --- Set first exercise first note as start
TrimPos=In %>% 
  filter(Lesson==LessonNames[1]) %>% 
  .$V2 %>% 
  min()
TrimPos=TrimPos-Offset
In$V2=sapply(In$V2,function(x){
  if(x==0) return(x)
  return(x-TrimPos)
})
rm(TrimPos)

# --- Remove silence and Add offset
for(i in 2:length(LessonNames)){
  Base=In %>%
    filter(Lesson==LessonNames[i-1]) %>% 
    .$V2 %>% max()
  First=In %>%
    filter(Lesson==LessonNames[i]) %>% 
    .$V2 %>% min()
  Diff=First-Base
  x=In$V2[In$V2>=First & In$Lesson!=LessonNames[i-1]] 
  x=x-Diff+Offset
  In$V2[In$V2>=First & In$Lesson!=LessonNames[i-1]]=x
}

# --- Export splitted csv
for(i in 1:length(LessonSetNames)){
  Out=In %>% 
    filter(LessonSet %in% c(LessonSetNames[i],"MANDATORY"))
  RelativeOffset=Out %>% 
    filter(V2>0) %>% 
    .$V2 %>% min()
  Out=Out %>% 
    mutate(V2=if_else(V2==0,0,V2-(RelativeOffset))) %>% 
    select(-LessonSet)
  Out$V2[str_detect(Out$V3,'End_track')]=Out %>% 
    filter(str_detect(V3,'End_track',negate=T)) %>% 
    .$V2 %>% max() + 1000
  OutPrefix=str_c('EachLesson/',ifelse(i<10,str_c(0,i),i),'_',str_replace_all(LessonSetNames[i],'\\s','_'))
  system(str_c("mkdir -p ",OutPrefix))
  write_csv(x=Out,file=str_c(OutPrefix,'/1.csv'),quote='none',col_names=F,na='')
}

# ----------------------------------------
OutMid=In %>% select(-LessonSet,-Lesson)

MetronomeChannel=3
OutMid$V1[OutMid$V1==MetronomeChannel]=MetronomeChannel+3 # add three channels for drums (needs 4)

DrumChannel=2
DrumData=OutMid %>% filter(V1==DrumChannel)
OutMid=OutMid %>% filter(V1!=DrumChannel)

# drums_1	Kick / low drum elements
DrumNotes=list(
  'drums_1'=c(
    35, # Bass Drum -> C7
    36, # Bass Drum -> C7
    41,  # Low Tom -> E8
    43  # Low Tom -> E8
  ),
  # drums_2	Snare
  'drums_2'=c(
    38, # Snare -> C#7
    40 # Snare -> C#7
  ),
  # drums_3	Toms
  'drums_3'=c(
    45,  # Mid Tom -> D#8
    47,  # Mid Tom -> D#8
    48,  # High Tom -> D8
    50  # High Tom -> D8
  ),
  # drums_4	Cymbals / hi-hat
  'drums_4'=c(
    42, # Hi-Hat Closed -> D7
    46, # Hi-Hat Open -> D7
    49, # Crash Cymbal -> D#7
    57, # Crash Cymbal -> D#7
    51,  # Ride Cymbal -> E7
    52,  # Ride Cymbal -> E7
    53 # Ride Bell -> E7
  )
)

NewDrumData=lapply(1:length(DrumNotes),function(i){
  x=DrumData %>% 
    filter(!(str_detect(V3,'Note_') & !(V5 %in% DrumNotes[[i]])))
  x$V1=DrumChannel+i-1
  return(x)
}) %>% 
  bind_rows()

OutMid=OutMid %>% 
  bind_rows(NewDrumData) %>% 
  arrange(V1,V2)

OutMid[1,5]=OutMid[1,5]+3

# Write to be as midi
write_csv(x=OutMid,file='temp.csv',quote='none',col_names=F,na='')
system("csvmidi temp.csv temp.mid")

# ----------------------------------------


