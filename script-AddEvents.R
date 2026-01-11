library(tidyverse)
rm(list=ls())

Names=read_lines('names.list')

for(Name in Names){
  Csv=In=read.csv(str_c('EachLesson/',Name,'/4.csv'),header=F)
  OutFile=str_c('EachLesson/',Name,'/5.csv')
  
  Events=Csv %>% 
    filter(V4!=' Start') %>% 
    filter(str_detect(V3,'Marker_t')) %>% 
    mutate(V1=3) %>%  # CHECK IF THIS IS THE CORRECT EVENTS TRACK! (USUALLY REPLACES METRONOME)
    mutate(V2=V2-3000) %>% 
    mutate(V3='Text_t') %>% 
    mutate(V4=V4 %>% str_remove_all(str_remove_all(Name,'[0-9]+?_') %>% str_replace_all('_',' ')) %>% str_trim()) %>% 
    mutate(V4=str_c('[section ',str_replace_all(tolower(V4),'\\s','_'),']'))
  Out=Csv %>% 
    filter(V1!=3) %>% 
    filter(V1!=0)
  
  # Header
  write_csv(x=head(Csv,n=1),file=OutFile,quote='none',col_names=F,na='')  

  # Body
  write_csv(x=Out,file=OutFile,quote='none',col_names=F,na='',append=T)
  
  # Events header
write_lines(append=T,file=OutFile,x=
'3,0,Start_track
3,0,Title_t,"EVENTS"
3,0,Control_c,0,0,0
3,0,Program_c,0,0')

  # Events body
  write_csv(x=Events,file=OutFile,quote='none',col_names=F,na='',append=T)
  
  # Events tail
  write_lines(file=OutFile,x=str_c('3,',max(Out$V2),',End_track'),append=T)
  
  # last line
  write_lines(file=OutFile,x=str_c('0,0,End_of_file'),append=T)
}
