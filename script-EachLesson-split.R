# Script that I used to split the 'full_transcription.mid' into separate tracks
# Firstly, I converted full_transcription.mid into full_transcription.csv using midicsv
# After all the data-processing, I used csvmid to reverse back to .mid
library(tidyverse)
rm(list=ls())

Offset=6000

In=read.csv('full_transcription.csv',header=F)
Times=read.csv('table-TimeShift.csv')
Names=In %>% 
  filter(V3==' Marker_t') %>% 
  filter(V4!=' Start') %>% 
  mutate(x=V4 %>% str_replace_all('([A-Z]+?\\s[A-Z]+?)\\s.*','\\1') %>% str_trim()) %>% 
  .$x
x=sapply(1:nrow(In),function(i){
  x=In$V2[i]
  Which=which(Times$from<=x & Times$to>=x)
  if(length(Which)>1) Which=ifelse(str_detect(In$V3[i],'Note_off_c'),min(Which),max(Which))
  if(is_empty(Which)) return(0)
  return(Which)
})
In$Exercise=sapply(x,function(x){
  if(x==0) return('MANDATORY')
  return(Names[x])
})
In$Exercise[str_detect(In$V3,'End_track')]="MANDATORY"
UniqueNames=unique(Names)
for(i in 1:length(UniqueNames)){
  Out=In %>% 
    filter(Exercise %in% c(UniqueNames[i],"MANDATORY"))
  RelativeOffset=Out %>% 
    filter(V2>0) %>% 
    .$V2 %>% min()
  Out=Out %>% 
    mutate(V2=if_else(V2==0,0,V2-(RelativeOffset-Offset))) %>% 
    select(-Exercise)
  Out$V2[str_detect(Out$V3,'End_track')]=Out %>% 
    filter(str_detect(V3,'End_track',negate=T)) %>% 
    .$V2 %>% max() + 1000
  OutPrefix=str_c('EachLesson/',ifelse(i<10,str_c(0,i),i),'_',str_replace_all(UniqueNames[i],'\\s','_'))
  system(str_c("mkdir -p ",OutPrefix))
  write_csv(x=Out,file=str_c(OutPrefix,'/1.csv'),quote='none',col_names=F,na='')
}
