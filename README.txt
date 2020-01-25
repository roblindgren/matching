Rob Lindgren - Matching Program

This is a Stata program that will create a 1-1 matched sample, i.e., a sample to be used
for making statistical comparisons to the original sample. The matched sample is similar 
on some set of matching variables that are different from the variable under investigation. 
This removes some of the effects of other matching variables when estimating differences 
between the samples. Wikipedia has a nice article on this that also links to helpful 
journal articles: https://en.wikipedia.org/wiki/Matching_(statistics).

The primary file of interest is “matching/src/match_sample.do”.  I included 
sample data in “matching/data/” and a driver program, “matching/src/main.do”. To run 
the driver file, open it and change the macro “working_directory” to the file path where 
you unzipped the zip file.

The bulk of the work is performed by a set of functions written in Stata's C-like development
language, Mata. As a lower-level language than the primary Stata language, it runs faster,
allows you to hold multiple datasets in memory, and allows you to use normal programming
data structures like vectors and matrices. 

You will find more detail in the comments on "match_sample.do".