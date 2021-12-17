

clear all

*\Set working directory
log using "$log/descriptive_analysis.log", replace

*\Import datasets
*1. Read in Rand HRS Longitudinal File 2016
use "$data/randhrs1992_2016v2.dta", clear
*2. Subset Rand HRS Longitudinal File 2016 to only include wave 13
keep if inw13 == 1
distinct hhidpn //20,912 unique observations
tempfile temp2016
sa `temp2016'
*3. Merge with the 2016 Rand Biennial Data
use "$data/h16f2a.dta", clear
distinct hhidpn //20,912 unique observations
merge 1:1 hhidpn using `temp2016',gen (merge_1)
//all matched, good.

*\ Define Sample: people aged 65 and above
tab r13agey_e, m //no missing, good.
rename r13agey_e age
keep if age >= 65
tab age, m //9,994 observations remain. 

*\ Generate Vars
*1. Rename vars
*** Rename PH115 (Group Meals) as Meals 
tab ph115, m nolab 
rename ph115 Meals
*** Rename PH124 as ADLHELP
tab ph124, m nolab 
rename ph124 ADLHELP 
*** Rename PH130 as NURSINGHELP
tab ph130, m nolab 
rename ph130 NURSINGHELP
*** Rename PH004 as LTCRENT
tab ph004, m nolab 
rename ph004 LTCRENT

*2. Formal Rensidential LTC Care
*** Independent Living = Meals Yes, ADL HELP No, Nursing No, RENT Yes;
gen IL = 0
replace IL = 1 if Meals ==1 & ADLHELP ==5 & NURSINGHELP ==5 & LTCRENT ==2
tab IL, m 
*** Assisted Living = Meals Yes, ADL HELP Yes, Nursing No, RENT Yes;
gen AL = 0
replace AL = 1 if Meals ==1 & ADLHELP == 1 & NURSINGHELP ==5 & LTCRENT == 2
tab AL, m
*** Continuing Care Retirement Community = Meals Yes, ADL HELP Yes, Nursing Yes, RENT or Own 
gen CCRC = 0 
replace CCRC = 1 if Meals ==1 & ADLHELP ==1 & NURSINGHELP ==1
tab CCRC,m 
*** Combine three above because frequencies are so low for them separately
gen FC_COMBO = 0
replace FC_COMBO = 1 if CCRC ==1 | AL ==1 | IL ==1 

*** Save it as a tempfile
tempfile hrs2016
save `hrs2016'

*\ Identify people who are currently living in a care facility
keep if FC_COMBO ==1
tab FC_COMBO, m //186 observations 
*** Save as a tempfile
tempfile rensidentialfacility
save `rensidentialfacility'

*\ Identify people who are currently living in a nursing home
use `hrs2016', clear
tab r13nhmliv CCRC, m
keep if r13nhmliv == 1 & CCRC!=1 & FC_COMBO==0
tab r13nhmliv CCRC, m //396 observations 
*** Save as a tempfile
tempfile nursinghome
save `nursinghome'

*\ Identify people who are community-dwelling
use `hrs2016', clear
gen nursinghome = 0
replace nursinghome = 1 if r13nhmliv == 1 & CCRC!=1 & FC_COMBO==0
tab nursinghome, m
drop if FC_COMBO==1
drop if nursinghome ==1 
distinct hhidpn
*** Save as a tempfile
tempfile community_dwelling
save `community_dwelling'

