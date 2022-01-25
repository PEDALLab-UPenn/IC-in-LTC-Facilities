
*********************************************************************
*	This file creates summary statistics for IC in LTC project   *	
*                                                                   *
*       - Code written by CS                                        *
*********************************************************************

clear all

foreach sample in nursinghome communitydwelling {
	
	capture log close
	log using "$log/`sample'_table2.log", replace
	
	use "$data/`sample'", clear

 	***************
        * 1. Mobility *
	***************
    	
        ** Diff-Walk
        *1. Identify people having diff
        gen walkdiff = 99
        replace walkdiff = 1 if inlist(r13walkr,1,2,9)
        replace walkdiff = 0 if r13walkr ==0
        *2. % of people who need help
        tab walkdiff,m
        tab walkdiff[aweight=r13wtrespe],m
        *3. Identify people having diff received informal help
        gen walkdiffinformal = 0
        replace walkdiffinformal = 1 if walkdiff ==1 & Informal ==1
        replace walkdiffinformal = 99 if walkdiff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if walkdiff ==1
        tab walkdiffinformal, m
        tab walkdiffinformal[aweight=r13wtrespe], m
        restore


        ** Diff-Bed
        *1. Identify people having diff
        gen beddiff = 99
        replace beddiff = 1 if inlist(r13bed,1,2,9)
        replace beddiff = 0 if r13bed ==0
        *2. % of people who need help
        tab beddiff,m
        tab beddiff[aweight=r13wtrespe],m
        *3. Identify people having diff received informal help
        gen beddiffinformal = 0
        replace beddiffinformal = 1 if beddiff ==1 & Informal ==1
        replace beddiffinformal = 99 if beddiff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if beddiff ==1
        tab beddiffinformal, m
        tab beddiffinformal[aweight=r13wtrespe], m
        restore

        
        ** MOBILITY
        *1. Identify people having mobility diff
        gen mobilitydiff = 99
        replace mobilitydiff = 1 if walkdiff ==1 | beddiff ==1
        replace mobilitydiff = 0 if walkdiff ==0 & beddiff ==0
        *2. % of people who need mobility help
        tab mobilitydiff,m
        tab mobilitydiff[aweight=r13wtrespe],m
        *3. Identify people having mobility diff received informal help
        gen mobilityiffinformal = 0
        replace mobilityiffinformal = 1 if mobilitydiff ==1 & Informal ==1
        replace mobilityiffinformal = 99 if mobilitydiff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if mobilitydiff ==1
        tab mobilityiffinformal, m
        tab mobilityiffinformal[aweight=r13wtrespe], m
        restore


 	****************
        * 2. Self-Care *
	****************

        ** Diff-Eat 
        *1. Identify people having diff
        gen eatdiff = 99
        replace eatdiff = 1 if inlist(r13eat,1,2,9)
        replace eatdiff = 0 if r13eat ==0
        *2. % of people who need help
        tab eatdiff,m
        tab eatdiff[aweight=r13wtrespe],m
        *3. Identify people having diff received informal help
        gen eatdiffinformal = 0
        replace eatdiffinformal = 1 if eatdiff ==1 & Informal ==1
        replace eatdiffinformal = 99 if eatdiff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if eatdiff ==1
        tab eatdiffinformal, m
        tab eatdiffinformal[aweight=r13wtrespe], m
        restore


        ** Diff-Bath
        *1. Identify people having bath diff
        gen bathdiff = 99
        replace bathdiff = 1 if inlist(r13bath,1,2,9)
        replace bathdiff = 0 if r13bath ==0
        *2. % of people who need help
        tab bathdiff,m
        tab bathdiff[aweight=r13wtrespe],m
        *3. Identify people having diff received informal help
        gen bathdiffinformal = 0
        replace bathdiffinformal = 1 if bathdiff ==1 & Informal ==1
        replace bathdiffinformal = 99 if bathdiff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if bathdiff ==1
        tab bathdiffinformal, m
        tab bathdiffinformal[aweight=r13wtrespe], m
        restore


        ** Diff-Toilet
        *1. Identify people having diff
        gen toiltdiff = 99
        replace toiltdiff = 1 if inlist(r13toilt,1,2,9)
        replace toiltdiff = 0 if r13toilt ==0
        *2. % of people who need help
        tab toiltdiff,m
        tab toiltdiff[aweight=r13wtrespe],m
        *3. Identify people having diff received informal help
        gen toiltdiffinformal = 0
        replace toiltdiffinformal = 1 if toiltdiff ==1 & Informal ==1
        replace toiltdiffinformal = 99 if toiltdiff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if toiltdiff ==1
        tab toiltdiffinformal, m
        tab toiltdiffinformal[aweight=r13wtrespe], m
        restore


        ** Diff-Dress
        *1. Identify people having diff
        gen dressdiff = 99
        replace dressdiff = 1 if inlist(r13dress,1,2,9)
        replace dressdiff = 0 if r13dress ==0
        *2. % of people who need help
        tab dressdiff,m
        tab dressdiff[aweight=r13wtrespe],m
        *3. Identify people having diff received informal help
        gen dressdiffinformal = 0
        replace dressdiffinformal = 1 if dressdiff ==1 & Informal ==1
        replace dressdiffinformal = 99 if dressdiff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if dressdiff ==1
        tab dressdiffinformal, m
        tab dressdiffinformal[aweight=r13wtrespe], m
        restore


        ** SELF-CARE
        *1. Identify people having self-care diff
        gen selfcarediff = 99
        replace selfcarediff = 1 if eatdiff ==1 | bathdiff ==1 | toiltdiff==1 | dressdiff==1
        replace selfcarediff = 0 if eatdiff ==0 & bathdiff ==0 & toiltdiff==0 & dressdiff==0
        *2. % of people who need self-care help
        tab selfcarediff,m
        tab selfcarediff[aweight=r13wtrespe],m
        *3. Identify people having self-care diff received informal help
        gen selfcarediffinformal = 0
        replace selfcarediffinformal = 1 if selfcarediff ==1 & Informal ==1
        replace selfcarediffinformal = 99 if selfcarediff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if selfcarediff ==1
        tab selfcarediffinformal, m
        tab selfcarediffinformal[aweight=r13wtrespe], m
        restore


 	*************************
        * 3. Household Activity *
	*************************

        ** Diff-Shop
        *1. Identify people having diff
        gen shopdiff = 99
        replace shopdiff = 1 if inlist(r13shop,1,2,9)
        replace shopdiff = 0 if r13shop ==0
        *2. % of people who need help
        tab shopdiff,m
        tab shopdiff[aweight=r13wtrespe],m
        *3. Identify people having diff received informal help
        gen shopdiffinformal = 0
        replace shopdiffinformal = 1 if shopdiff ==1 & Informal ==1
        replace shopdiffinformal = 99 if shopdiff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if shopdiff ==1
        tab shopdiffinformal, m
        tab shopdiffinformal[aweight=r13wtrespe], m
        restore


        ** Diff-Hot meal
        *1. Identify people having meal diff
        gen mealdiff = 99
        replace mealdiff = 1 if inlist(r13meals,1,2,9)
        replace mealdiff = 0 if r13meals ==0
        *2. % of people who need help
        tab mealdiff,m
        tab mealdiff[aweight=r13wtrespe],m
        *3. Identify people having meal diff received informal help
        gen mealdiffinformal = 0
        replace mealdiffinformal = 1 if mealdiff ==1 & Informal ==1
        replace mealdiffinformal = 99 if mealdiff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if mealdiff ==1
        tab mealdiffinformal, m
        tab mealdiffinformal[aweight=r13wtrespe], m
        restore


        ** Diff-Handle Money
        *1. Identify people having diff
        gen moneydiff = 99
        replace moneydiff = 1 if inlist(r13money,1,2,9)
        replace moneydiff = 0 if r13money ==0
        *2. % of people who need help
        tab moneydiff,m
        tab moneydiff[aweight=r13wtrespe],m
        *3. Identify people having diff received informal help
        gen moneydiffinformal = 0
        replace moneydiffinformal = 1 if moneydiff ==1 & Informal ==1
        replace moneydiffinformal = 99 if moneydiff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if moneydiff ==1
        tab moneydiffinformal, m
        tab moneydiffinformal[aweight=r13wtrespe], m
        restore


        ** Diff-Phone Call
        *1. Identify people having diff making phone call
        gen phoncalldiff = 99
        replace phoncalldiff = 1 if inlist(r13phone,1,2,9)
        replace phoncalldiff = 0 if r13phone ==0
        *2. % of people who need help
        tab phoncalldiff,m
        tab phoncalldiff[aweight=r13wtrespe],m
        *3. Identify people having diff received informal help
        gen phoncalldiffinformal = 0
        replace phoncalldiffinformal = 1 if phoncalldiff ==1 & Informal ==1
        replace phoncalldiffinformal = 99 if phoncalldiff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if phoncalldiff ==1
        tab phoncalldiffinformal, m
        tab phoncalldiffinformal[aweight=r13wtrespe], m
        restore


        ** HOUSEHOLD ACTIVITY
        *1. Identify people having diff doing household activities
        gen householddiff = 99
        replace householddiff = 1 if shopdiff ==1 | mealdiff ==1 | moneydiff==1 | phoncalldiff==1
        replace householddiff = 0 if shopdiff ==0 & mealdiff ==0 & moneydiff==0 & phoncalldiff==0
        *2. % of people who need household help
        tab householddiff,m
        tab householddiff[aweight=r13wtrespe],m
        *3. Identify people having household diff received informal help
        gen householddiffinformal = 0
        replace householddiffinformal = 1 if householddiff ==1 & Informal ==1
        replace householddiffinformal = 99 if householddiff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if householddiff ==1
        tab householddiffinformal, m
        tab householddiffinformal[aweight=r13wtrespe], m
        restore


 	***************
        * 4. Medicare *
	***************

        *1. Identify people having diff taking medications
        gen medsdiff = 99
        replace medsdiff = 1 if inlist(r13meds,1,2,9)
        replace medsdiff = 0 if r13meds ==0
        *2. % of people who need help
        tab medsdiff,m
        tab medsdiff[aweight=r13wtrespe],m
        *3. Identify people having diff received informal help
        gen medsdiffinformal = 0
        replace medsdiffinformal = 1 if medsdiff ==1 & Informal ==1
        replace medsdiffinformal = 99 if medsdiff ==99
        *4. % of people who need help and received informal help AMONG PEOPLE WHO NEED HELP
        preserve
        keep if medsdiff ==1
        tab medsdiffinformal, m
        tab medsdiffinformal[aweight=r13wtrespe], m
        restore

}
