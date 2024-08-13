# 1 Acquiring hazard, population and vulnerability data

## Population Data:
The indicator uses gridded population data from the Global Human Settlement Layer (GHSL) produced by the Joint Research Centre, European Union (Schiavina, Freire, Alessandra, and MacManus, 2023). The GHS-POP – R2023A dataset depicts the distribution of human population, expressed as the number of people per cell. Resi-dential population estimates at 5-year intervals from 1975 to 2030 are derived from the raw global census data harmonized by CIESIN for the Gridded Population of the World, version 4.11 (GPWv4.11), and disaggregated from census or administrative units to grid cells, informed by the distribution, classification, and volume of built-up as mapped in the GHSL global layers per corresponding epoch. The disaggregation methodology is de-scribed in a peer reviewed paper (Freire et al., 2016). The populations of GHSL are closer to statistical values than alternatives such as WorldPop because the main data source is statistical data and the spatialization meth-od maintains the population in the administrative region (Chen et al. 2020). The GHS-POP – R2023A dataset with a spatial resolution of 3 arcseconds (approximately 90 m) is used for the indicator.

The population is further classified using the GHSL application of the Degree of Urbanisation methodology rec-ommended by the UN Statistical Commission (Schiavina, Melchiorri, and Pesaresi, 2023). The GHS-SMOD – R2023A dataset classifies settlements according to population cluster sizes, population densities and built-up area densities, as defined by the stage I of the Degree of Urbanisation (European Commission & Statistical Of-fice of the European Union, 2021). The GHS-SMOD spatial raster data, classifying each 1km grid cell globally, is used for the indicator.

For some countries, gridded population data is extrapolated from outdated census in GPWv4.11. To maintain consistency with the population used for global poverty monitoring and other statistics, population estimates derived from the gridded data are rescaled to align with country level population data taken from the World Bank’s World Development Indicators (WDI).

## Hazard Data:
The indicator uses gridded hazard datasets to represent four extreme climate-related events. Hazard events are characterized by their intensity and probability of occurrence (or return period). The data are summarized in Table 1 and described in the following section. 

**ADD TABLE**

### Agricultural drought: 
The indicator uses Historic Agricultural Drought Frequency data from the Food and Agriculture Organization of the United Nations (FAO). The data depicts the annual frequency of severe drought events defined using the Agricultural Stress Index (ASI) (FAO, 2023). Unlike other hazard data used for the indicator, these drought maps are not based on a probabilistic modeling approach. The historical frequency of severe droughts is calcu-lated using the entire 39-year time series, spanning from 1984 to 2022. The ASI is based on remote sensing vegetation (NDVI) and land surface temperature (BT4) data, combined with information on agricultural crop-ping cycles derived from historical data and a global crop mask. Specifically, a vegetation health index (VHI) is defined as a weighted combination of deviations of NDVI and BT4 from the historical range of NDVI and BT4. Grid cells with a VHI value below 35% over a growing season are considered as experiencing severe drought. The final ASI value is calculated as the percentage of crop or grassland pixels within each administrative unit (based on the Global Administrative Unit Layers by FAO) affected by severe drought. FAO provides datasets depicting the frequency of severe drought in areas where >30 percent or >50 percent of the cropland or grass-land is affected by severe drought  for two growing seasons, with a spatial resolution of 1 km (approximately 30 arcseconds). 

For the indicator, annual frequencies were directly converted into approximate return periods, such that a lo-cation recording at least one severe drought (as defined by the ASI) between 1984 and 2022 is considered ex-posed to a 39-year return period event. The GHS-SMOD Degree of Urbanisation dataset described above is used to restrict the drought maps to rural areas. The resulting global drought hazard dataset maps rural areas where more than 30 and 50 percent of cropland or grassland were affected in any growing season for approx-imate return periods ranging from 5 to 39 years (based only on historical frequency). Work is ongoing to gen-erate probabilistic estimates of drought using this data.  

