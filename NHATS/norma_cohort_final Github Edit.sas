/*******************************************************************************
** Project: PAC caregiving
** Program Name: norma_cohort_final.sas
** By: Xinwei Chen
** Date Programmed: 20210114
** Last Modified: 20210517

** Purpose:    
	to quantify the #/% of NHATS SP who receive caregiving provided NOT by staff of the facility
	cohort definition:
	1. 2015 NHATS
	2. in community or a care facility at the time of the interview
	
** Required Input Datasets:
	2015 NHATS survey data (public available):
		NHATS SP + SP Tracker file
		NHATS OP file
	2015 NHATS survey data (sensitive file):
		NHATS demo file 
	2015 NHATS-CMS linked date (restricted file)
		CMS-MBSF data
	
** Created Datasets: 
	/PATH/norma_cohort_20210517.csv

** Next program:
	norma_cohort_final_prep_table.rmd (create results & output)
*******************************************************************************/

filename libref "PATH/libname.sas";
%include libref;

options linesize = 120 pagesize = 42 missing = '' validvarname = upcase nocenter;
options nodate nonumber macrogen mlogic mprint symbolgen nofmterr compress = binary; 
title;


/*******************************************************************************
*** Step 0a: prep NHATS - extract race and gender for Round5 
*******************************************************************************/
proc sql;
	create table xctemp.wave2_gender_race as
	select spid, R5DGENDER as gender, 
		(case when RL5DRACEHISP = 6 then 5
			else RL5DRACEHISP end) as race
	from r5pub.spfile;
quit;


/*******************************************************************************
*** Step 0b: prep NHATS - extract marital status by round
*** this is because in follow up rounds only changes were reported
*** so linking between rounds is required
*** algorithm: use updated marital if reported changes in hh*marchange or new SP
*** if report no/missing/NA for marchange, then use the last available marital info
*** who are missing/NA for marchage: FQ only + deceased
*******************************************************************************/
proc sql;
	create table xctemp.round1_marital as
	select spid, hh1martlstat as marital
	from r1pub.spfile;
	
	/* starting in R2, linking to previous round*/
	create table xctemp.round2_marital as
	select a.spid, 
		(case when hh2marchange = 1 or hh2martlstat > 0 then hh2martlstat 
		else b.marital end) as marital
	from r2pub.spfile as a left join xctemp.round1_marital as b
		on a.spid = b.spid;
		
	create table xctemp.round3_marital as
	select a.spid, 
		(case when hh3marchange = 1 or hh3martlstat > 0 then hh3martlstat 
		else b.marital end) as marital
	from r3pub.spfile as a left join xctemp.round2_marital as b
		on a.spid = b.spid;
		
	create table xctemp.round4_marital as
	select a.spid, 
		(case when hh4marchange = 1 or hh4martlstat > 0 then hh4martlstat 
		else b.marital end) as marital
	from r4pub.spfile as a left join xctemp.round3_marital as b
		on a.spid = b.spid;
		
	/* note R5 is different!*/	
	create table xctemp.round5_marital as
	select a.spid, 
		(case when r5dcontnew = 2 then hh5martlstat
		when r5dcontnew = 1 and (hh5marchange = 1 or hh5martlstat > 0) then hh5martlstat 
		else b.marital end) as marital
	from r5pub.spfile as a left join xctemp.round4_marital as b
		on a.spid = b.spid;
	
	create table xctemp.round6_marital as
	select a.spid, 
		(case when hh6marchange = 1 or hh6martlstat > 0 then hh6martlstat 
		else b.marital end) as marital
	from r6pub.spfile as a left join xctemp.round5_marital as b
		on a.spid = b.spid;

	create table xctemp.round7_marital as
	select a.spid, 
		(case when hh7marchange = 1 or hh7martlstat > 0 then hh7martlstat 
		else b.marital end) as marital
	from r7pub.spfile as a left join xctemp.round6_marital as b
		on a.spid = b.spid;
quit;

* collapose marital categories;
%macro round(num, wave, year);
   data xctemp.round&num._marital;
   	   set xctemp.round&num._marital;
   	   if marital in (1, 2) then mari = 1;
   	   else if marital in (3, 4, 5) then mari = 2;
   	   else if marital = 6 then mari = 3;
   	   else mari = .;
   	   drop marital;
   	   rename mari = marital;
   run;
