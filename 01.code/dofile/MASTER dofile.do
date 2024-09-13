//Vulnerable to poverty and climate 2.0
//folder structure and sequences

global rnd AM24
global upath2 "path in your computer"

set varabbrev on

sysdir set PLUS "$upath2/01.code/ado"

** Run the needed do files 

*gtools, groupfunction, 

*no need to run
*do "$upath2/01.code/dofile/0-0 GMD datacheck.do"

do "$upath2/01.code/dofile/0-1 Get PIP nat lineup number.do"
do "$upath2/01.code/dofile/0-2 Update pop class region.do"
do "$upath2/01.code/dofile/0-7a Findex_quintiles 2021.do"
do "$upath2/01.code/dofile/0-7b Prep ASPIRE.do"
do "$upath2/01.code/dofile/0-7c Prep JMP.do"
do "$upath2/01.code/dofile/0-7d Prep GED.do"
do "$upath2/01.code/dofile/0-7e Prep UNESCO.do"
do "$upath2/01.code/dofile/0-8 Water and Elec WDI.do"
do "$upath2/01.code/dofile/0-3 Prep data for coverage.do"

* no need to run
*do "$upath2/01.code/dofile/0-4a Coverage check.do"

do "$upath2/01.code/dofile/1-1 Get list for LISSY.do"
do "$upath2/01.code/dofile/1-2 Get list for GMD full.do"

pause

* these two do files have to be run in Lissy interface. See readme file for details. 
*"$upath2/01.code/dofile/2-1a Estimate national vul rate for LISSY data.do" 
*$upath2/01.code/dofile/2-1b Estimate vul rate for LISSY data.do"

do "$upath2/01.code/dofile/2-1c Extract national data - for LISSY data.do"
do "$upath2/01.code/dofile/2-1d Extract subnat data - for LISSY data.do"
do "$upath2/01.code/dofile/2-2 Estimate vul rate for CHN data 2021.do"
do "$upath2/01.code/dofile/2-4 Estimate vul rate for IND data 2021.do"

do "$upath2/01.code/dofile/2-3 Estimate vul rate for GMD data full.do"

do "$upath2/01.code/dofile/2-5 Combine vul estimates full.do"
do "$upath2/01.code/dofile/2-6a Merge exposure, rai, and vul estimates.do"

*do "$upath2/01.code/dofile/2-7 Vul_Exp - Get tables and figures.do"
do "$upath2/01.code/dofile/2-8 Get tables for CSC.do"