### Flood:
The indicator uses modelled pluvial and fluvial flood maps from the 2019 version of the Fathom Global 2.0 flood hazard dataset (Sampson et al., 2015). Fluvial or river floods occur when intense precipitation or snow melt causes rivers to overflow or submersion of land along floodplains. Pluvial or surface water floods are caused by the fast accumulation of heavy rainfall leading to a reduction in soil absorbing capacity or saturation of drainage infrastructures. The Fathom datasets depict the maximum inundation depth of fluvial and pluvial floods at a resolution of 3 arcseconds (approximately 90 m) for return periods ranging from 5 to 1,000 years. The unde-fended fluvial flood data is used for the indicator. While Fathom provides a defended option for fluvial flooding, it uses GDP as a proxy to set defense standards rather than the actual presence of flood defense structure. Alt-hough the use of the undefended flood maps may lead to an overestimation of exposure in areas with flood protection systems, there is evidence that many low and middle-income countries do not have effective flood protection systems (Hallegatte et al., 2017; Rozenberg and Fay, 2019; Rentschler, Salhab, and Jafino, 2022). The Fathom data have global coverage between 56°S and 60°N. 

Since the Fathom Global 2.0 flood hazard dataset does not represent coastal flooding, a separate coastal flood dataset produced by Deltares (2021) is used. Coastal flooding is modelled at the same 3 arcsecond spatial reso-lution and using the same digital elevation model (MERIT DEM) as Fathom 2.0 but is forced by tide and storm surges (e.g. during a tropical cyclone). The water level at the coastline is extended landwards to all areas that are hydrodynamically connected to the coast following a ‘bathtub’ like approach and calculates the flood depth as the difference between the water level and the topography. The model attenuates the water level over land simulating the dampening of the flood levels due to the roughness over land. The Deltares dataset depicts the maximum depth of coastal flooding for return periods ranging from 0 to 250 years, with global coverage. The MERIT DEM version of the dataset with a spatial resolution of 3 arcseconds is used.

The Fathom flood maps for 231 countries or regions were merged to produce global fluvial and pluvial maps for each return period, aligning with the global coastal flood maps. Finally, a combined global flood hazard map was created for return periods ranging from 5 to 100 years by taking the maximum inundation depth of any flood type, following Rentschler, Salhab, and Jafino (2022). This will be updated in the coming year to Fathom 3.0. 

### Heatwave:
The indicator uses modelled 5-day heatwave maps prepared by the World Bank Climate Change Knowledge Portal (CCKP). The probabilistic dataset depicts the maximum 5-day average of the daily maximum Environ-mental Stress Index (ESI) at a resolution of 0.25 degrees (approximately 30 km) for return periods ranging between 5 and 100 years. The ESI is an approximation for the Wet Bulb Globe Temperature (WBGT), derived from temperature, relative humidity and solar radiation (Moran et al., 2001). ESI is calculated using an adjust-ed formula including a factor that corrects systematic underestimation from solar radiation (Kong and Huber, 2022). Each daily maximum value was derived from hourly ERA5 climate reanalysis data. The maximum aver-age of 5 consecutive days was calculated for each year from 1950-2022, detrended and the values fit to gener-alized extreme value distributions (GEV) to estimate return levels for a 5-day heatwave event. Work is ongoing to determine whether a more spatially disaggregated measure of heat can be used. 

### Tropical cyclone:
The indicator uses global modelled tropical cyclone maps from Bloemendaal, Haigh, de Moel et al. (2020). The tropical cyclone dataset is generated using a synthetic resampling algorithm called STORM (Synthetic Tropical cyclOne geneRation Model). STORM is applied to 38 years of historical cyclone track data from the Interna-tional Best Track Archive for Climate Stewardship (IBTrACS) to statistically extend the dataset to 10,000 years of cyclone activity. The dataset covers all tropical cyclone basins except the South Atlantic which was left out as there are too few historical cyclone formations in this basin for adequate distribution and relationships fitting. Results were validated against historical observations and previous studies (Bloemendaal, de Moel, Muis et al., 2020). The STORM wind speed dataset depicts the maximum 10-minute average sustained wind speed at a resolution of 0.1 degrees (approximately 11km) for return periods ranging from 10 to 10,000 years. Although wind speed does not reflect storm surge and heavy precipitation generally associated with cyclones, these di-mensions are considered in the modelled flood maps and therefore not necessarily excluded from the multi-hazard analysis. 