%mend round;
%round(1, 1, 2011)
%round(2, 1, 2012)
%round(3, 1, 2013)
%round(4, 1, 2014)
%round(5, 2, 2015)
%round(6, 2, 2016)
%round(7, 2, 2017)



/*******************************************************************************
*** Step 1: load NHATS 2015 main survey data
*** link with SP tracker file to get interview year/month information
*** link with SP demographic file to get sample person demographics (age, race, marital)
*** note R5-R7 have a different 2011 cohort weight
*******************************************************************************/

proc sql;
	create table r5_sp_combined as
	select 2015 as sp_year,
		 a.*,
		 a.r5d2intvrage as liveagecat, a.r5d2deathage as deathagecat, 
		  (case when liveagecat > 0 then liveagecat
		 when liveagecat < 0 and deathagecat > 0 then deathagecat
		 else . end) as agecat_nhats,
		 (case when a.hc5health in (-9, -8, -7) then .
			else a.hc5health end) as overall_health,
		 a.W5ANFINWGT0 as ana_final_wt0, 	
		 a.W5AN2011WGT0 as ana_2011_wt0,
		 b.*, 
		 c.pd5mthdied as mthdied,
   		 c.pd5yrdied as yrdied,
		 d.gender, d.race, e.marital
	from (
		select * 
		from r5pub.spfile 
			(keep = spid r5dresid
			 r5d2intvrage r5d2deathage
			 is5: hc5: sc5: mo5: ha: mc:
			 W5ANFINWGT0 W5AN2011WGT0 W5VARSTRAT W5VARUNIT)
		) as a,
		r5pub.tracker_file (keep = SPID YEARSAMPLE R:) as b,
		r5dem.sp_demo as c,
		xctemp.wave2_gender_race as d, 
		xctemp.round5_marital as e
	where a.spid = b.spid = c.spid = d.spid = e.spid
		and a.r5dresid in (1, 2, 4); /*20210502	add community-dwelling sample*/
quit;

proc freq data = r5_sp_combined;
	tables r5casestdtmt yearsample sp_year; /* month/year of the survey */
run;

proc freq data = r5_sp_combined;
	tables liveagecat * deathagecat / missing; 
*	tables agecat / missing;
run;

* check status vs dresid;
proc freq data = r5_sp_combined;
	tables r5status * r5dresid /missing nocum nopercent;
run;
	
/*******************************************************************************
*** Step 2: link with xwalk to get CMS BENE ID added to NHATS data
*******************************************************************************/
proc sql;
	create table r5_sp_tracker_beneid as
	select a.*, b.bene_id
	from r5_sp_combined as a join xc.nhats_xwalk_combined as b
		on a.spid = b.spid;
	
	* check - all good;
	select count(distinct bene_id) as n_SP
	from r5_sp_tracker_beneid;
quit;

proc freq data = r5_sp_tracker_beneid;
	tables ffs / missing;
run;

/*******************************************************************************
*** Step 3: merge with CMS MBSF data
*******************************************************************************/
* link by bene_id;
proc sql;
	create table r5_NHATS_MBSF as
	select a.*, b.BENE_BIRTH_DT, b.DEATH_DT
	from r5_sp_tracker_beneid as a join xctemp.wave2_mbsf as b
		on a.bene_id = b.bene_id;
		
	* check;
	select count(distinct spid), count(distinct bene_id), count(*) 
	from r5_NHATS_MBSF;
quit;

/*******************************************************************************
*** Step 4: calculate age at interview or age at death (based on MBSF, not NHATS)
*******************************************************************************/
* age at interview (compare birth date with first day of the interview month);

data r5_NHATS_age;
	set r5_NHATS_MBSF;
	intv_date = mdy(r5casestdtmt, 1, r5casestdtyr);
		
	* live age at interview;
	age = floor((intck('month',BENE_BIRTH_DT,intv_date)-(day(intv_date)<day(BENE_BIRTH_DT)))/12);
	drop intv_date;
	
	if 65 <= age <= 69 then agecat_mbsf = 1;
	else if 70 <= age <= 74 then agecat_mbsf = 2;
	else if 75 <= age <= 79 then agecat_mbsf = 3;
	else if 80 <= age <= 84 then agecat_mbsf = 4;
	else if 85 <= age <= 89 then agecat_mbsf = 5;
	else if 90 <= age then agecat_mbsf = 6;
	else agecat_mbsf = .;	

