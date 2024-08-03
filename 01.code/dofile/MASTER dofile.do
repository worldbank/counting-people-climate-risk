*! version 0.1.1  01Aug2024
*! Copyright (C) World Bank 2024
*! Minh Cong Nguyen - mnguyen3@worldbank.org
*! Ben James Brunckhorst - bbrunckhorst@worldbank.org

* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.


//Vulnerable to poverty and climate 2.0
//folder structure and sequences

global rnd AM24
global upath2 "Your path here"

//See the excel file (readme) for the folder structure and the sequence of codes
/*
01.code\
	ado\
	dofile\
02.input\
03.intermediate\
	Lineupcheck\
	Lineuplist\
	LISoutput\
	PIPinput\
04.output\
05.references\
06.note\
07.presentations
*/

do "$upath2/01.code/dofile/0-0 GMD datacheck.do"
do "$upath2/01.code/dofile/0-1 Get PIP nat lineup number.do"
do "$upath2/01.code/dofile/0-2 Update pop class region.do"
do "$upath2/01.code/dofile/0-7a Findex_quintiles 2021.do"
do "$upath2/01.code/dofile/0-7a Findex_quintiles 2010.do"
do "$upath2/01.code/dofile/0-7b Prep ASPIRE.do"
do "$upath2/01.code/dofile/0-7c Prep JMP.do"
do "$upath2/01.code/dofile/0-7d Prep GED.do"
do "$upath2/01.code/dofile/0-7e Prep UNESCO.do"
do "$upath2/01.code/dofile/0-8 Water and Elec WDI.do"
do "$upath2/01.code/dofile/0-3 Prep data for coverage.do"

do "$upath2/01.code/dofile/1-1 Get list for LISSY.do"
do "$upath2/01.code/dofile/1-2 Get list for GMD full.do"

//Below dofiles need to run in LISSY.
do "$upath2/01.code/dofile/2-1a Estimate national vul rate for LISSY data.do" 
do "$upath2/01.code/dofile/2-1b Estimate vul rate for LISSY data.do"
//Get the txt from LISSY, clean it and run the code to format the data
do "$upath2/01.code/dofile/2-1c Extract national data - for LISSY data.do"
do "$upath2/01.code/dofile/2-1d Extract subnat data - for LISSY data.do"

//Run these in your machine
do "$upath2/01.code/dofile/2-2 Estimate vul rate for CHN data 2021.do"
do "$upath2/01.code/dofile/2-4 Estimate vul rate for IND data 2021.do"
do "$upath2/01.code/dofile/2-3 Estimate vul rate for GMD data full.do"
do "$upath2/01.code/dofile/2-5 Combine vul estimates full.do"
do "$upath2/01.code/dofile/2-6a Merge exposure and vul estimates.do"
do "$upath2/01.code/dofile/2-7 Vul_Exp - Get tables and figures.do"
do "$upath2/01.code/dofile/2-8 Get tables for CSC.do"
