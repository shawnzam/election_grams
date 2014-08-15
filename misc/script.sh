#!/bin/bash
years=(1980 1982 1984 1986 1988 1990 1992 1994 1996 1998 2000 2002 2004 2006 2008 2010 2012)
for i in "${years[@]}" 
  do 
  ruby readmap.rb candidates.csv $i;

done