run;

proc means data = r5_NHATS_age;
	var age;
run;

* compare MBSF age with NHATS age;
proc freq data = r5_NHATS_age;
	tables agecat_mbsf * agecat_nhats / missing nocum nopercent;
run;

/*******************************************************************************
*** Step 5: code caregiving activities
*******************************************************************************/
proc freq data = r5_NHATS_age;
	tables mo5outhlp mo5insdhlp mo5bedhlp
			sc5eathlp sc5bathhlp sc5toilhlp sc5dreshlp / missing;
run;

data r5_prep1;
	set r5_NHATS_age;

	/**************************************************************/
	/* MO: get around outside
	/**************************************************************/
	if mo5outhlp = 1 then mo_out = 1;
		else if mo5outhlp in (2, -7, -8) then mo_out = 0;
	
	/**************************************************************/
	/* MO: get around inside
	/**************************************************************/
	if mo5insdhlp = 1 then mo_in = 1;
		else if mo5insdhlp in (2, -7, -8) then mo_in = 0;
	
	/**************************************************************/
	/* MO: get out of bed
	/**************************************************************/
	if mo5bedhlp = 1 then mo_bed = 1;
		else if mo5bedhlp in (2, -7, -8) then mo_bed = 0;
		
	/**************************************************************/
	/* SC: eating
	/**************************************************************/
	if sc5eathlp = 1 then sc_eat = 1;
		else if sc5eathlp in (2, -7, -8) then sc_eat = 0;
	
	/**************************************************************/
	/* SC: cleaning 
	/**************************************************************/
	if sc5bathhlp = 1 then sc_bath = 1;
		else if sc5bathhlp in (2, -7, -8) then sc_bath = 0;
	
	/**************************************************************/
	/* SC: toileting
	/**************************************************************/
	if sc5toilhlp = 1 then sc_toil = 1;
		else if sc5toilhlp in (2, -7, -8) then sc_toil = 0;
		
	/**************************************************************/
	/* SC: dressing
	/**************************************************************/
	if sc5dreshlp = 1 then sc_dres = 1;
		else if sc5dreshlp in (2, -7, -8) then sc_dres = 0;
		
	/**************************************************************/
	/* HA: do laundry
	/**************************************************************/
	if ha5laun in (2, 3, 4) then ha_laun = 1;
		else if ha5laun in (1, -7, -8) then ha_laun = 0;           
	
	/**************************************************************/
	/* HA: do shopping
	/**************************************************************/
	if ha5shop in (2, 3, 4) then ha_shop = 1;
		else if ha5shop in (1, -7, -8) then ha_shop = 0;
	
	/**************************************************************/
	/* HA: make hot meals
	/**************************************************************/
	if ha5meal in (2, 3, 4) then ha_meal = 1;
		else if ha5meal in (1, -7, -8) then ha_meal = 0;
	
	/**************************************************************/
	/* HA: handle bills and banking
	/**************************************************************/
	if ha5bank in (2, 3, 4) then ha_bank = 1;
		else if ha5bank in (1, -7, -8) then ha_bank = 0;
		

	/**************************************************************/
	/* MC: keep track of medicine
	/**************************************************************/
	if mc5medstrk in (2, 3, 4) then mc_med = 1;
		else if mc5medstrk in (1, -7, -8) then mc_med = 0;

	
run;

proc freq data = r5_prep1;
	tables mo_: sc_: ha_: mc_:/ missing;
run;

/*******************************************************************************
*** Step 6: use OP file to find SP who only received help from staff
*******************************************************************************/
* method: for each activity and for each SP:
* 1. count #OP who helped with the activity;
* 2. count #OP who helped with the activity and is staff;
* 3. compare the two counts:
	1) if the number is equal, then the SP is only receiving help from staff
	2) otherwise, the SP is receiving help from not only staff;
	
%varlist(r5pub.opfile)

