/* MACRO: Missing Value Imputation
 */


* Define MACRO: impute_median;
%MACRO impute_median(table, variable);
	PROC SQL;
		CREATE TABLE &variable._median AS
			SELECT DISTINCT age, MEDIAN(&variable) AS &variable._med
			FROM &table
			WHERE &variable IS NOT NULL
			GROUP BY age;
		
		CREATE TABLE temp AS
			SELECT t.*, med.&variable._med
			FROM &table t
			INNER JOIN
			&variable._median med
			ON t.age = med.age;
	QUIT;

	DATA &table;
		SET temp;
		IF &variable = . THEN &variable = &variable._med;
		DROP &variable._med;
	RUN;
%MEND;

* Define MACRO: impute_mode;
%MACRO impute_mode(table, variable);
	PROC SQL;
		CREATE TABLE &variable._mode AS
			SELECT age, &variable AS &variable._mod
			FROM
			    (SELECT age, &variable, last
			     FROM
			        (SELECT age, &variable, count(*) AS n, MAX(order) AS last
			         FROM &table
			         GROUP BY age, &variable)
			     GROUP BY age
			     HAVING n = MAX(n))
			GROUP BY age
			HAVING last = MAX(last); 
		
		CREATE TABLE temp AS
			SELECT t.*, mod.&variable._mod
			FROM &table t
			INNER JOIN
			&variable._mode mod
			ON t.age = mod.age;
	QUIT;

	DATA &table;
		SET temp;
		IF &variable = . THEN &variable = &variable._mod;
		DROP &variable._mod;
	RUN;
%MEND;

* Define MACRO: impute_all;
%MACRO impute_all(table);
	* Get the variable list from metadata;
	PROC CONTENTS DATA=&table OUT=&table._meta NOPRINT; RUN;
	DATA &table._meta;
		SET &table._meta;
		IF name ^= 'AGE';
	RUN;

	* Write variable list into a MACRO variable;
	PROC SQL NOPRINT;
		SELECT name INTO: varlist SEPARATED BY ' ' FROM &table._meta;
		%LET n = &sqlobs;
	QUIT;

	%DO i=1 %TO &n;
		%LET current_var = %SCAN(&varlist, &i);
		PROC SQL NOPRINT;
			SELECT COUNT(DISTINCT &current_var) INTO: numlevel
			FROM &table
			WHERE &current_var IS NOT NULL;
		QUIT;

		%IF &numlevel > 19 %THEN %DO;
			%impute_median(&table, &current_var)
		%END;
		%ELSE %DO;
			%impute_mode(&table, &current_var)
		%END;
	%END;
%MEND;