version 16.0
clear all
set more off
set varabbrev off

* CHANGE THIS to whatever directory you save to
local working_directory "C:/Users/RLindgren/samples/Matching Sample - Robert Lindgren/"
cd "`working_directory'"

* Import Match Sample program
quietly do "src/match_sample"

* Define local macros
local sample1 "data/sample1.dta"
local sample2 "data/sample2.dta"
local output "output/final.dta"
local matchvars var1 var2 var3 var4 var5 var6 var7 var8 var9
local idvar id

* Main
match_sample "`sample1'" "`sample2'" "`output'" "`matchvars'" "`idvar'"

use "`output'"