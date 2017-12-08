/* Shootout 2010
   Disease Prevention: A Data Mining Approach
   Created date: 12/20/2016
   Team Lead: Yun Zhou
 */

* Define LIBNAME for saving permanent datasets in Excel;
LIBNAME dp "C:\Users\WenYun\Desktop\filepath";
%INCLUDE "C:\Users\WenYun\Desktop\filepath\impute_macro.sas";
TITLE;

* Clean up all dataset in WORK library;
PROC DATASETS LIB=work KILL NOLIST MEMTYPE=data;QUIT;

PROC CONTENTS DATA=dp.shootout2010 ORDER=VARNUM; RUN; * Review dataset in the order of column;
* Based on the VARIABLE LISTING and problem description  it is necessary to split the dataset into three subsets: children  adult male and adult female;

* Check whether there is any missing value in AGE or SEX;
PROC FREQ DATA=dp.shootout2010; TABLE age sex; RUN;
* There are four records with AGE = -1  and no missing in SEX;

* Select records with AGE = -1 and review them;
PROC SQL;
	SELECT * FROM dp.shootout2010 WHERE age = -1;
QUIT;

* The four records have many missing values and the diabetes diagnostic is 0  therefore we can simply delete them;
* Recode -1 and inapplicable as MISSING (numerical for now);
DATA diabetes;
	SET dp.shootout2010;
	IF age > -1;
	IF census_region = -1 THEN census_region = .;
	IF marital_status = -1 OR marital_status = 6 THEN marital_status = .;
	IF years_educ = -1 AND age < 7 THEN years_educ = 0;
		ELSE IF years_educ = -1 THEN years_educ = .;
	IF highest_degree = -1 OR highest_degree = 8 THEN highest_degree = .;
	IF served_armed_forces = -1 or served_armed_forces = 3 THEN served_armed_forces = .;
		ELSE IF served_armed_forces = 4 THEN served_armed_forces = 1;
	IF foodstamps_purchase = -1 THEN foodstamps_purchase = .;
	IF more_than_one_job = -1 THEN more_than_one_job = .;
	IF wears_eyeglasses = -1 THEN wears_eyeglasses = .;
	IF person_blind = -1 THEN person_blind = .;
	IF wear_hearing_aid = -1 THEN wear_hearing_aid = .;
	IF is_deaf = -1 THEN is_deaf = .;
	IF child_bmi = -1 THEN child_bmi = .;
	IF dental_checkup = -1 THEN dental_checkup = .;
	IF cholest_lst_chck = -1 THEN cholest_lst_chck = .;
	IF last_checkup = -1 THEN last_checkup = .;
	IF last_flushot = -1 THEN last_flushot = .;
	IF lost_all_teeth = -1 THEN lost_all_teeth = .;
	IF last_psa = -1 THEN last_psa = .;
	IF last_pap_smear = -1 THEN last_pap_smear = .;
	IF last_breast_exam = -1 THEN last_breast_exam = .;
	IF last_mammogram = -1 THEN last_mammogram = .;
	IF bld_stool_tst = -1 THEN bld_stool_tst = .;
	IF sigmoidoscopy_colonoscopy = -1 THEN sigmoidoscopy_colonoscopy = .;
	IF adult_bmi = -1 THEN adult_bmi = .;
	IF wear_seat_belt = -1 THEN wear_seat_belt = .;
	IF asthma_diagnosis = -1 THEN asthma_diagnosis = .;
	IF high_blood_pressure_diag = -1 THEN high_blood_pressure_diag = .;
	IF heart_disease_diag = -1 THEN heart_disease_diag = .;
	IF angina_diagnosis = -1 THEN angina_diagnosis = .;
	IF heart_attack = -1 THEN heart_attack = .;
	IF other_heart_disease = -1 THEN other_heart_disease = .;
	IF stroke_diagnosis = -1 THEN stroke_diagnosis = .;
	IF emphysema_diagnosis = -1 THEN emphysema_diagnosis = .;
	IF joint_pain = -1 THEN joint_pain = .;
	IF currently_smoke = -1 THEN currently_smoke = .;
	IF amount_paid_medicare = -1 THEN amount_paid_medicare = .; * We may drop this one because the total expense is of interest;
	IF amount_paid_medicaid = -1 THEN amount_paid_medicaid = .; * We may drop this one because the total expense is of interest;
	IF totalexp = -1 THEN totalexp = .;
	IF numb_visits = -1 THEN numb_visits = .;
	IF person_weight = -1 THEN person_weight = .;