%macro care(varname, desc);
	
	proc sql;
		create table sp_lvl_prep1_&desc. as
		select spid, count(distinct opid) as op_&desc.
		from r5pub.opfile
		where r5dresid in (2, 4) and &varname. = 1
		group by spid;
		
		create table sp_lvl_prep2_&desc. as
		select spid, count(distinct opid) as op_staff_&desc.
		from r5pub.opfile
		where r5dresid in (2, 4) and &varname. = 1 and op5relatnshp = 37
		group by spid;
		
		create table sp_lvl_compare_&desc. as
		select a.*, b.op_staff_&desc.
		from sp_lvl_prep1_&desc. as a left join sp_lvl_prep2_&desc. as b
			on a.spid = b.spid;
	quit;
	
	proc means data = sp_lvl_compare_&desc.;
		var op_&desc. op_staff_&desc.;
	run;
	
	data sp_lvl_compare2_&desc.;
		set sp_lvl_compare_&desc.;
		if op_&desc. > 0 and op_staff_&desc. = . then op_staff_&desc. = 0;
		diff = op_&desc. - op_staff_&desc.;
		if diff = 0 then flag = 1;
	run;
	
	proc freq data = sp_lvl_compare2_&desc.;
		tables flag / missing;
	run;

		
%mend care;
%care(op5outhlp,   mo_out)
%care(op5insdhlp,  mo_in)
%care(op5bedhlp,   mo_bed)
%care(op5eathlp,   sc_eat)
%care(op5bathhlp,  sc_bath)
%care(op5toilhlp,  sc_toil)
%care(op5dreshlp,  sc_dres)
%care(op5launhlp,  ha_laun)
%care(op5shophlp,  ha_shop)
%care(op5mealhlp,  ha_meal)
%care(op5bankhlp,  ha_bank)
%care(op1medshlp,  mc_med)


/*******************************************************************************
*** Step 7: link SP with OP 
*******************************************************************************/
* recode get help variables;
proc sql;
	create table r5_prep2 as
	select a.*, 
		(case when a.mo_out    = 1 and b.flag = 1 then 0 else mo_out   end) as mo_out_edit,
		(case when a.mo_in     = 1 and c.flag = 1 then 0 else mo_in    end) as mo_in_edit,
		(case when a.mo_bed    = 1 and d.flag = 1 then 0 else mo_bed   end) as mo_bed_edit,
		(case when a.sc_eat    = 1 and e.flag = 1 then 0 else sc_eat   end) as sc_eat_edit,
		(case when a.sc_bath   = 1 and f.flag = 1 then 0 else sc_bath  end) as sc_bath_edit,
		(case when a.sc_toil   = 1 and g.flag = 1 then 0 else sc_toil  end) as sc_toil_edit,
		(case when a.sc_dres   = 1 and h.flag = 1 then 0 else sc_dres  end) as sc_dres_edit,
		(case when a.ha_laun   = 1 and i.flag = 1 then 0 else ha_laun  end) as ha_laun_edit,
		(case when a.ha_shop   = 1 and j.flag = 1 then 0 else ha_shop  end) as ha_shop_edit,
		(case when a.ha_meal   = 1 and k.flag = 1 then 0 else ha_meal  end) as ha_meal_edit,
		(case when a.ha_bank   = 1 and l.flag = 1 then 0 else ha_bank  end) as ha_bank_edit,
		(case when a.mc_med    = 1 and n.flag = 1 then 0 else mc_med   end) as mc_med_edit

	from r5_prep1 as a 
		left join sp_lvl_compare2_mo_out   as b on a.spid = b.spid
		left join sp_lvl_compare2_mo_in    as c on a.spid = c.spid
		left join sp_lvl_compare2_mo_bed   as d on a.spid = d.spid
		left join sp_lvl_compare2_sc_eat   as e on a.spid = e.spid
		left join sp_lvl_compare2_sc_bath  as f on a.spid = f.spid
		left join sp_lvl_compare2_sc_toil  as g on a.spid = g.spid
		left join sp_lvl_compare2_sc_dres  as h on a.spid = h.spid
		left join sp_lvl_compare2_ha_laun  as i on a.spid = i.spid
		left join sp_lvl_compare2_ha_shop  as j on a.spid = j.spid
		left join sp_lvl_compare2_ha_meal  as k on a.spid = k.spid
		left join sp_lvl_compare2_ha_bank  as l on a.spid = l.spid
		left join sp_lvl_compare2_mc_med   as n on a.spid = n.spid
		;
quit;

proc freq data = r5_prep2;
	tables mo_: sc_: ha_: mc_:/ missing;
