
clear all

*\Set working directory
log using "$log/Table2_nursinghome.log", replace

*\ Import datasets- 2016 Biennial and Longitudinal
*1. Read in the 2016 Rand Biennial Data and select five variables
use ph115 ph124 ph130 ph004 hhidpn using "$data/h16f2a.dta", clear
tempfile 2016biennial
save `2016biennial'
*2. Load Rand HRS Longitudinal File 2016 and subset to only include wave13
use inw13 r13agey_e r13nhmliv r13walkr r13dress r13bath r13eat r13bed r13toilt ///
r13phone r13money r13meds r13shop r13meals hhidpn r13wtrespe using "$data/randhrs1992_2016v2.dta",clear
keep if inw13==1
tempfile 2016longitudinal
save `2016longitudinal'
*3. Merge two datasets
use `2016longitudinal', clear
merge 1:1 hhidpn using `2016biennial',gen (merge_1)
distinct hhidpn 
*4. Sample restrictions
keep if r13agey_e>=65

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
*** Continuing Care Retirement Community = Meals Yes, ADL HELP Yes, Nursing Yes, RENT or Own (What about fee?)
gen CCRC = 0 
replace CCRC = 1 if Meals ==1 & ADLHELP ==1 & NURSINGHELP ==1
tab CCRC,m 
*** Combine three above because frequencies are so low for them separately
gen FC_COMBO = 0
replace FC_COMBO = 1 if CCRC ==1 | AL ==1 | IL ==1 