RUN;

* Split dataset into three subset;
DATA children adultm adultf;
	SET diabetes;
	IF age <= 20 THEN OUTPUT children;
	ELSE IF sex = 1 THEN OUTPUT adultm;
	ELSE OUTPUT adultf;
RUN;

* Drop variables inapplicable to each group;
* 1) Children;
DATA children;
	SET children;
	IF age <= 18 THEN bmi = child_bmi;
	ELSE bmi = adult_bmi;
	DROP more_than_one_job  cholest_lst_chck  last_checkup  last_flushot  lost_all_teeth  last_psa 
	     last_pap_smear  last_breast_exam  last_mammogram  bld_stool_tst  sigmoidoscopy_colonoscopy 
		 wear_seat_belt  high_blood_pressure_diag  heart_disease_diag  angina_diagnosis  heart_attack 
		 other_heart_disease  stroke_diagnosis  emphysema_diagnosis  joint_pain  currently_smoke child_bmi adult_bmi 
		 amount_paid_medicaid  amount_paid_medicare;
RUN;

PROC SORT DATA=children; BY diabetes_diag_binary; RUN;

TITLE "Before Imputation: Children";
PROC MEANS DATA=children N NMISS;
	CLASS diabetes_diag_binary;
	VAR _NUMERIC_;
	BY diabetes_diag_binary;
RUN;

* Further drop variables that have missing values more than 50% and no pattern shown to contribute to diabetes diagnostics;
DATA children;
	SET children;
	DROP marital_status highest_degree served_armed_forces person_blind is_deaf;
	order = _N_;
RUN;

%impute_all(children)

TITLE "After Imputation: Children";
PROC MEANS DATA=children N NMISS;
	CLASS diabetes_diag_binary;
	VAR _NUMERIC_;
	BY diabetes_diag_binary;
RUN;

* 2) Female Adults;
DATA adultf;
	SET adultf;
	bmi = adult_bmi;
	DROP last_psa  child_bmi adult_bmi amount_paid_medicaid  amount_paid_medicare;
RUN;

PROC SORT DATA=adultf; BY diabetes_diag_binary; RUN;

TITLE "Before Imputation: Adult F";
PROC MEANS DATA=adultf N NMISS;
	CLASS diabetes_diag_binary;
	VAR _NUMERIC_;
	BY diabetes_diag_binary;
RUN;

DATA adultf;
	SET adultf;
	IF age <= 29 AND last_mammogram = . THEN last_mammogram = 50; * Recode INAPPLICABLE case as 50 for females younger than 30;
	DROP more_than_one_job person_blind is_deaf;
	order = _N_;
RUN;

%impute_all(adultf)

TITLE "After Imputation: Adult F";
PROC MEANS DATA=adultf N NMISS;
	CLASS diabetes_diag_binary;
	VAR _NUMERIC_;
	BY diabetes_diag_binary;
RUN;

* 3) Male Adults;
DATA adultm;
	SET adultm;
	bmi = adult_bmi;
	DROP last_pap_smear  last_breast_exam  last_mammogram  child_bmi adult_bmi amount_paid_medicaid  amount_paid_medicare;
RUN;

PROC SORT DATA=adultm; BY diabetes_diag_binary; RUN;

TITLE "Before Imputation: Adult M";
PROC MEANS DATA=adultm N NMISS;
	CLASS diabetes_diag_binary;
	VAR _NUMERIC_;
	BY diabetes_diag_binary;
