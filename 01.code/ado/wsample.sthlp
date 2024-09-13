{smcl}
{* *! version 1.0.0  30April2018}{...}
{cmd:help wsample}
{hline}

{title:Title}
{p2colset 5 24 26 2}{...}
{p2col :{cmd:wsample} {hline 1} Creates values or an indicator for a weighted random sample}{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 23 2}

{opt wsample} {var} {ifin} [aw] {cmd:,} 
{opt newvar(newvarname)}
[{opt percent(positive real)}
{opt value(positive real)}
{opt numsim(integer)}
{opt seed(integer)}]

{title:Description}

{pstd}
{cmd:wsample} Draws weighted random samples of the data in memory. It is useful for simulations where specific population targets are to be met. The size of the population to be drawn can be specified as a percentage (percent option) or as a total value (value option). 

The command allows for producing indicators of the desired sample, or may also keep the values for the variable specified in varlist.

{title:Options}

{phang}
{opt newvar(newvarname)} Variable containing the indicator for the sample. If a variable with values is placed in varlist, then the variable produced by the newvar option will have the values to ensure that a certain population has those specified values.

{phang}
{opt percent(positive real)} Specifies that # percent of the weighted sample is desired.

{phang}
{opt value(positive real)} Specifies that # in the weighted sample is desired.

{phang}
{opt numsim(integer)} Specifies that # samples is desired, each will be created in a new variable where the name specified in newvar is used as a prefix.

{phang}
{opt seed(string)} Seed to ensure replicability, one may use Stata's c(rngstate).


{title:Example}
sysuse auto, clear
//Take a 90 percent weighted sample of foreign vehicles
wsample foreign if foreign==1 [aw=weight], percent(90) newvar(myforeign) seed(3894)
//Assume that only 90 percent of all vehicles should have a price, the rest are assigned a price of 0. Get 10 samples.
wsample price [aw=weight], percent(90) newvar(price90) seed(3894) numsim(10)


{title:Author:}

{pstd}
Paul Corral{break}
The World Bank - Poverty and Equity Global Practice {break}
Washington, DC{break}
pcorralrodas@worldbank.org{p_end}


{pstd}
Any error or omission is the author's responsibility alone.