*\ Identify people who are currently living in a nursing home
tab r13nhmliv CCRC, m
keep if r13nhmliv == 1 & CCRC!=1 & FC_COMBO==0
tab r13nhmliv CCRC, m //396 obs remain.
*** Save as a tempfile
tempfile nursinghome
save `nursinghome'

clear all
*\ Import dataset- HRS 2016 core helper file
infile using "$data/H16G_HP.dct", using("$data/H16G_HP.da")
*1. Gen hhidpn using HHID and PN
gen hhidpn = HHID+PN
listsome hhidpn
codebook hhidpn
destring hhidpn, replace
*2. Make 6 relationship categories from dozens of options for helper relationships
gen rel_cat = 0
replace rel_cat = 1 if inlist(PG069,21,22,23,24,25) //Professional
replace rel_cat = 2 if inlist(PG069,2,26,27) //Spouse/Partner
replace rel_cat = 3 if inlist(PG069,3,8) //Son/Daughter in Law
replace rel_cat = 4 if inlist(PG069,5,6) //Daughter/Son in law
replace rel_cat = 5 if inlist(PG069,4,7,9,10,11,12,13,14,15,16,17,18,19,28,30,31,33,90,91)
replace rel_cat = 6 if inlist(PG069,20,32,34,98)
replace rel_cat = 99 if PG069 == 98 //0 represents self
tab rel_cat, m
*3. Informal helpers
gen Informal = 0
replace Informal = 1 if PG076 == 5 & inlist(rel_cat,1,6,99)
replace Informal = 1 if inlist(rel_cat,2,3,4,5)
tab Informal,m
*4. Keep if Informal equals to 1
keep if Informal == 1
distinct hhidpn //5,256 obs, 3131 distinct obs.
duplicates r
bys hhidpn: gen dup = cond(_N==1,0,_n)
tab dup,m
drop if dup>1
distinct hhidpn //3131 obs, good.
*5. Save as a temp file
tempfile helper
save `helper'
*6. Merge with the NursingHome
use `nursinghome',clear
merge m:1 hhidpn using `helper', gen(merge_2)
*7. Drop if merge_2 (unmatched from using)
drop if merge_2==2
*8. Save as a temp file
tempfile FinalData
save `FinalData'
*9. Informal var: give NA a numeric number 0
tab Informal, m
replace Informal = 0 if mi(Informal)
tab Informal, m


****************************************************************************************************
***Table 2- Nursing Home***
***************************
*\ Mobility
*\ Diff-Walk
tab r13walkr, m nolab
***A. AMONG ALL SAMPLE POP
*1. Identify people having diff
gen walkdiff = 99
replace walkdiff = 1 if inlist(r13walkr,1,2,9)
replace walkdiff = 0 if r13walkr ==0
tab walkdiff, m
*2. % of people who need help
tab walkdiff,m
tab walkdiff[aweight=r13wtrespe],m
*3. Identify people having diff received informal help
gen walkdiffinformal = 0
replace walkdiffinformal = 1 if walkdiff ==1 & Informal ==1
replace walkdiffinformal = 99 if walkdiff ==99
tab walkdiffinformal, m
*4. % of people who need help and received informal help
tab walkdiffinformal, m
tab walkdiffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if walkdiff ==1
tab walkdiffinformal, m
tab walkdiffinformal[aweight=r13wtrespe], m
restore

**************************************************************
*\ Diff-Bed
tab r13bed, m nolab
***A. AMONG ALL SAMPLE POP
*1. Identify people having diff
gen beddiff = 99
replace beddiff = 1 if inlist(r13bed,1,2,9)
replace beddiff = 0 if r13bed ==0
tab beddiff, m
*2. % of people who need help
tab beddiff,m
tab beddiff[aweight=r13wtrespe],m
*3. Identify people having diff received informal help
gen beddiffinformal = 0
replace beddiffinformal = 1 if beddiff ==1 & Informal ==1
replace beddiffinformal = 99 if beddiff ==99
tab beddiffinformal, m
*4. % of people who need help and received informal help
tab beddiffinformal, m
tab beddiffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if beddiff ==1
tab beddiffinformal, m
tab beddiffinformal[aweight=r13wtrespe], m
restore

**************************************************************
*\ Mobility
***A. AMONG ALL SAMPLE POP
*1. Identify people having mobility diff
tablist walkdiff beddiff
gen mobilitydiff = 99
replace mobilitydiff = 1 if walkdiff ==1 | beddiff ==1
replace mobilitydiff = 0 if walkdiff ==0 & beddiff ==0
tab mobilitydiff, m
*2. % of people who need mobility help
tab mobilitydiff,m
tab mobilitydiff[aweight=r13wtrespe],m
*3. Identify people having mobility diff received informal help
gen mobilityiffinformal = 0
replace mobilityiffinformal = 1 if mobilitydiff ==1 & Informal ==1
replace mobilityiffinformal = 99 if mobilitydiff ==99
tab mobilityiffinformal, m
*4. % of people who need help and received informal help
tab mobilityiffinformal, m
tab mobilityiffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if mobilitydiff ==1
tab mobilityiffinformal, m
tab mobilityiffinformal[aweight=r13wtrespe], m
restore


**************************************************************
**************************************************************
**************************************************************
*\ Self-Care
*\ Diff-Eat 
tab r13eat, m nolab
***A. AMONG ALL SAMPLE POP
*1. Identify people having diff
gen eatdiff = 99
replace eatdiff = 1 if inlist(r13eat,1,2,9)
replace eatdiff = 0 if r13eat ==0
tab eatdiff, m
*2. % of people who need help
tab eatdiff,m
tab eatdiff[aweight=r13wtrespe],m
*3. Identify people having diff received informal help
gen eatdiffinformal = 0
replace eatdiffinformal = 1 if eatdiff ==1 & Informal ==1
replace eatdiffinformal = 99 if eatdiff ==99
tab eatdiffinformal, m
*4. % of people who need help and received informal help
tab eatdiffinformal, m
tab eatdiffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if eatdiff ==1
tab eatdiffinformal, m
tab eatdiffinformal[aweight=r13wtrespe], m
restore

**************************************************************
*\ Diff-Bath
tab r13bath, m nolab
***A. AMONG ALL SAMPLE POP
*1. Identify people having bath diff
gen bathdiff = 99
replace bathdiff = 1 if inlist(r13bath,1,2,9)
replace bathdiff = 0 if r13bath ==0
tab bathdiff, m
*2. % of people who need help
tab bathdiff,m
tab bathdiff[aweight=r13wtrespe],m
*3. Identify people having diff received informal help
gen bathdiffinformal = 0
replace bathdiffinformal = 1 if bathdiff ==1 & Informal ==1
replace bathdiffinformal = 99 if bathdiff ==99
tab bathdiffinformal, m
*4. % of people who need help and received informal help
tab bathdiffinformal, m
tab bathdiffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if bathdiff ==1
tab bathdiffinformal, m
tab bathdiffinformal[aweight=r13wtrespe], m
restore

**************************************************************
*\ Diff-Toilt
tab r13toilt, m nolab
***A. AMONG ALL SAMPLE POP
*1. Identify people having diff
gen toiltdiff = 99
replace toiltdiff = 1 if inlist(r13toilt,1,2,9)
replace toiltdiff = 0 if r13toilt ==0
tab toiltdiff, m
*2. % of people who need help
tab toiltdiff,m
tab toiltdiff[aweight=r13wtrespe],m
*3. Identify people having diff received informal help
gen toiltdiffinformal = 0
replace toiltdiffinformal = 1 if toiltdiff ==1 & Informal ==1
replace toiltdiffinformal = 99 if toiltdiff ==99
tab toiltdiffinformal, m
*4. % of people who need help and received informal help
tab toiltdiffinformal, m
tab toiltdiffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if toiltdiff ==1
tab toiltdiffinformal, m
tab toiltdiffinformal[aweight=r13wtrespe], m
restore

**************************************************************
*\ Diff-Dress
tab r13dress, m nolab
***A. AMONG ALL SAMPLE POP
*1. Identify people having diff
gen dressdiff = 99
replace dressdiff = 1 if inlist(r13dress,1,2,9)
replace dressdiff = 0 if r13dress ==0
tab dressdiff, m
*2. % of people who need help
tab dressdiff,m
tab dressdiff[aweight=r13wtrespe],m
*3. Identify people having diff received informal help
gen dressdiffinformal = 0
replace dressdiffinformal = 1 if dressdiff ==1 & Informal ==1
replace dressdiffinformal = 99 if dressdiff ==99
tab dressdiffinformal, m
*4. % of people who need help and received informal help
tab dressdiffinformal, m
tab dressdiffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if dressdiff ==1
tab dressdiffinformal, m
tab dressdiffinformal[aweight=r13wtrespe], m
restore

**************************************************************
*\ SELF-CARE
***A. AMONG ALL SAMPLE POP
*1. Identify people having self-care diff
tablist eatdiff bathdiff toiltdiff dressdiff
gen selfcarediff = 99
replace selfcarediff = 1 if eatdiff ==1 | bathdiff ==1 | toiltdiff==1 | dressdiff==1
replace selfcarediff = 0 if eatdiff ==0 & bathdiff ==0 & toiltdiff==0 & dressdiff==0
tab selfcarediff, m
*2. % of people who need self-care help
tab selfcarediff,m
tab selfcarediff[aweight=r13wtrespe],m
*3. Identify people having self-care diff received informal help
gen selfcarediffinformal = 0
replace selfcarediffinformal = 1 if selfcarediff ==1 & Informal ==1
replace selfcarediffinformal = 99 if selfcarediff ==99
tab selfcarediffinformal, m
*4. % of people who need help and received informal help
tab selfcarediffinformal, m
tab selfcarediffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if selfcarediff ==1
tab selfcarediffinformal, m
tab selfcarediffinformal[aweight=r13wtrespe], m
restore

**************************************************************
**************************************************************
**************************************************************
*\ Household Acticity
*\ Diff-Shop
tab r13shop, m nolab
***A. AMONG ALL SAMPLE POP
*1. Identify people having diff
gen shopdiff = 99
replace shopdiff = 1 if inlist(r13shop,1,2,9)
replace shopdiff = 0 if r13shop ==0
tab shopdiff, m
*2. % of people who need help
tab shopdiff,m
tab shopdiff[aweight=r13wtrespe],m
*3. Identify people having diff received informal help
gen shopdiffinformal = 0
replace shopdiffinformal = 1 if shopdiff ==1 & Informal ==1
replace shopdiffinformal = 99 if shopdiff ==99
tab shopdiffinformal, m
*4. % of people who need help and received informal help
tab shopdiffinformal, m
tab shopdiffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if shopdiff ==1
tab shopdiffinformal, m
tab shopdiffinformal[aweight=r13wtrespe], m
restore


**************************************************************
*\ Diff-Hotmeal
tab r13meals, m nolab
***A. AMONG ALL SAMPLE POP
*1. Identify people having meal diff
gen mealdiff = 99
replace mealdiff = 1 if inlist(r13meals,1,2,9)
replace mealdiff = 0 if r13meals ==0
tab mealdiff, m
*2. % of people who need help
tab mealdiff,m
tab mealdiff[aweight=r13wtrespe],m
*3. Identify people having meal diff received informal help
gen mealdiffinformal = 0
replace mealdiffinformal = 1 if mealdiff ==1 & Informal ==1
replace mealdiffinformal = 99 if mealdiff ==99
tab mealdiffinformal, m
*4. % of people who need help and received informal help
tab mealdiffinformal, m
tab mealdiffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if mealdiff ==1
tab mealdiffinformal, m
tab mealdiffinformal[aweight=r13wtrespe], m
restore

**************************************************************
*\ Diff-Handle Money
tab r13money, m nolab
***A. AMONG ALL SAMPLE POP
*1. Identify people having diff
gen moneydiff = 99
replace moneydiff = 1 if inlist(r13money,1,2,9)
replace moneydiff = 0 if r13money ==0
tab moneydiff, m
*2. % of people who need help
tab moneydiff,m
tab moneydiff[aweight=r13wtrespe],m
*3. Identify people having diff received informal help
gen moneydiffinformal = 0
replace moneydiffinformal = 1 if moneydiff ==1 & Informal ==1
replace moneydiffinformal = 99 if moneydiff ==99
tab moneydiffinformal, m
*4. % of people who need help and received informal help
tab moneydiffinformal, m
tab moneydiffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if moneydiff ==1
tab moneydiffinformal, m
tab moneydiffinformal[aweight=r13wtrespe], m
restore


**************************************************************
*\ Diff-Phone Call
tab r13phone, m nolab
***A. AMONG ALL SAMPLE POP
*1. Identify people having diff making phone call
gen phoncalldiff = 99
replace phoncalldiff = 1 if inlist(r13phone,1,2,9)
replace phoncalldiff = 0 if r13phone ==0
tab phoncalldiff, m
*2. % of people who need help
tab phoncalldiff,m
tab phoncalldiff[aweight=r13wtrespe],m
*3. Identify people having diff received informal help
gen phoncalldiffinformal = 0
replace phoncalldiffinformal = 1 if phoncalldiff ==1 & Informal ==1
replace phoncalldiffinformal = 99 if phoncalldiff ==99
tab phoncalldiffinformal, m
*4. % of people who need help and received informal help
tab phoncalldiffinformal, m
tab phoncalldiffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if phoncalldiff ==1
tab phoncalldiffinformal, m
tab phoncalldiffinformal[aweight=r13wtrespe], m
restore

**************************************************************
*\ HOUSEHOLD ACTIVITY
***A. AMONG ALL SAMPLE POP
*1. Identify people having diff doing household acticities
tablist shopdiff mealdiff moneydiff phoncalldiff
gen householddiff = 99
replace householddiff = 1 if shopdiff ==1 | mealdiff ==1 | moneydiff==1 | phoncalldiff==1
replace householddiff = 0 if shopdiff ==0 & mealdiff ==0 & moneydiff==0 & phoncalldiff==0
tab householddiff, m
*2. % of people who need household help
tab householddiff,m
tab householddiff[aweight=r13wtrespe],m
*3. Identify people having household diff received informal help
gen householddiffinformal = 0
replace householddiffinformal = 1 if householddiff ==1 & Informal ==1
replace householddiffinformal = 99 if householddiff ==99
tab householddiffinformal, m
*4. % of people who need help and received informal help
tab householddiffinformal, m
tab householddiffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if householddiff ==1
tab householddiffinformal, m
tab householddiffinformal[aweight=r13wtrespe], m
restore


**************************************************************
**************************************************************
**************************************************************
*\ Medicare
tab r13meds, m nolab
***A. AMONG ALL SAMPLE POP
*1. Identify people having diff taking madications
gen medsdiff = 99
replace medsdiff = 1 if inlist(r13meds,1,2,9)
replace medsdiff = 0 if r13meds ==0
tab medsdiff, m
*2. % of people who need help
tab medsdiff,m
tab medsdiff[aweight=r13wtrespe],m
*3. Identify people having diff received informal help
gen medsdiffinformal = 0
replace medsdiffinformal = 1 if medsdiff ==1 & Informal ==1
replace medsdiffinformal = 99 if medsdiff ==99
tab medsdiffinformal, m
*4. % of people who need help and received informal help
tab medsdiffinformal, m
tab medsdiffinformal[aweight=r13wtrespe], m

***B.AMONG PEOPLE WHO NEED HELP
preserve
keep if medsdiff ==1
tab medsdiffinformal, m
tab medsdiffinformal[aweight=r13wtrespe], m
restore


capture log close








