RUN;

DATA adultm;
	SET adultm;
	IF age <= 39 AND last_psa = . THEN last_psa = 50; * Recode INAPPLICABLE case as 50 for males younger than 40;
	DROP more_than_one_job person_blind is_deaf;
	order = _N_;
RUN;

%impute_all(adultm)

TITLE "After Imputation: Adult M";
PROC MEANS DATA=adultm N NMISS;
	CLASS diabetes_diag_binary;
	VAR _NUMERIC_;
	BY diabetes_diag_binary;
RUN;

* Model diabetes_diag_binary;
* Using Logistic Regression;
TITLE;
ODS GRAPHICS ON;
%MACRO resp_review(table);
	PROC FREQ DATA=&table;
		TABLES diabetes_diag_binary*age;
	RUN;

	PROC SORT DATA=&table; BY diabetes_diag_binary; RUN;
	PROC UNIVARIATE DATA=&table PLOT;
		BY diabetes_diag_binary;
		VAR age;
	RUN;

	PROC SGPLOT DATA=&table;
		VBAR age /GROUP=diabetes_diag_binary;
	RUN;
%MEND;

** 1) Children;
%resp_review(children) * Notice the diabetes event is very low (~0.25%);

PROC SURVEYSELECT DATA=children METHOD=SRS N=(41, 41) SEED=1357
	OUT=children_sampled;
	STRATA diabetes_diag_binary;
RUN;

DATA children_bmi_redu; * Create dataset for prediction;
	SET children;
	IF age >= 5 AND bmi >= 8/15*age + 43/3;
	bmi = 0.9*bmi;
RUN;

PROC LOGISTIC DATA=children_sampled;
	CLASS asthma_diagnosis census_region dental_checkup foodstamps_purchase sex wear_hearing_aid wears_eyeglasses years_educ diabetes_diag_binary;
	MODEL diabetes_diag_binary(EVENT="1") = asthma_diagnosis census_region dental_checkup foodstamps_purchase sex wear_hearing_aid 
										    wears_eyeglasses years_educ age bmi numb_visits person_weight total_income
										    /SELECTION=STEPWISE;
RUN;
***** Only selected age and numb_visits as predictors. Force bmi to be included in the model and refit;
PROC LOGISTIC DATA=children_sampled;
	CLASS diabetes_diag_binary;
	MODEL diabetes_diag_binary(EVENT="1") = age numb_visits bmi;
	SCORE DATA=children_bmi_redu OUT=children_pred1;
RUN;

DATA children_pred1;
	SET children_pred1;
	IF i_diabetes_diag_binary = '0' THEN diabetes_diag_binary = 0;
	ELSE IF i_diabetes_diag_binary = '1' THEN diabetes_diag_binary = 1;
	ELSE diabetes_diag_binary = .;
RUN;

** 2) Female Adults;
%resp_review(adultf) * Notice the number of diabetes events is 1396;

PROC SURVEYSELECT DATA=adultf METHOD=SRS N=(1604, 1396) SEED=1357
	OUT=adultf_sampled;
	STRATA diabetes_diag_binary;
RUN;

DATA adultf_bmi_redu;
	SET adultf;
	IF bmi >= 25;
	bmi = 0.9*bmi;
RUN;