run;

* create aggregate get help variables;
data r5_prep3;
	set r5_prep2;
	
	/**************************************************************/
	/* MO
	/**************************************************************/
	if mo_out_edit = 1 or mo_in_edit = 1 or mo_bed_edit = 1 then mo_help = 1;
		else if mo_out_edit = . and mo_in_edit = . and mo_bed_edit = . then mo_help = .;
		else mo_help = 0;	

	/**************************************************************/
	/* SC
	/**************************************************************/
	if sc_eat_edit = 1 or sc_bath_edit = 1 or sc_toil_edit = 1 or sc_dres_edit = 1 then sc_help = 1;
		else if sc_eat_edit = . and sc_bath_edit = . and sc_toil_edit = . and sc_dres_edit = . then sc_help = .;
		else sc_help = 0;
		
	/**************************************************************/
	/* HA
	/**************************************************************/
	if ha_laun_edit = 1 or ha_shop_edit = 1 or ha_meal_edit = 1 or ha_bank_edit = 1  then ha_help = 1;
		else if ha_laun_edit = . and ha_shop_edit = . and ha_meal_edit = . and ha_bank_edit = . then ha_help = .;
		else ha_help = 0;
	
	/**************************************************************/
	/* MC
	/**************************************************************/
	if mc_med_edit = 1  then mc_help = 1;
		else if mc_med_edit = .  then mc_help = .;
		else mc_help = 0;	
		
run;


/*******************************************************************************
*** Step 8: code NEED HELP measures (removed 3 activities)
*******************************************************************************/
data r5_prep4;
	set r5_prep3;
	
* code for each activity; 
	/**************************************************************/
	/* MO: get around outside
	/**************************************************************/
	if mo5outoft = 5 /* MO1: never go outside */
		or mo5outwout = 1 /* MO10: ever not go outside b/c no help/diff */
		or mo5outdif in (3, 4) /* MO8: have difficulty doing by self */
	then needhelp_mo_out = 1;
	else needhelp_mo_out = 0;
	
	/**************************************************************/
	/* MO: get around inside
	/**************************************************************/
	if (mo5oftgoarea = 5 or mo5oflvslepr = 5) /* MO11/MO12: never go inside */
		or mo5insdwout = 1 /* MO23: ever not go inside b/c no help/diff */
		or mo5insddif in (3, 4) /* MO21: have difficulty doing by self */
	then needhelp_mo_ins = 1;
	else needhelp_mo_ins = 0;
	
	/**************************************************************/
	/* MO: get out of bed
	/**************************************************************/
	if mo5bedwout = 1 /* MO23: ever stay in bed b/c no help or diff */
		or mo5beddif in (3, 4) /* MO21: have difficulty doing by self */
	then needhelp_mo_bed = 1;
	else needhelp_mo_bed = 0;
	
	
	/**************************************************************/
	/* SC: eating
	/**************************************************************/
	if sc5eatwout = 1 /* no eat b/c no help or diff */
		or sc5eatslfdif in (3, 4) /* have difficulty doing by self */
	then needhelp_sc_eat = 1;
	else needhelp_sc_eat = 0;
	
	/**************************************************************/
	/* SC: cleaning 
	/**************************************************************/
	if sc5bathwout = 1 /* no washing b/c no help or diff */
		or sc5bathdif in (3, 4) /* have difficulty doing by self */
	then needhelp_sc_clean = 1;	
	else needhelp_sc_clean = 0;
	
	/**************************************************************/
	/* SC: toileting
	/**************************************************************/
	if sc5toilwout = 1 /* wet/soil b/c no help or diff */
		or sc5toildif in (3, 4) /* have difficulty doing by self */
	then needhelp_sc_toilet = 1;
	else needhelp_sc_toilet = 0;
	
	/**************************************************************/
	/* SC: dressing
	/**************************************************************/
	if sc5dresoft = 5 
		or sc5dreswout = 1 /* ever no dress b/c no help/diff */
		or sc5dresdif in (3, 4) /* have difficulty doing by self */
	then needhelp_sc_dress = 1;
	else needhelp_sc_dress = 0;
	
	
	/**************************************************************/
	/* HA: laundry
	/**************************************************************/
	if ha5launwout = 1 /* go without laundry b/c no help/diff */
		or ha5laundif in (3, 4) /* have difficulty doing by self */
		or (ha5laun in (2, 3, 4) and HA5DLAUNREAS in (1, 3)) /* receive help b/c health/functioning reason */
	then needhelp_ha_laun = 1;
	else needhelp_ha_laun = 0;
	
	/**************************************************************/
	/* HA: shopping
	/**************************************************************/
	if ha5shopwout = 1 /* go without shopping b/c no help/diff */
		or ha5shopdif in (3, 4) /* have difficulty doing by self */
		or (ha5shop in (2, 3, 4) and HA5DSHOPREAS in (1, 3)) /* receive help b/c health/functioning reason */
	then needhelp_ha_shop = 1;
	else needhelp_ha_shop = 0;
	
	/**************************************************************/
	/* HA: make hot meals
	/**************************************************************/
	if ha5mealwout = 1 /* go without hot meal b/c no help/diff */
		or ha5mealdif in (3, 4) /* have difficulty doing by self */
		or (ha5meal in (2, 3, 4) and HA5DMEALREAS in (1, 3)) /* receive help b/c health/functioning reason */
	then needhelp_ha_meal = 1;
	else needhelp_ha_meal = 0;
	
	/**************************************************************/
	/* HA: handle bills and banking
	/**************************************************************/
	if ha5bankwout = 1 /* go without paying bills b/c no help/diff */
		or ha5bankdif in (3, 4) /* have difficulty doing by self */
		or (ha5bank in (2, 3, 4) and HA5DBANKREAS in (1, 3))  /* receive help b/c health/functioning reason */
	then needhelp_ha_bank = 1;
	else needhelp_ha_bank = 0;
	
	
	/**************************************************************/
	/* MC: keep track of medicine
	/**************************************************************/
	if mc5medsmis = 1 /* make mistakes b/c no help/diff */
		or mc5medsdif in (3, 4) /* have difficulty doing by self */
		or (mc5medstrk in (2, 3, 4) and MC5DMEDSREAS in (1, 3))  /* receive help b/c health/functioning reason */
	then needhelp_mc_meds = 1;
	else needhelp_mc_meds = 0;
		
	
	