**********************************************************************
*  Table 1- Community Dwelling *
**********************************************************************
*\ Read in dataset
use `community_dwelling', clear

*\ Age
***raw mean
summarize age 
summarize age [aweight=r13wtrespe]

*\ Gender
rename ragender gender
tab gender, m 
tab gender[aweight=r13wtrespe], m

*\ Race and Ethnicity
tablist raracem rahispan, nolab
gen Race_Ethinic = 0
replace Race_Ethinic=1 if raracem == 1 & rahispan == 0 //non-hispanic white
replace Race_Ethinic=2 if raracem == 2 & rahispan == 0 //non-hispanic black
replace Race_Ethinic=3 if raracem == 3 & rahispan == 0 //non-hispanic other
replace Race_Ethinic=4 if rahispan == 1 //Hispanic-regardless of race
tab Race_Ethinic, m nolab
tab Race_Ethinic[aweight=r13wtrespe], m

*\ Marital Status
gen Marital_Status = 0
replace Marital_Status = 1 if inlist(r13mstat,1,2,3) //Married/Living with partner
replace Marital_Status = 2 if inlist(r13mstat,4,5,7) //Divorced/Separate/Widowed
replace Marital_Status = 3 if r13mstat==8 //Never married
tab Marital_Status, m
tab Marital_Status[aweight=r13wtrespe], m

*\ Self-reported health
rename r13shlt selfreportedhealth
tab selfreportedhealth, m nolab
tab selfreportedhealth, m
replace selfreportedhealth = 0 if selfreportedhealth == .r | selfreportedhealth == .d
tab selfreportedhealth, m nolab
tab selfreportedhealth, m
tab selfreportedhealth[aweight=r13wtrespe], m


**********************************************************************
* Table 1- Residential Facility *
**********************************************************************
*\ Read in Residential Facility dataset
use `rensidentialfacility', clear

*\ Age
***raw mean
summarize age 
summarize age [aweight=r13wtrespe]

*\ Gender
rename ragender gender
tab gender, m 
tab gender[aweight=r13wtrespe], m

*\ Race and Ethnicity
tablist raracem rahispan, nolab
gen Race_Ethinic = 0
replace Race_Ethinic=1 if raracem == 1 & rahispan == 0 //non-hispanic white
replace Race_Ethinic=2 if raracem == 2 & rahispan == 0 //non-hispanic black
replace Race_Ethinic=3 if raracem == 3 & rahispan == 0 //non-hispanic other
replace Race_Ethinic=4 if rahispan == 1 //Hispanic-regardless of race
tab Race_Ethinic, m nolab
tab Race_Ethinic[aweight=r13wtrespe], m

*\ Marital Status
gen Marital_Status = 0
replace Marital_Status = 1 if inlist(r13mstat,1,2,3) //Married/Living with partner
replace Marital_Status = 2 if inlist(r13mstat,4,5,7) //Divorced/Separate/Widowed
replace Marital_Status = 3 if r13mstat==8 //Never married
tab Marital_Status, m
tab Marital_Status[aweight=r13wtrespe], m

*\ Self-reported health
rename r13shlt selfreportedhealth
tab selfreportedhealth, m nolab
tab selfreportedhealth, m
replace selfreportedhealth = 0 if selfreportedhealth == .r | selfreportedhealth == .d
tab selfreportedhealth, m nolab
tab selfreportedhealth, m
tab selfreportedhealth[aweight=r13wtrespe], m


**********************************************************************
* Table 1- Nursing Home  *
**********************************************************************
*\ Read in Nursing Home dataset
use `nursinghome', clear

*\ Age
***raw mean
summarize age
summarize age [aweight=r13wtrespe]
egen newvar = wtmean(age), weight(r13wtrespe)

*\ Gender
rename ragender gender
tab gender, m 
tab gender[aweight=r13wtrespe], m

*\ Race and Ethnicity
tablist raracem rahispan, nolab
gen Race_Ethinic = 0
replace Race_Ethinic=1 if raracem == 1 & rahispan == 0 //non-hispanic white
replace Race_Ethinic=2 if raracem == 2 & rahispan == 0 //non-hispanic black
replace Race_Ethinic=3 if raracem == 3 & rahispan == 0 //non-hispanic other
replace Race_Ethinic=4 if rahispan == 1 //Hispanic-regardless of race
tab Race_Ethinic, m nolab
tab Race_Ethinic[aweight=r13wtrespe], m

*\ Marital Status
gen Marital_Status = 0
replace Marital_Status = 1 if inlist(r13mstat,1,2,3) //Married/Living with partner
replace Marital_Status = 2 if inlist(r13mstat,4,5,7) //Divorced/Separate/Widowed
replace Marital_Status = 3 if r13mstat==8 //Never married
tab Marital_Status, m
tab Marital_Status[aweight=r13wtrespe], m

*\ Self-reported health
rename r13shlt selfreportedhealth
tab selfreportedhealth, m nolab
tab selfreportedhealth, m
replace selfreportedhealth = 0 if selfreportedhealth == .r | selfreportedhealth == .d
tab selfreportedhealth, m nolab
tab selfreportedhealth, m
tab selfreportedhealth[aweight=r13wtrespe], m


capture log close