PROC LOGISTIC DATA=adultf_sampled;
	CLASS angina_diagnosis asthma_diagnosis bld_stool_tst census_region cholest_lst_chck currently_smoke dental_checkup diabetes_diag_binary emphysema_diagnosis
          foodstamps_purchase heart_attack heart_disease_diag high_blood_pressure_diag highest_degree joint_pain last_breast_exam last_checkup last_flushot
          last_mammogram last_pap_smear lost_all_teeth marital_status other_heart_disease served_armed_forces sigmoidoscopy_colonoscopy stroke_diagnosis
          wear_hearing_aid wear_seat_belt wears_eyeglasses years_educ;
	MODEL diabetes_diag_binary(EVENT="1") = bmi age numb_visits person_weight total_income
          									angina_diagnosis asthma_diagnosis bld_stool_tst census_region cholest_lst_chck 
											currently_smoke dental_checkup emphysema_diagnosis
          									foodstamps_purchase heart_attack heart_disease_diag high_blood_pressure_diag highest_degree 
											joint_pain last_breast_exam last_checkup last_flushot last_mammogram last_pap_smear lost_all_teeth 
											marital_status other_heart_disease served_armed_forces sigmoidoscopy_colonoscopy stroke_diagnosis
          									wear_hearing_aid wear_seat_belt wears_eyeglasses years_educ
										    /SELECTION=STEPWISE;
RUN;
***** Refit and score the whold data;
PROC LOGISTIC DATA=adultf_sampled;
	CLASS diabetes_diag_binary CHOLEST_LST_CHCK HEART_ATTACK HEART_DISEASE_DIAG high_blood_pressure_diag LAST_FLUSHOT LAST_MAMMOGRAM LOST_ALL_TEETH;
	MODEL diabetes_diag_binary(EVENT="1") = bmi AGE PERSON_WEIGHT TOTAL_INCOME CHOLEST_LST_CHCK HEART_ATTACK HEART_DISEASE_DIAG high_blood_pressure_diag 
											LAST_FLUSHOT LAST_MAMMOGRAM LOST_ALL_TEETH;
	SCORE DATA=adultf_bmi_redu OUT=adultf_pred1;
RUN;

DATA adultf_pred1;
	SET adultf_pred1;
	IF i_diabetes_diag_binary = '0' THEN diabetes_diag_binary = 0;
	ELSE IF i_diabetes_diag_binary = '1' THEN diabetes_diag_binary = 1;
	ELSE diabetes_diag_binary = .;
RUN;

** 3) Male Adults;
%resp_review(adultm) * Notice the number of diabetes events is 1152;

PROC SURVEYSELECT DATA=adultm METHOD=SRS N=(1348, 1152) SEED=1357
	OUT=adultm_sampled;
	STRATA diabetes_diag_binary;
RUN;

DATA adultm_bmi_redu;
	SET adultm;
	IF bmi >= 25;
	bmi = 0.9*bmi;
RUN;

PROC LOGISTIC DATA=adultm_sampled;
	CLASS angina_diagnosis asthma_diagnosis bld_stool_tst census_region cholest_lst_chck currently_smoke dental_checkup diabetes_diag_binary emphysema_diagnosis
          foodstamps_purchase heart_attack heart_disease_diag high_blood_pressure_diag highest_degree joint_pain last_checkup last_flushot
          last_psa lost_all_teeth marital_status other_heart_disease served_armed_forces sigmoidoscopy_colonoscopy stroke_diagnosis
          wear_hearing_aid wear_seat_belt wears_eyeglasses years_educ;
	MODEL diabetes_diag_binary(EVENT="1") = bmi age numb_visits person_weight total_income
          									angina_diagnosis asthma_diagnosis bld_stool_tst census_region cholest_lst_chck currently_smoke dental_checkup 
											emphysema_diagnosis foodstamps_purchase heart_attack heart_disease_diag high_blood_pressure_diag 
											highest_degree joint_pain last_checkup last_flushot last_psa lost_all_teeth marital_status other_heart_disease 
											served_armed_forces sigmoidoscopy_colonoscopy stroke_diagnosis wear_hearing_aid wear_seat_belt wears_eyeglasses years_educ
										    /SELECTION=STEPWISE;
RUN;
***** Refit and score the whold data;
PROC LOGISTIC DATA=adultm_sampled;
	CLASS diabetes_diag_binary CHOLEST_LST_CHCK FOODSTAMPS_PURCHASE HEART_DISEASE_DIAG HIGH_BLOOD_PRESSURE_DIAG HIGHEST_DEGREE LAST_FLUSHOT;
	MODEL diabetes_diag_binary(EVENT="1") = BMI AGE NUMB_VISITS PERSON_WEIGHT TOTAL_INCOME 
											CHOLEST_LST_CHCK FOODSTAMPS_PURCHASE HEART_DISEASE_DIAG HIGH_BLOOD_PRESSURE_DIAG HIGHEST_DEGREE LAST_FLUSHOT ;
	SCORE DATA=adultm_bmi_redu OUT=adultm_pred1;
