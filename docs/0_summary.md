# Summary

This page summarizes the method used to estimate the population at high risk from climate-related hazards Vision Indicator. The methodology adopts a widely used framework to assess risk in the context of climate change impacts. Risk is the potential for adverse consequences. Risks result from interactions between climate-related **hazards** with the **exposure** and **vulnerability** of the affected population to the hazards. 

<p align="center">
  <img width="300" alt="Framework" src="https://github.com/worldbank/counting-people-climate-risk/blob/main/docs/images/framework.png?raw=true">
</p>

The hazard is the potential occurrence of a physical event that may cause welfare impacts. Exposure is the presence of people in places that could be adversely affected. Vulnerability is the propensity or predisposition of these people to be adversely affected, or unable to cope with impacts. 

**People at high risk from climate-related hazards** are defined as those exposed to any hazard and vulnerable on any dimension, based on specific thresholds. 

**Exposure** to four climate-related hazards is considered: 
| Hazard               | Return period  | Intensity threshold defining an exposed location |
|----------------------|----------------|---------------------------------------------------|
| Agricultural drought | 40 years[^1]      | > 30% cropland or pasture affected and rural  |
| Flood                | 100 years     | > 0.5 m inundation depth                          |
| Heatwave             | 100 years      | > 33°C 5-day maximum Environmental Stress Index   |
| Tropical cyclone     | 100 years      | ≥ Category 2 wind speed                           |

[^1]: historical frequency based on 39 years of observations.

**Vulnerability** is assessed on seven dimensions:
| Dimension                      | Threshold defining a vulnerable household                      |
|--------------------------------|----------------------------------------------------------------|
| Income                         | Less than $2.15 (2017 PPP) per person per day                  |
| Education                      | No member has completed primary education                      |
| Access to finance              | No member has a bank or mobile money account                   |
| Access to social protection    | Does not benefit or contribute to a social protection program  |
| Access to drinking water       | No access to improved drinking water                           |
| Access to electricity          | No access to electricity                                       |
| Access to services and markets | More than 2km from an all-season road and rural                |

Five steps to calculate the indicator are summarized below. The following chapters provide more detail.

### Step 1: [Acquiring hazard, population and vulnerability data](1_data)

Data from several sources are required to calculate the indicator. Global gridded spatial data is used to determine who is exposed in [Step 2](2_exposure). These data sets indicate the [number of people](https://worldbank.github.io/counting-people-climate-risk/docs/1_data.html#population-data) living in a given location (grid cell), the [degree of urbanization](https://worldbank.github.io/counting-people-climate-risk/docs/1_data.html#degree-of-urbanization), and the [probability and intensity of each hazard event](1_data#hazard-data) across space. Vulnerability is assessed in [Step 3](3_vulnerability) primarily using data from [household surveys](https://worldbank.github.io/counting-people-climate-risk/docs/1_data.html#vulnerability-data) - the same [surveys used by the World Bank to measure poverty](https://datanalytics.worldbank.org/PIP-Methodology/acquiring.html#selection). Access to services and markets is quantified using gridded [Rural Access Index (RAI) data](https://worldbank.github.io/counting-people-climate-risk/docs/1_data.html#access-to-services-and-markets). Lastly, spatial data mapping the [boundaries of statistical regions represented by surveys](https://worldbank.github.io/counting-people-climate-risk/docs/1_data.html#statistical-boundary-data) is used to merge gridded exposure and survey-based vulnerability estimates in [Step 4](4_risk).

### Step 2: [Determining who is exposed](2_exposure)

The exposed population is estimated by combining global gridded population, degree of urbanization and hazard data. The hazard data is used to identify exposed locations where [specific hazard intensity thresholds](https://worldbank.github.io/counting-people-climate-risk/docs/2_exposure.html#thresholds-defining-exposure) are exceeded. The hazard and degree of urbanization data is [resampled](https://worldbank.github.io/counting-people-climate-risk/docs/2_exposure.html#resampling-spatial-data) so that grid cells align with the high resolution population data (approximately 90 m). Approximately 90 billion population grid cells covering the globe are then [categorized](https://worldbank.github.io/counting-people-climate-risk/docs/2_exposure.html#combining-spatial-data) by exposure to any combination of the four hazards according to thresholds, and by eight degree of urbanization categories. As a result, every location and the global population is assigned to one of 128 possible exposure-urbanization categories at a very fine spatial scale. 

### Step 3: [Determining who is vulnerable](3_vulnerability)

Estimating the share of households vulnerable on any dimension requires "fusing" data since information on all dimensions is not available from the same household survey.  A [simulation method](https://worldbank.github.io/counting-people-climate-risk/docs/3_vulnerability.html#estimating-vulnerability-using-fused-household-surveys) is used to impute indicators derived from other sources, such as access to social protection and finance, into household surveys. The method preserves estimates for each population subgroup reported by other data sources, for example, the share of the poorest rural quintile without access to social protection. The average share of households vulnerable on any dimension across 100 simulations is used to calculate the indicator. 

The share of the population vulnerable on the "access to services and markets" dimension is [derived from gridded RAI data](https://worldbank.github.io/counting-people-climate-risk/docs/3_vulnerability.html#estimating-vulnerability-using-spatial-data) for each exposure category defined in [Step 2](2_exposure). This dimension is incorporated into the [calculation](https://worldbank.github.io/counting-people-climate-risk/docs/4_risk.html#calculating-the-risk-indicator) of the final indicator in [Step 4](4_risk).

### Step 4: [Determining who is at risk](4_risk)
To determine who is at risk, the exposure estimates from [Step 2](2_exposure) are aggregated to the same level as the representative survey-based vulnerability estimates from [Step 3](3_vulnerability). This involves (1) [aggregating](https://worldbank.github.io/counting-people-climate-risk/docs/4_risk.html#aggregating-exposure-estimates-to-survey-statistical-regions) the population in each exposure category to survey statistical regions; and (2) [aligning rural and urban classifications](https://worldbank.github.io/counting-people-climate-risk/docs/4_risk.html#aligning-rural-and-urban-classifications). With the exposure data aggregated to the same geographic and rural/urban population units as the vulnerability data, the population exposed to any hazard and vulnerable on any dimension is [calculated](https://worldbank.github.io/counting-people-climate-risk/docs/4_risk.html#calculating-the-risk-indicator).

### Step 5: [Calculating global and regional aggregates](5_aggregates)
Global and regional population weighted aggregates are calculated from the sample of countries with [sufficiently recent data on all vulnerability dimensions](https://worldbank.github.io/counting-people-climate-risk/docs/5_aggregates.html#sample-selection). For reporting the 2021 global indicator, this includes 103 countries accounting for 86 percent of the population. Aggregates are reported [when population coverage is sufficient](https://worldbank.github.io/counting-people-climate-risk/docs/5_aggregates.html#coverage-rule).


### Limitations
The data and methodology have important limitations. Data availability limits country coverage and means the indicator is reported with a lag. The methodology has limitations related to the: [selection of thresholds](), [focus on direct exposure](), [fusing of vulnerability data from different sources](), and [assuming uniform vulnerability rates]() within population units represented by surveys. These are [discussed in more detail](limitations). Quantifying the risk to people from climate-related hazards is complex, and the current methodology is a first step. It will be improved over time to better address limitations.