## Hazard thresholds:
Defining the population exposed to climate-related hazards requires specifying an intensity threshold and re-turn period for each type of event. The first threshold specifies an intensity (in physical units) which must be exceeded for a particular location to be considered exposed. The return period specifies a minimum frequency of above threshold events for a location to be considered exposed. The intensity threshold helps to focus the indicator on the population exposed to events that have the potential to cause significant impacts, conditional on the vulnerability of the exposed population. The return period focuses the indicator on exposure to events that are relatively likely to occur.

Table 2 lists the intensity thresholds used to define the exposed population. In all cases the return period used is 100 years, so as to include people that have a greater than 50 percent chance of experiencing the shock de-scribed in their lifetime (using average global life expectancy). In the case of drought, the return period is as high as is possible (39 years) given historical data rather than a modelled approach is used to define the proba-bility.


**ADD TABLE**

The intensity of the events has been defined to represent a severe event for each type of event considered. Given some events primarily affect lives, some productivity, and some assets, it is hard to choose equally se-vere thresholds in a meaningful way across contexts. The approach taken is to take events that are counted as severe in each dimension in the literature that measures these events.  In the case of drought, the cutoff used is that defined as a severe drought by the FAO. In the case of flood, inundation depths of at least 50 cm indicate a high risk that bring disruptions to livelihoods and economic activity, as well as risk to life for select locations and vulnerable groups (Rentschler, Salhab, and Jafino, 2022). For a fluvial and marine flood depth of 0.5 me-ters, Huizinga, De Moel, and Szewczyk (2017) estimate the average share of residential assets lost ranges from 0.22 to 0.49. Cyclone damage functions also indicate direct economic damage in the range of 0.2-0.5 for category 2 windspeeds for most regions (Eberenz, Lüthi, and Bresch, 2021) and this is the cutoff used for cy-clones. A WBGT threshold of 33 degrees Celsius corresponds with the reference upper limit for healthy, accli-matized humans at rest to keep a normal core temperature, based on international standard ISO 7243 used to assess heat stress on workers (International Organization for Standardization, 2017). Heat-related mortality and hospital visits increase significantly around this level.

## Vulnerability Data:
The indicator uses seven datasets that capture vulnerability dimensions, summarized in Table 3 below and elaborated upon in the following section.

**ADD TABLE**

### Income: 
The first dimension of inability to cope is not having income to manage the impact of shocks. The aim of this measure is to identify individuals that have incomes that are too low to be able to meet basic needs should a shock to incomes occur. Estimates of the share of households that have income or consumption less than the poverty line of $2.15 (2017 PPP) for each administrative unit are obtained from the Global Subnational Atlas of Poverty (GSAP). These subnational estimates are representative for each household survey used in the GSAP. These household surveys come from the Global Monitoring Database (GMD), which are collated and harmo-nized across countries and over time to maximize comparability. The GMD country data contains the income or consumption aggregate used for poverty monitoring and other data on household characteristics such as ac-cess to improved water, access to electricity, and education of adult household members, all of which are used in this methodology. 

The income and consumption data are further extrapolated or interpolated to a common reference year (e.g., 2021), and the share of the population falling beneath the international poverty lines in this reference year—or any other line—can be determined. The extrapolation or interpolation method is the same one used in the World Bank’s Poverty and Inequality Platform (PIP), thus assuring country level estimates match. 

### Education: 
The second dimension of inability to cope is educational attainment. This measure captures both a household’s ability to understand and respond to risk information such as weather forecasts and early warnings, as well as their ability to switch livelihoods when facing climate-related shocks. This dimension is measured by a variable reflecting whether the household has an adult that has completed primary education. This is a very low level of education that is likely mostly relevant in lower income countries. Education data are taken from the GMD. There are some countries that are missing data on education but have achieved near universal coverage for at least primary education attainment; for these countries, it is assumed that no household is vulnerable on the education dimension.  Universal coverage is defined as at least 97 percent of the adult population having com-pleted primary education or higher using data from UNESCO Institute for Statistics (UIS), SDG indicator 4.4.3. For additional countries that are missing education data, data from UNESCO UIS are again used to fuse with GMD.  The UNESCO data are reported at the urban/rural level and are based on national population censuses and household and labor force surveys. 