RUN;

DATA adultm_pred1;
	SET adultm_pred1;
	IF i_diabetes_diag_binary = '0' THEN diabetes_diag_binary = 0;
	ELSE IF i_diabetes_diag_binary = '1' THEN diabetes_diag_binary = 1;
	ELSE diabetes_diag_binary = .;
RUN;

* Model totalexp;
* Using multiple regression;
ODS GRAPHICS ON;
** 1) Children;
PROC GLMSELECT DATA=children PLOTS=CRITERIONPANEL;
	CLASS asthma_diagnosis census_region dental_checkup foodstamps_purchase sex wear_hearing_aid wears_eyeglasses years_educ diabetes_diag_binary;
	MODEL totalexp = asthma_diagnosis census_region dental_checkup foodstamps_purchase sex wear_hearing_aid 
					 diabetes_diag_binary wears_eyeglasses years_educ age bmi numb_visits person_weight total_income
					 /SELECTION=STEPWISE;
RUN;

PROC GLM DATA=children;
	CLASS ASTHMA_DIAGNOSIS diabetes_diag_binary;
	MODEL totalexp = NUMB_VISITS ASTHMA_DIAGNOSIS age diabetes_diag_binary/SOLUTION;
	STORE children_reg;
RUN;

PROC PLM RESTORE=children_reg;
	SCORE DATA=children_pred1 OUT=children_pred;
RUN;

** 2) Female Adult;
PROC GLMSELECT DATA=adultf PLOTS=CRITERIONPANEL;
	CLASS angina_diagnosis asthma_diagnosis bld_stool_tst census_region cholest_lst_chck currently_smoke dental_checkup emphysema_diagnosis
          foodstamps_purchase heart_attack heart_disease_diag high_blood_pressure_diag highest_degree joint_pain last_breast_exam last_checkup last_flushot
          last_mammogram last_pap_smear lost_all_teeth marital_status other_heart_disease served_armed_forces sigmoidoscopy_colonoscopy stroke_diagnosis
          wear_hearing_aid wear_seat_belt wears_eyeglasses years_educ;
	MODEL totalexp = bmi age numb_visits person_weight total_income
          			 angina_diagnosis asthma_diagnosis bld_stool_tst census_region cholest_lst_chck 
					 currently_smoke dental_checkup emphysema_diagnosis
          			 foodstamps_purchase heart_attack heart_disease_diag high_blood_pressure_diag highest_degree 
					 joint_pain last_breast_exam last_checkup last_flushot last_mammogram last_pap_smear lost_all_teeth 
					 marital_status other_heart_disease served_armed_forces sigmoidoscopy_colonoscopy stroke_diagnosis
          			 wear_hearing_aid wear_seat_belt wears_eyeglasses years_educ
					 /SELECTION=STEPWISE;
RUN;

PROC GLM DATA=adultf;
	CLASS HEART_DISEASE_DIAG DIABETES_DIAG_BINARY OTHER_HEART_DISEASE HEART_ATTACK STROKE_DIAGNOSIS JOINT_PAIN EMPHYSEMA_DIAGNOSIS SIGMOIDOSCOPY_COLONOSCOPY 
		  ASTHMA_DIAGNOSIS HIGH_BLOOD_PRESSURE_DIAG LOST_ALL_TEETH;
	MODEL totalexp = diabetes_diag_binary NUMB_VISITS HEART_DISEASE_DIAG OTHER_HEART_DISEASE HEART_ATTACK STROKE_DIAGNOSIS JOINT_PAIN 
					 EMPHYSEMA_DIAGNOSIS SIGMOIDOSCOPY_COLONOSCOPY ASTHMA_DIAGNOSIS HIGH_BLOOD_PRESSURE_DIAG LOST_ALL_TEETH/SOLUTION;
	STORE adultf_reg;
