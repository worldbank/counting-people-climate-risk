{smcl}
{* 3sep2015/24sep2015/26nov2015/11may2017/27jun2017/3sep2020/27jan2023}{...}
{cmd:help missings}{right: ({browse "http://www.stata-journal.com/article.html?article=up00!!":SJ23-2: dm0085_3})}
{hline}

{title:Title}

{phang}
{cmd:missings} {hline 2} Various utilities for managing missing values

{title:Syntax}

{p 8 16 2}
{cmd:missings} {opt r:eport} [{varlist}] {ifin} [{cmd:,} 
{opt num:eric} {opt str:ing} {opt sys:miss} 
{opt obs:ervations} {opt min:imum(#)} {opt p:ercent} {opt f:ormat(format)}
{opt id:entify(varlist)}
{opt sort(specification)} {opt show(#)} {it:{help list:list_options}}]

{p 8 16 2}
{cmd:missings} {opt b:reakdown} [{varlist}] {ifin} [{cmd:,} 
{opt num:eric} {opt str:ing} {opt sys:miss} {opt min:imum(#)} {opt sort(specification)} {opt show(#)} 
{it:{help list:list_options}}]

{p 8 16 2}
{cmd:missings} {opt l:ist} [{varlist}] {ifin}   
[{cmd:,} 
{opt num:eric} {opt str:ing} {opt sys:miss} 
{opt min:imum(#)}
{opt id:entify(varlist)} 
{it:{help list_options}}]

{p 8 16 2}
{cmd:missings} {opt tab:le} [{varlist}] {ifin}   
[{cmd:,}
{opt num:eric} {opt str:ing} {opt sys:miss} 
{opt min:imum(#)}
{opt id:entify(varlist)} 
{it:{help tabulate_oneway:tabulate_options}}]

{p 8 16 2}
{cmd:missings} {opt tag} [{varlist}] {ifin}{cmd:,} {opt gen:erate(newvar)}
[{opt num:eric} {opt str:ing} {opt sys:miss}] 

{p 8 16 2}
{cmd:missings dropvars} [{varlist}] 
[{cmd:,} 
{opt num:eric} {opt str:ing} {opt sys:miss} 
{opt force}]


{p 8 16 2}
{cmd:missings dropobs} [{varlist}] {ifin}   
[{cmd:,} 
{opt num:eric} {opt str:ing} {opt sys:miss} 
{opt force}]


{pstd}
{cmd:by:} may be used with any of {cmd:missings report}, {cmd:breakdown}, {cmd:missings list},
or {cmd:missings table}.  See {manhelp by D}.


{title:Description}

{pstd}
{cmd:missings} is a set of utility commands for managing variables that
may have missing values. By default, "missing" means numeric missing
(that is, the system missing value {cmd:.} or one of the extended missing
values {cmd:.a} to {cmd:.z}) for numeric variables and empty or {cmd:""} for
string variables.  See {helpb missing:[U] 12.2.1 Missing values} for further
information. 

{pstd}
If {varlist} is not specified, it is interpreted by default as all
variables. 

{pstd}
{cmd:missings report} issues a report on the number of missing values in
{varlist}. By default, counts of missings are given by variables;
optionally, counts are given by observations. 

{pstd}
{cmd:missing breakdown} issues a report on different missing values
in {varlist}, that is the numbers present of (1) empty strings {cmd:""} if string 
variables are included and (2) system missing and extended missing 
values if numeric variables are included. This subcommand is most obviously 
useful as a check on the presence of extended missing values for numeric 
variables. 

{pstd}
{cmd:missings list} lists observations with missing values in {varlist}. 

{pstd}
{cmd:missings table} tabulates observations by the number of missing
values in {varlist}. 

{pstd} 
{cmd:missings tag} generates a variable containing the number of missing
values in each observation in {varlist}. 

{pstd}
{cmd:missings dropvars} drops any variables in {varlist} that are
missing on all values. 

{pstd}
{cmd:missings dropobs} drops any observations that are missing on all
values in {varlist}. 


{title:Options} 

{phang}
{opt numeric} (all subcommands) indicates to include numeric
variables only. If any string variables are named explicitly, such
variables will be ignored. 

{phang}
{opt string} (all subcommands) indicates to include string variables
only. If any numeric variables are named explicitly, such variables will
be ignored. 

{phang}
{opt sysmiss} (all subcommands) indicates to include system missing
{cmd:.} only. This option has no effect with string variables, for which
missing is deemed to be the empty string {cmd:""}, regardless. 

{phang}
{opt observations} (with {cmd:missings report})  indicates counting of
missing values by observations, not the default of counting by
variables. 

{phang}
{opt minimum(#)}  (with {cmd:missings report}; {cmd:missings breakdown}; {cmd:missings list}; and
{cmd:missings table}) specifies the minimum number of missings to be
shown explicitly. With {cmd:missings table}, the default is {cmd:minimum(0)};
otherwise, it is {cmd:minimum(1)}.  

{phang}
{opt percent} (with {cmd:missings report})  reports percents missing as well as
counts. Percents are calculated relative to the number of observations or
variables specified. 

{phang}
{opt format(format)} (with {cmd:missings report})  specifies a display 
format for percents. The default is {cmd:format(%5.2f)}. This option has no
effect unless {opt percent} is also specified. 

{phang}
{opt identify(varlist)} or {opt identify(varname)}
(with {cmd:missings report, observations}; {cmd:missings list}; and {cmd:missings table})
insists on showing {it:varlist} or {it:varname} in the display of results.
This can be especially useful to show (for example) identifier variables, which
typically will not be missing, or key categorical variables such as education
or gender.  With {cmd:missings report, observations}
and {cmd:missings list}, {it:varlist} is included in the {cmd:list} results.
With {cmd:missings table}, {it:varname} is used to produce a two-way table in
contrast to a one-way table; two or more variables may not be specified.

{phang}
{opt sort(specification)} (with {cmd:missings report} and {cmd:missings breakdown})  specifies output should be
sorted as specified. The {it:specification} must include either {cmd:missings}
or {cmd:alpha} or any abbreviation of either keyword. {cmd:missings} means
sorting by number of missing values. {cmd:alpha} means sorting by variable
name. The specification may include {cmd:descending} to indicate sorting in
descending order, for example, that variables with the most missing values will
be shown first. 

{p 8 8 2}Note: to maintain compatibility with previous versions, the bare
option {opt sort} is also supported, although not indicated in the syntax
diagram. {opt sort} is equivalent to {cmd:sort(missings descending)}. 

{phang}
{opt show(#)} (with {cmd:missings report} and {cmd:missings breakdown}) specifies that at most the first {it:#}
variables be shown.  This option has no effect unless sorting is also specified
and is most obviously useful whenever the sort is on the number of missing
values.  

{phang}
{it:list_options} (with {cmd:missings report}, {cmd:missings breakdown} and {cmd:missings list}) are options
listed in {manhelp list D} that may be specified when {cmd:list} is used to
show results. 

{phang}
{it:tabulate_options} (with {cmd:missings table})  are options listed in
{manhelp tabulate_oneway R:tabulate oneway} or
{manhelp tabulate_twoway R:tabulate twoway}
that may be specified when {cmd:tabulate} is used to show results. 

{phang}
{opt generate(newvar)} (with {cmd:missings tag}) specifies the name of a new
variable. {cmd:generate()} is required.

{phang}
{opt force} (with {cmd:missings dropvars} and {cmd:missings dropobs}) signals
that the dataset in memory is being changed and is a required
option when data are being dropped and the dataset in memory has not been
saved as such. 
  

{title:Remarks} 

{pstd}
{cmd:missings} is intended to unite and supersede the main ideas of 
{cmd:nmissing} (Cox 1999, 2001a, 2003, 2005) and 
{cmd:dropmiss} (Cox 2001b, 2008). 

{pstd}
Creating entirely empty observations (rows) and variables (columns)
is a habit of many spreadsheet users, but neither is helpful in Stata 
datasets. The subcommands {cmd:dropobs} and {cmd:dropvars} should 
help users clean up. Conversely, there is no explicit support here for
dropping observations or variables with some missing and some
nonmissing values. Users so minded will find other subcommands of use 
as an intermediate step, but multiple imputation might be a better way
forward. 


{title:Examples}

{phang}{cmd:. webuse nlswork, clear}{p_end}
{phang}{cmd:. missings report}{p_end}
{phang}{cmd:. missings report, minimum(1000)}{p_end}
{phang}{cmd:. missings report, sort(miss desc)}{p_end}
{phang}{cmd:. missings report, sort(miss desc) show(10)}{p_end}
{phang}{cmd:. missings list, minimum(5)}{p_end}
{phang}{cmd:. missings list, minimum(5) id(race)}{p_end}
{phang}{cmd:. missings table}{p_end}
{phang}{cmd:. bysort race: missings table}{p_end}
{phang}{cmd:. missings table, identify(race)}{p_end}
{phang}{cmd:. missings tag, generate(nmissing)}{p_end}
{phang}{cmd:. generate frog = .}{p_end}
{phang}{cmd:. generate toad = .a}{p_end}
{phang}{cmd:. generate newt = ""}{p_end}
{phang}{cmd:. missings breakdown, sort(missings descending)}{p_end}
{phang}{cmd:. missings breakdown, numeric sort(missings descending)}{p_end}
{phang}{cmd:. missings dropvars frog toad newt, force sysmiss}{p_end}
{phang}{cmd:. missings dropvars toad, force sysmiss}{p_end}
{phang}{cmd:. set obs 30000}{p_end}
{phang}{cmd:. missings dropobs, force}{p_end}

        
{title:Stored results} 

{pstd}
{cmd:missings} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 18 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations checked (all){p_end}
{synopt:{cmd:r(n_dropped)}}number of observations dropped ({cmd:missings dropobs}){p_end}

{p2col 5 16 18 2: Macros}{p_end}
{synopt:{cmd:r(varlist)}}varlist used ({cmd:missings report}, {cmd:missings breakdown}, 
{cmd:missings list}, {cmd:missings table}, and {cmd:missings dropvars}){p_end}
{p2colreset}{...}


{title:Author}

{pstd}Nicholas J. Cox, Durham University, Durham, UK{p_end}
{pstd}n.j.cox@durham.ac.uk{p_end}


{title:Acknowledgments} 

{pstd}
Jeroen Weesie, Eric Uslaner, and Estie Sid Hudes contributed to the
earlier development of {cmd:nmissing} and {cmd:dropmiss}. 

{pstd}
A question from Fahim Ahmad on Statalist prompted the addition of sorting
and {opt show(#)} options to {cmd:missings report}.  A question from
Martyn Sherriff on Statalist prompted the addition of the {cmd:identify()}
option. Discussion with Richard Goldstein led to clarification of the 
scope of {cmd:identify()}. A question from J{c o/}rgen Carling on Statalist 
led to adding {cmd:missings breakdown}. 


{title:References} 

{phang}
Cox, N. J. 1999.
{browse "http://www.stata.com/products/stb/journals/stb49.pdf":dm67: Numbers of missing and present values.}
{it:Stata Technical Bulletin} 49: 7-8.
Reprinted in {it:Stata Technical Bulletin Reprints}, vol. 9, pp. 26-27.
College Station, TX: Stata Press.

{phang}
------. 2001a.
{browse "http://www.stata.com/products/stb/journals/stb60.pdf":dm67.1: Enhancements to numbers of missing and present values}.
{it:Stata Technical Bulletin} 60: 2-3.
Reprinted in {it:Stata Technical Bulletin Reprints}, vol. 10, pp. 7-9.
College Station, TX: Stata Press.

{phang}
------. 2001b.
{browse "http://www.stata.com/products/stb/journals/stb60.pdf":dm89: Dropping variables or observations with missing values}.
{it:Stata Technical Bulletin} 60: 7-8.
Reprinted in {it:Stata Technical Bulletin Reprints}, vol. 10, pp. 44-46.
College Station, TX: Stata Press.

{phang}
------. 2003. Software Updates:
{browse "http://www.stata-journal.com/sjpdf.html?articlenum=up0005":dm67_2: Numbers of missing and present values}.
{it:Stata Journal} 3: 449.

{phang}
------. 2005.
{browse "http://www.stata-journal.com/sjpdf.html?articlenum=up0013":Software Updates: dm67_3: Numbers of missing and present values}.
{it:Stata Journal} 5: 607.

{phang}
------. 2008. Software Updates:
{browse "http://www.stata-journal.com/sjpdf.html?articlenum=up0023":dm89_1: Dropping variables or observations with missing values}.
{it:Stata Journal} 8: 594.


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 17, number 3: {browse "http://www.stata-journal.com/article.html?article=up0056":dm0085_1},{break}
                    {it:Stata Journal}, volume 15, number 4: {browse "http://www.stata-journal.com/article.html?article=dm0085":dm0085}{p_end}

{p 7 14 2}Help:  {helpb missing:[U] 12.2.1 Missing values},
{manhelp codebook D}, {manhelp egen D}, {manhelp ipolate D}
{manhelp misstable R}, {manhelp mvencode D}, {manhelp recode D},
{manhelp mi MI:intro},{break}
{helpb findname} (if installed), {helpb mipolate} (if installed){p_end}