### Social Protection:
The third dimension of inability to cope is access to public support, or social protection. There is considerable evidence that cash transfers help households to manage shocks.  For this dimension, households are identified as highly vulnerable if they neither receive social transfers nor contribute to social insurance.  The data draws from The Atlas for Social Protection (ASPIRE) database, estimated using both household surveys and adminis-trative data. For countries that are missing data from ASPIRE, most notably high-income countries outside of the World Bank’s client countries, a broad assumption is made that OECD countries have near universal (i.e. greater than 97 percent) rates of coverage (when considered as both those receiving payouts and contrib-uting). 

### Financial Inclusion: 
The final dimension of the ability to cope is access to financial services.  There is a strong body of evidence showing that households borrow after a disaster to meet basic consumption needs, and transfers of money between family and friends in the aftermath of a disaster are also central to household risk management.  Ac-cess to a bank account is used to indicate whether households have access to financial services to smooth con-sumption in the face of a shock. Data are derived from the Global Financial Inclusion (Global Findex) database, using the variable that indicates whether a respondent has either a financial institution account or a mobile money account. 

### Water: 
The first dimension of physical propensity to experience severe losses is access to a certain standard of drinking water. When shocks hit, access to improved drinking water can protect households from contaminated water from flooding and storms, as well as lessen the impact of droughts. Estimates on whether households have access to at least limited standard water (or, improved water sources) is obtained from the Global Monitoring Database (GMD).  There are some countries that are missing data on water access but that have achieved uni-versal access to at least improved drinking water; for these countries, it is assumed that no household is vul-nerable on the water dimension.  Universal coverage is defined as at least 97 percent of the population having access to improved water using data from WHO/UNICEF Joint Monitoring Programme (JMP). For additional countries that are missing water data, information from the JMP (subnational and by quintile where possible) is used to fuse with GMD data when GMD data is missing.  The current approach uses access to improved water sources for this dimension given the broad country coverage in the GMD; future work will explore revising this indicator to be access to at least basic drinking water to be aligned with the SDGs.

### Energy: 
The second dimension of physical propensity to experience severe losses is access to electricity.  During shocks such as heatwaves, households with electricity are much more likely to have assets such as fans that can allevi-ate the impact. Estimates on whether a household has access to electricity are obtained from the Global Moni-toring Database. There are some countries that are missing data on electricity access but that have achieved universal coverage; for these countries, it is assumed that no household is vulnerable on the energy dimension.  Universal coverage is defined as at least 97 percent of the population having access to electricity using data from the WDI.  When data is not available in the GMD, data from the World Bank’s Global Electrification Data-base (GED) are used to fuse with GMD. The GED compiles data on access to electricity (SDG indicator 7.1.1) from nationally representative household survey data and occasionally census data, and reports values at the national, urban, and rural levels.

### Transport:
The third dimension of physical propensity to experience severe losses is access to services and markets. Ac-cess to transport networks plays a pivotal role in enhancing resilience, increasing access to health and other services, and ensuring households can access alternate employment opportunities and markets for goods. Accessibility is based on the Rural Access Index (RAI), a Sustainable Development Goal indicator that measures rural accessibility by evaluating access to all-season roads. RAI is defined as the “proportion of the rural popula-tion living within 2km of an all-season road”. This distance is considered reasonable for most economic and so-cial activities, roughly equating to a 20–25-minute walk. The indicator relies on four major geospatial datasets: land use differentiating between rural or urban areas (Global Human Settlement Database and NASA’s Global Rural-Urban Mapping Project data), population distribution (WorldPop), road network extent (Open Street Map, Global Roads Inventory Project Database, and Microsoft BING – Road Detection Project), and the all-season status of roads (based on Transport Research Laboratory Methodology, 2019).  The RAI is calculated following the methodology in the Sustainable Development Report 2023.

## Statistical Boundary Data:
To map survey-based vulnerability indicators, geospatial boundary data corresponding with the representative spatial units in GMD surveys is used. These are the boundaries used in GSAP. The source of boundary data in-cludes the World Bank’s Administrative Boundaries, Database of Global Administrative Areas (GADM), Global Administrative Unit Layers (GAUL), Nomenclature of Territorial Units for Statistics (NUTS) or National Statistical Offices. The final boundaries are verified and approved by the World Bank’s Map Unit. For most of the data-base, surveys are representative at the first administrative level (ADM1) or other subnational statistical regions (areas). For more details, see Nguyen et al. (2023).