RUN;

PROC PLM RESTORE=adultf_reg;
	SCORE DATA=adultf_pred1 OUT=adultf_pred;
RUN;

** 3) Male Adult;
PROC GLMSELECT DATA=adultm PLOTS=CRITERIONPANEL;
	CLASS angina_diagnosis asthma_diagnosis bld_stool_tst census_region cholest_lst_chck currently_smoke dental_checkup 
		  emphysema_diagnosis foodstamps_purchase heart_attack heart_disease_diag high_blood_pressure_diag 
		  highest_degree joint_pain last_checkup last_flushot last_psa lost_all_teeth marital_status other_heart_disease 
		  served_armed_forces sigmoidoscopy_colonoscopy stroke_diagnosis wear_hearing_aid wear_seat_belt wears_eyeglasses years_educ diabetes_diag_binary;
	MODEL totalexp = bmi age numb_visits person_weight total_income
          			 angina_diagnosis asthma_diagnosis bld_stool_tst census_region cholest_lst_chck currently_smoke dental_checkup 
					 emphysema_diagnosis foodstamps_purchase heart_attack heart_disease_diag high_blood_pressure_diag 
					 highest_degree joint_pain last_checkup last_flushot last_psa lost_all_teeth marital_status other_heart_disease 
					 served_armed_forces sigmoidoscopy_colonoscopy stroke_diagnosis wear_hearing_aid wear_seat_belt wears_eyeglasses years_educ diabetes_diag_binary
					 /SELECTION=STEPWISE;
RUN;

PROC GLM DATA=adultm;
	CLASS HEART_DISEASE_DIAG HEART_ATTACK OTHER_HEART_DISEASE STROKE_DIAGNOSIS DIABETES_DIAG_BINARY EMPHYSEMA_DIAGNOSIS JOINT_PAIN 
          SIGMOIDOSCOPY_COLONOSCOPY ASTHMA_DIAGNOSIS CHOLEST_LST_CHCK FOODSTAMPS_PURCHASE;
	MODEL totalexp = NUMB_VISITS HEART_DISEASE_DIAG AGE HEART_ATTACK OTHER_HEART_DISEASE STROKE_DIAGNOSIS DIABETES_DIAG_BINARY EMPHYSEMA_DIAGNOSIS JOINT_PAIN 
                     SIGMOIDOSCOPY_COLONOSCOPY ASTHMA_DIAGNOSIS CHOLEST_LST_CHCK FOODSTAMPS_PURCHASE;
	STORE adultm_reg;
RUN;

PROC PLM RESTORE=adultm_reg;
	SCORE DATA=adultm_pred1 OUT=adultm_pred;
RUN;

* Review Total Expense Saving Results;
TITLE "Predicted Total Savings for the Diabetes Prevention Program: Reduction of BMI by 10%";
PROC SQL;
	SELECT sv_children AS Saving_for_Children, sv_adultf AS Saving_for_Women, sv_adultm AS Saving_for_Men, (sv_children + sv_adultf + sv_adultm) AS Total_Savings
	FROM (SELECT SUM(totalexp - predicted) AS sv_children FROM children_pred WHERE f_diabetes_diag_binary = '1' AND i_diabetes_diag_binary = '0'),
	     (SELECT SUM(totalexp - predicted) AS sv_adultf   FROM adultf_pred   WHERE f_diabetes_diag_binary = '1' AND i_diabetes_diag_binary = '0'),
	     (SELECT SUM(totalexp - predicted) AS sv_adultm   FROM adultm_pred   WHERE f_diabetes_diag_binary = '1' AND i_diabetes_diag_binary = '0');
QUIT;

ODS GRAPHICS OFF;
TITLE;
** END OF CODE; **