* add aggregate needhelp variables;
	/**************************************************************/
	/* MO
	/**************************************************************/
	if needhelp_mo_out = 1 or needhelp_mo_ins = 1 or needhelp_mo_bed = 1 
		then needhelp_mo = 1;
		else needhelp_mo = 0;

	/**************************************************************/
	/* SC
	/**************************************************************/
	if needhelp_sc_eat = 1 or needhelp_sc_clean = 1 or needhelp_sc_toilet = 1 or needhelp_sc_dress = 1 
		then needhelp_sc = 1;
		else needhelp_sc = 0;
		
	/**************************************************************/
	/* HA
	/**************************************************************/
	if needhelp_ha_laun = 1 or needhelp_ha_shop = 1 or needhelp_ha_meal = 1 or needhelp_ha_bank = 1
		then needhelp_ha = 1;
		else needhelp_ha = 0;
	
	/**************************************************************/
	/* MC
	/**************************************************************/
	if needhelp_mc_meds = 1
		then needhelp_mc = 1;
		else needhelp_mc = 0;
run;



/*******************************************************************************
*** Step 9: recode RECEIVING HELP based on NEEDING HELP (change denominators)
*******************************************************************************/
data r5_prep5;
	set r5_prep4;
	
	/**************************************************************/
	/* MO: get around outside
	/**************************************************************/
	mo_out_edit2 = mo_out_edit;
	if needhelp_mo_out = 0 then mo_out_edit2 = .;
		else if mo_out_edit = . and needhelp_mo_out = 1 then mo_out_edit2 = 9;
	
	/**************************************************************/
	/* MO: get around inside
	/**************************************************************/
	mo_in_edit2 = mo_in_edit;
	if needhelp_mo_ins = 0 then mo_in_edit2 = .;
		else if mo_in_edit = . and needhelp_mo_ins = 1 then mo_in_edit2 = 9;

	/**************************************************************/
	/* MO: get out of bed
	/**************************************************************/
	mo_bed_edit2 = mo_bed_edit;
	if needhelp_mo_bed = 0 then mo_bed_edit2 = .;
		else if mo_bed_edit = . and needhelp_mo_bed = 1 then mo_bed_edit2 = 9;
	
		
	/**************************************************************/
	/* SC: eating
	/**************************************************************/
	sc_eat_edit2 = sc_eat_edit;
	if needhelp_sc_eat = 0 then sc_eat_edit2 = .;
		else if sc_eat_edit = . and needhelp_sc_eat = 1 then sc_eat_edit2 = 9;
	
	/**************************************************************/
	/* SC: cleaning 
	/**************************************************************/
	sc_bath_edit2 = sc_bath_edit;
	if needhelp_sc_clean = 0 then sc_bath_edit2 = .;
		else if sc_bath_edit = . and needhelp_sc_clean = 1 then sc_bath_edit2 = 9;

	/**************************************************************/
	/* SC: toileting
	/**************************************************************/
	sc_toil_edit2 = sc_toil_edit;
	if needhelp_sc_toilet = 0 then sc_toil_edit2 = .;
		else if sc_toil_edit = . and needhelp_sc_toilet = 1 then sc_toil_edit2 = 9;
	
	/**************************************************************/
	/* SC: dressing
	/**************************************************************/
	sc_dres_edit2 = sc_dres_edit;
	if needhelp_sc_dress = 0 then sc_dres_edit2 = .;
		else if sc_dres_edit = . and needhelp_sc_dress = 1 then sc_dres_edit2 = 9;

	
	/**************************************************************/
	/* HA: do laundry
	/**************************************************************/
	ha_laun_edit2 = ha_laun_edit;
	if needhelp_ha_laun = 0 then ha_laun_edit2 = .;     
		else if ha_laun_edit = . and needhelp_ha_laun = 1 then ha_laun_edit2 = 9;     

	/**************************************************************/
	/* HA: do shopping
	/**************************************************************/
	ha_shop_edit2 = ha_shop_edit;
	if needhelp_ha_shop = 0 then ha_shop_edit2 = .;     
		else if ha_shop_edit = . and needhelp_ha_shop = 1 then ha_shop_edit2 = 9;     

	/**************************************************************/
	/* HA: make hot meals
	/**************************************************************/
	ha_meal_edit2 = ha_meal_edit;
	if needhelp_ha_meal = 0 then ha_meal_edit2 = .;     
		else if ha_meal_edit = . and needhelp_ha_meal = 1 then ha_meal_edit2 = 9;     

	/**************************************************************/
	/* HA: handle bills and banking
	/**************************************************************/
	ha_bank_edit2 = ha_bank_edit;
	if needhelp_ha_bank = 0 then ha_bank_edit2 = .;     
		else if ha_bank_edit = . and needhelp_ha_bank = 1 then ha_bank_edit2 = 9;     

		
	/**************************************************************/
	/* MC: keep track of medicine
	/**************************************************************/
	mc_med_edit2 = mc_med_edit;
	if needhelp_mc_meds = 0 then mc_med_edit2 = .;     
		else if mc_med_edit = . and needhelp_mc_meds = 1 then mc_med_edit2 = 9;     

	
	/*aggregate*/
	/**************************************************************/
	/* MO
	/**************************************************************/
	mo_help2 = mo_help;
	if needhelp_mo = 0 then mo_help2 = .;
		else if mo_help = . and needhelp_mo = 1 then mo_help2 = 9;

	/**************************************************************/
	/* SC
	/**************************************************************/
	sc_help2 = sc_help;
	if needhelp_sc = 0 then sc_help2 = .;
		else if sc_help = . and needhelp_sc = 1 then sc_help2 = 9;
		
	/**************************************************************/
	/* HA
	/**************************************************************/
	ha_help2 = ha_help;
	if needhelp_ha = 0 then ha_help2 = .;
		else if ha_help = . and needhelp_ha = 1 then ha_help2 = 9;
	
	/**************************************************************/
	/* MC
	/**************************************************************/
	mc_help2 = mc_help;
	if needhelp_mc = 0 then mc_help2 = .;
		else if mc_help = . and needhelp_mc = 1 then mc_help2 = 9;
	
	drop is5: hc5: r4: r3: r2: r1:;
run;

/*******************************************************************************
*** Step 9: Export data
*******************************************************************************/

proc export data = r5_prep5
			dbms = csv
			outfile = "/PATH/norma_cohort_20210517.csv"
			replace;
run;
