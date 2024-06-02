// ============================================================================
//
// NPM -- 1.6.0
//
// ============================================================================
cd ~/Dropbox/Papers/10_WorkInProgress/VulnerabilityContagion/Data/NPM-1.6.0Wyss/

// prepare Wyss data
insheet using Wyss_npm_data5.csv, names delimiter(";") clear
	egen foo = max(downloads)
	gen rel_down = downloads / foo
	drop foo
	
	egen foo = max(size)
	gen rel_size = size / foo
	drop foo

	egen foo = max(versions)
	gen rel_versions = versions / foo
	drop foo
	
	order id_repo id_repo_new repo repo_user repository rel_down vulnerabilities issues_per_download size rel_size versions rel_versions

save Wyss_npm_data5.dta, replace
outsheet using Wyss_npm_data6.csv, names delimiter(";") replace

// prepare gephi data
insheet using gephi_repo_dependencies_NPM-matchedWyss+newIDs.csv, clear nonames
	drop v2 v3
	rename v1 id_repo_new
	rename v4 in_degree
	rename v5 out_degree
	drop v6
	rename v7 ev_centrality
	sort id_repo_new
save gephi_repo_dependencies_NPM-matchedWyss+newIDs.dta, replace


// load equilibria
insheet using equilibria_repo_dependencies_NPM-matchedWyss+newIDs-0.005-5.csv, delimiter(" ") names clear
	gen id_repo = i + 1 
	drop i
	order id_repo 
	rename id_repo id_repo_new

	gen log_svfb = log(svfb)
	
	gen d_p = (p_eq - p_so) / p_eq
	gen d_q = (q_eq - q_so) / q_eq 

merge 1:1 id_repo_new using Wyss_npm_data5.dta 
	keep if _merge == 3
	drop _merge
merge 1:1 id_repo_new using gephi_repo_dependencies_NPM-matchedWyss+newIDs.dta
	keep if _merge == 3
	drop _merge
save "Master.dta", replace


use "Master.dta", clear
	scatter svfb d_p
graph export "scatter_svfb_d_p.png", as(png) name("Graph") replace	



insheet using "output_delta_calibration.csv", delimiter(" ") clear
	rename v1 delta
	rename v2 dist

// 	twoway (line dist delta, lcolor(black) lpattern(solid)), yrange(2 2.2)
//	
// 	twoway (line dist delta, lcolor(black) lpattern(solid)) ///
//        (scatteri 2.044944 0.0036, mlabel("Minimum") mlabposition(6) mcolor(red) msymbol(Oh)) ///
//        , yscale(range(2 2.2)) ylabel(2(0.05)2.2, nogrid)

twoway (line dist delta, lcolor(black) lpattern(solid)) ///
       (scatteri 2.044944 0.0036, mlabposition(6) mcolor(red) msymbol(Oh)) ///
       (function y=2.044944, range(0 0.005) lpattern(dash) lcolor(blue) lwidth(thin)) ///
       , yscale(range(2 2.2)) ylabel(2(0.05)2.2) xline(0.0036, lpattern(dash) lcolor(blue) lwidth(thin)) legend(off)

graph export dist_delta.png, as(png) replace


// load single equilibrium file
insheet using repo_dependencies_NPM-matchedWyss+newIDs/equilibria_0.004-5.csv, delimiter(" ") names clear
	hist theta
	hist pobs
	hist p_eq



// 	scatter p_eq theta
// graph export "scatter_p_eq-theta.png", as(png) name("Graph") replace
// 	scatter p_so theta
// graph export "scatter_p_so-theta.png", as(png) name("Graph") replace
//
// 	reg p_eq theta
// 	reg p_so theta

	
// insheet using summary_repo_dependencies_NPM-matchedWyss+newIDs-0.005-5.csv, delimiter(";") nonames clear
// 	rename v1 delta
// 	rename v2 colnum
// 	rename v3 tcd_eq
// 	rename v4 tcf_eq
// 	rename v5 tcd_so
// 	rename v6 tcf_so
//	
// 	set scheme s1mono
// 	gen log_tcf_so = log(tcf_so)
// 	gen log_tcf_eq = log(tcf_eq)
//	
// 	gen frac_tcf = tcf_eq / tcf_so
// 	gen log_frac_tcf = log(frac_tcf)
//	
// twoway (line log_tcf_so delta, lcolor(black) lpattern(solid)) ///
//        (line log_tcf_eq delta, lcolor(black) lpattern(dash)), ///
//        legend(label(1 "log(tcf_so)") label(2 "log(tcf_eq)")) ///
//        ylabel(, format(%10.0g)) ///
//        title("Plot of log(tcf_so) and log(tcf_eq) vs. delta")	
// graph export tcf_eqso_delta.png, as(png) replace
//
// twoway (line frac_tcf delta, lcolor(black) lpattern(solid)), ///
//        legend(label(1 "tcf_eq/tcf_so")) ///
//        ylabel(, format(%10.0g)) ///
//        title("Plot of tcf_eq/tcf_so vs. delta")	
// graph export fractcf_delta.png, as(png) replace






	


// ============================================================================
//
// Cargo -- 1.6.0
//
// ============================================================================
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo-1.6.0/

// ----------------------------------------------------------------------------
//
// PREPARATION
//
// ----------------------------------------------------------------------------

//
// SAMPLED DATA -- CREATE PROPER IDs FOR EQUILIBRIUM COMPUTATION
// NOTE: ./33_sample_network.py needs to be executed first
// 
{
// create list of consecutive and unique ids
insheet using "sampled-0.01_dependencies_Cargo-repo2-matched-lcc.edgelist", delimiter(" ") clear
	drop v3
	rename v1 repo_name
	drop v2 
save "tmp.dta", replace
insheet using "sampled-0.01_dependencies_Cargo-repo2-matched-lcc.edgelist", delimiter(" ") clear
	drop v3
	drop v1
	rename v2 repo_name
append using tmp.dta
	duplicates drop
	sort repo_name
	gen id_sample = _n
outsheet using "sampled_ids.csv", delimiter(";") replace
save "sampled_ids.dta", replace

// now create sampled covariate data 
insheet using "20_master_Cargo-matched.csv", delimiter(";") clear
merge 1:1 repo_name using sampled_ids.dta
	keep if _merge == 3
	drop _merge
	order id_sample 
	drop id_repo
outsheet using "sampled-0.01_20_master_Cargo-matched.csv", delimiter(";") replace	

// restrict popularity within reasonable bounds
// insheet using "20_master_Cargo-matched.csv", delimiter(";") clear
//  	winsor2 popularity, replace cuts(0,99) trim
//  	replace popularity = . if popularity == 0
//	
//  	drop if popularity == .
// 	keep repo_name
// 	sort repo_name
// 	gen id_sample = _n
// save sampled_ids.dta, replace
// outsheet using sampled_ids.csv, delimiter(";") replace
}

// full sample
insheet using "20_master_Cargo-matched.csv", delimiter(";") clear
	keep repo_name
	sort repo_name
	gen id_sample = _n
save sampled_ids-all.dta, replace
outsheet using sampled_ids-all.csv, delimiter(";") replace


//
// apply cuts to covariates
//
insheet using "20_master_Cargo-matched.csv", delimiter(";") clear
// merge 1:1 repo_name using sampled_ids.dta // with cuts applied above
merge 1:1 repo_name using sampled_ids-all.dta // without cuts
	keep if _merge == 3
	drop _merge 
	order id_sample
	drop id_repo
outsheet using 20_master_Cargo-matched-cut.csv, delimiter(";") replace
save 20_master_Cargo-matched-cut.dta, replace

// transform size for computation of theta
insheet using "20_master_Cargo-matched.csv", delimiter(";") clear
// merge 1:1 repo_name using sampled_ids.dta
merge 1:1 repo_name using sampled_ids-all.dta
	keep if _merge == 3
	drop _merge 
	order id_sample
	drop id_repo
outsheet using 20_master_Cargo-matched-all.csv, delimiter(";") replace
save 20_master_Cargo-matched-all.dta, replace


//
// apply cuts to dependencies
//
insheet using "dependencies_Cargo-repo2-matched-lcc.csv", delimiter(" ") clear
	drop v3 v4
	
	rename v1 repo_name 
// merge m:1 repo_name using sampled_ids.dta // with cuts
merge m:1 repo_name using sampled_ids-all.dta // without cuts
	keep if _merge == 3
	drop _merge 
	rename id_sample v1 
	drop repo_name
	
	rename v2 repo_name 
merge m:1 repo_name using sampled_ids-all.dta
// merge m:1 repo_name using sampled_ids.dta
	keep if _merge == 3
	drop _merge 
	rename id_sample v2 
	drop repo_name

	sort v1 v2 
outsheet using "dependencies_Cargo-repo2-matched-lcc-cut.edgelist", delimiter(" ") replace nonames


//
// further cleaning -- dependencies
//
// some repositories are dropped because their only links are to repos that have been cut before
insheet using "dependencies_Cargo-repo2-matched-lcc-cut.edgelist", delimiter(" ") clear 
	keep v1 
	duplicates drop
save "tmp.dta", replace

insheet using "dependencies_Cargo-repo2-matched-lcc-cut.edgelist", delimiter(" ") clear 
	drop v1 
	rename v2 v1
append using "tmp.dta"
	duplicates drop
	sort v1
rename v1 repo_name
	gen id_sample = _n
save "ids_existing_repo.dta", replace

// now merge again as before
insheet using "dependencies_Cargo-repo2-matched-lcc-cut.edgelist", delimiter(" ") clear 
	rename v1 repo_name 
merge m:1 repo_name using ids_existing_repo.dta
	keep if _merge == 3
	drop _merge 
	rename repo_name v1
	drop id_sample 
	
	rename v2 repo_name 
merge m:1 repo_name using ids_existing_repo.dta
	keep if _merge == 3
	drop _merge 
	rename repo_name v2
	drop id_sample 

	sort v1 v2
outsheet using "dependencies_Cargo-repo2-matched-lcc-cut2.edgelist", delimiter(" ") replace nonames


//
// further cleaning -- covariates
//
use 20_master_Cargo-matched-cut.dta, clear
	drop repo_name // old repo name
	rename id_sample repo_name // we match on this, a bit messy, but makes sense
merge 1:1 repo_name using ids_existing_repo.dta
	keep if _merge == 3
	drop _merge
	order id_sample 
	drop repo_name  // popularity must be column 4
	
	// VARIANT 1
// 	egen dec_pop = cut(popularity), group(10)
// 	order id_sample projectname size dec_pop 
	
	// VARIANT 2
	gen log_pop = log(1+popularity)
	egen max_pop = max(log_pop)
	gen rel_pop = log_pop / max_pop

	gen log_size = log(1 + size)  // the 1 + ensures that log(x) is never 0 which causes issues in q,p computations
	egen max_size = max(log_size)
	gen rel_size = log_size / max_size 
	
	
	gen size_inv = 1.0/rel_size
	
	order id_sample projectname rel_pop rel_size log_size size
save 20_master_Cargo-matched-cut2.dta, replace
outsheet using 20_master_Cargo-matched-cut2.csv, delimiter(";") replace 


// ----------------------------------------------------------------------------
//
// ANALYSIS
//
// ----------------------------------------------------------------------------
// analyze q,p
insheet using equilibria_dependencies_Cargo-repo2-matched-lcc-cut2.csv, delimiter(" ") clear
// 	rename v1 q_eq
// 	rename v2 p_eq 
// 	rename v3 q_so 
// 	rename v4 p_so

	gen d_p = (p_eq - p_so) / p_eq
	gen d_q = (q_eq - q_so) / q_eq 
	
	scatter p_eq theta
	graph export "scatter_p_eq-theta.png", as(png) name("Graph") replace
	scatter p_so theta
	graph export "scatter_p_so-theta.png", as(png) name("Graph") replace

	reg p_eq theta
	reg p_so theta

	scatter d_p theta
	reg d_p theta
	
	

insheet using summary_tcdtcf.csv, delimiter(";") nonames clear
	rename v1 delta
	rename v2 colnum
	rename v3 tcd_eq
	rename v4 tcf_eq
	rename v5 tcd_so
	rename v6 tcf_so
	
	set scheme s1mono
	gen log_tcf_so = log(tcf_so)
	gen log_tcf_eq = log(tcf_eq)
	
	gen frac_tcf = tcf_eq / tcf_so
	gen log_frac_tcf = log(frac_tcf)
	
twoway (line log_tcf_so delta, lcolor(black) lpattern(solid)) ///
       (line log_tcf_eq delta, lcolor(black) lpattern(dash)), ///
       legend(label(1 "log(tcf_so)") label(2 "log(tcf_eq)")) ///
       ylabel(, format(%10.0g)) ///
       title("Plot of log(tcf_so) and log(tcf_eq) vs. delta")	
graph export tcf_eqso_delta.png, as(png) replace

twoway (line frac_tcf delta, lcolor(black) lpattern(solid)), ///
       legend(label(1 "tcf_eq/tcf_so")) ///
       ylabel(, format(%10.0g)) ///
       title("Plot of tcf_eq/tcf_so vs. delta")	
graph export fractcf_delta.png, as(png) replace


local net_values star_in
local dist_values equal log_normal

foreach dist_value of local dist_values {
	foreach net_value of local net_values {
		insheet using summary_test-`net_value'-`dist_value'.csv, delimiter(";") nonames clear
			rename v1 delta 
			rename v2 theta
			rename v3 num_nodes 
			rename v4 tcd_eq 
			rename v5 tcf_eq 
			rename v6 tcd_so 
			rename v7 tcf_so
		save "summary_test-`net_value'-`dist_value'.dta", replace	
	}
}


use summary_test-star_in-equal.dta, clear
	rename tcd_eq star_in_equal_tcd_eq
	rename tcf_eq star_in_equal_tcf_eq
	rename tcd_so star_in_equal_tcd_so
	rename tcf_so star_in_equal_tcf_so 
	
merge 1:1 delta theta num_nodes using summary_test-star_in-log_normal.dta
	keep if _merge == 3
	drop _merge
	
	twoway ///
		(line star_in_equal_tcf_eq num_nodes, lcolor(black) lpattern(solid)) ///
		(line star_in_equal_tcf_so num_nodes, lcolor(black) lpattern(dash))
	graph export star_in_equal_tcf.png, as(png) replace
	
	twoway ///
		(line tcf_eq num_nodes, lcolor(black) lpattern(solid)) ///
		(line tcf_so num_nodes, lcolor(black) lpattern(dash))
	graph export star_in_log_normal_tcf.png, as(png) replace
	

// ============================================================================
//
// Pypi -- 1.6.0
//
// ============================================================================
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Pypi-1.6.0/

// ----------------------------------------------------------------------------
//
// PREPARATION
//
// ----------------------------------------------------------------------------

// full sample
insheet using "20_master_Pypi-matched.csv", delimiter(";") clear
	keep repo_name
	sort repo_name
	gen id_sample = _n
save sampled_ids-all.dta, replace
outsheet using sampled_ids-all.csv, delimiter(";") replace


//
// apply cuts to covariates
//
insheet using "20_master_Pypi-matched.csv", delimiter(";") clear
// merge 1:1 repo_name using sampled_ids.dta // with cuts applied above
merge 1:1 repo_name using sampled_ids-all.dta // without cuts
	keep if _merge == 3
	drop _merge 
	order id_sample
	drop id_repo
outsheet using 20_master_Pypi-matched-cut.csv, delimiter(";") replace
save 20_master_Pypi-matched-cut.dta, replace

// transform size for computation of theta
insheet using "20_master_Pypi-matched.csv", delimiter(";") clear
// merge 1:1 repo_name using sampled_ids.dta
merge 1:1 repo_name using sampled_ids-all.dta
	keep if _merge == 3
	drop _merge 
	order id_sample
	drop id_repo
outsheet using 20_master_Pypi-matched-all.csv, delimiter(";") replace
save 20_master_Pypi-matched-all.dta, replace


//
// apply cuts to dependencies
//
insheet using "dependencies_Pypi-repo2-matched-lcc.edgelist", delimiter(" ") clear
	drop v3 v4
	
	rename v1 repo_name 
// merge m:1 repo_name using sampled_ids.dta // with cuts
merge m:1 repo_name using sampled_ids-all.dta // without cuts
	keep if _merge == 3
	drop _merge 
	rename id_sample v1 
	drop repo_name
	
	rename v2 repo_name 
merge m:1 repo_name using sampled_ids-all.dta
// merge m:1 repo_name using sampled_ids.dta
	keep if _merge == 3
	drop _merge 
	rename id_sample v2 
	drop repo_name

	sort v1 v2 
outsheet using "dependencies_Pypi-repo2-matched-lcc-cut.edgelist", delimiter(" ") replace nonames


//
// further cleaning -- dependencies
//
// some repositories are dropped because their only links are to repos that have been cut before
insheet using "dependencies_Pypi-repo2-matched-lcc-cut.edgelist", delimiter(" ") clear 
	keep v1 
	duplicates drop
save "tmp.dta", replace

insheet using "dependencies_Pypi-repo2-matched-lcc-cut.edgelist", delimiter(" ") clear 
	drop v1 
	rename v2 v1
append using "tmp.dta"
	duplicates drop
	sort v1
rename v1 repo_name
	gen id_sample = _n
save "ids_existing_repo.dta", replace

// now merge again as before
insheet using "dependencies_Pypi-repo2-matched-lcc-cut.edgelist", delimiter(" ") clear 
	rename v1 repo_name 
merge m:1 repo_name using ids_existing_repo.dta
	keep if _merge == 3
	drop _merge 
	rename repo_name v1
	drop id_sample 
	
	rename v2 repo_name 
merge m:1 repo_name using ids_existing_repo.dta
	keep if _merge == 3
	drop _merge 
	rename repo_name v2
	drop id_sample 

	sort v1 v2
outsheet using "dependencies_Pypi-repo2-matched-lcc-cut2.edgelist", delimiter(" ") replace nonames


//
// further cleaning -- covariates
//
use 20_master_Pypi-matched-cut.dta, clear
	drop repo_name // old repo name
	rename id_sample repo_name // we match on this, a bit messy, but makes sense
merge 1:1 repo_name using ids_existing_repo.dta
	keep if _merge == 3
	drop _merge
	order id_sample 
	drop repo_name  // popularity must be column 4
	
	// VARIANT 1
// 	egen dec_pop = cut(popularity), group(10)
// 	order id_sample projectname size dec_pop 
	
	// VARIANT 2
	gen log_pop = log(1+popularity)
	egen max_pop = max(log_pop)
	gen rel_pop = log_pop / max_pop

	gen log_size = log(1 + size)  // the 1 + ensures that log(x) is never 0 which causes issues in q,p computations
	egen max_size = max(log_size)
	gen rel_size = log_size / max_size 
	
	
	gen size_inv = 1.0/rel_size
	
	order id_sample projectname rel_pop rel_size log_size size
save 20_master_Pypi-matched-cut2.dta, replace
outsheet using 20_master_Pypi-matched-cut2.csv, delimiter(";") replace 


// ----------------------------------------------------------------------------
//
// ANALYSIS
//
// ----------------------------------------------------------------------------
// analyze q,p
insheet using equilibria_dependencies_Pypi-repo2-matched-lcc-cut2.csv, delimiter(" ") clear
// 	rename v1 q_eq
// 	rename v2 p_eq 
// 	rename v3 q_so 
// 	rename v4 p_so

	gen d_p = (p_eq - p_so) / p_eq
	gen d_q = (q_eq - q_so) / q_eq 
	
	scatter p_eq theta
	graph export "scatter_p_eq-theta.png", as(png) name("Graph") replace
	scatter p_so theta
	graph export "scatter_p_so-theta.png", as(png) name("Graph") replace

	reg p_eq theta
	reg p_so theta

	scatter d_p theta
	reg d_p theta
	
	
	
	
// ============================================================================
// ============================================================================	




// ============================================================================
//
// Pypi -- 1.6.0 -- DEPRECATED
//
// ============================================================================

//
// PREPARE FILES
//
// cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Pypi-1.6.0/

// repositories
cd ~/Downloads/Pypi/
insheet using "repositories_Pypi.csv", delimiter(";") names clear
	drop if repoid == "RepoID"
	destring size, replace
	destring numstars, replace
	destring numforks, replace
	destring numwatchers, replace
	destring numcontributors, replace

	destring repoid, replace
save "repositories_Pypi.dta", replace

// projects
cd ~/Downloads/Pypi/
insheet using "projects_Pypi.csv", delimiter(";") names clear
	drop if id == "ID"
	destring id, replace
	drop if repoid == "https://github.com/yochem/minicss" | repoid == "OpenWRT Kali KaliLinux"
	destring repoid, replace

save "projects_Pypi.dta", replace
	rename id projectid
	keep projectid repoid
	
	drop if repoid == .
save projectid_repoid.dta, replace 

// DEPENDENCIES
//
// NB (from libraries.io):  Dependencies describe the relationship between a project and the software it builds upon. Dependencies belong to Version. Each Version can have different sets of dependencies. Dependencies point at a specific Version or range of versions of other projects.
cd ~/Downloads/Pypi/
insheet using "dependencies_Pypi.csv", delimiter(";") names clear
	drop if projectname == "ProjectName"
	drop projectname
	
	destring projectid, replace
merge m:1 projectid using projectid_repoid.dta
	keep if _merge == 3
	drop _merge
	
	rename projectid from_project_id
	rename repoid from_repo_id
	
	drop if dependencyprojectid == ""
	destring dependencyprojectid, replace
	rename dependencyprojectid projectid
merge m:1 projectid using projectid_repoid.dta
	keep if _merge == 3
	drop _merge

	rename projectid to_project_id
	rename repoid to_repo_id
save repo_match_dependencies_Pypi.dta, replace
	keep to_repo_id from_repo_id
	duplicates drop
outsheet using "dependencies_Pypi-repo.csv", delimiter(";") replace
save "dependencies_Pypi-repo.dta", replace  // 85,895 observations

// REPO DEPENDENCIES 
//
// NB (from libraries.io): A repository dependency is a dependency upon a Version from a package manager has been specified in a manifest file, either as a manually added dependency committed by a user or listed as a generated dependency listed in a lockfile that has been automatically generated by a package manager and committed.
cd ~/Downloads/Pypi
insheet using repo_dependencies_Pypi.csv, names delimiter(";") clear
	drop id 
	drop projectname dependencyprojectname
	drop dependencyrequirements
	
	drop if dependencyprojectid == ""
	drop if dependencyprojectid == "DependencyProjectID"
	
	destring dependencyprojectid, replace
	rename dependencyprojectid projectid
	
	// repoid already exists
	rename repoid from_repo_id
	destring from_repo_id, replace
	
	// match dependencyproject
	drop if dependencyprojectid == ""
	destring dependencyprojectid, replace
	rename dependencyprojectid projectid
merge m:1 projectid using projectid_repoid.dta
	keep if _merge == 3
	drop _merge

	rename projectid to_project_id
	rename repoid to_repo_id
save repo_match_dependencies_Pypi2.dta, replace
	keep to_repo_id from_repo_id
	duplicates drop
outsheet using "dependencies_Pypi-repo2.csv", delimiter(";") replace
save "dependencies_Pypi-repo2.dta", replace // 3,676,078 observations


//
// Pypi -- MAIN ANALYSIS -- REPO LEVEL
//
// PREPARE CENTRALITIES
cd ~/Downloads/Pypi
insheet using gephi_analysis_dependencies_Pypi-repo2.csv, clear names
	drop v2 v3
	rename v1 repoid 
	rename v4 in_degree
	rename v5 out_degree
	drop v6
	rename v7 ev_centrality
	label var ev_centrality "Eigenvector Centrality"
save analysis_dependencies_Pypi-repo2-lcc.dta, replace

// CREATE MASTER DATASET
cd ~/Downloads/Pypi
use repositories_Pypi.dta, clear
	drop description 
	sort repoid

merge 1:1 repoid using analysis_dependencies_Pypi-repo2-lcc.dta
	keep if _merge == 3. // we lose 1,752,429 out of 2,181,356 obs
	drop _merge

	rename size Size
	rename numcontributors NumContributors
	
	drop if Size == 0  // some packages have zero size
	rename numstars Popularity

	// truncate
// 	winsor2 ev_centrality, replace cuts(0 95) trim
// 	winsor2 katz_centrality, replace cuts(0 95) trim
// 	winsor2 indeg_centrality, replace cuts(0,95) trim
// 	winsor2 in_degree, replace cuts(0,99) trim
// 	winsor2 out_degree, replace cuts(0,99) trim
	winsor2 Popularity, replace cuts(0 99) trim
	winsor2 NumContributors, replace cuts(0 99) trim
	
	// look at most central packages manually
	gsort - ev_centrality 
	
	// simple scatter plot
	scatter Popularity ev_centrality
	graph export pypi_popularity-ev_centrality.jpg, replace
		
	label variable in_degree "in-degree"
	label variable out_degree "out-degree"
	scatter in_degree out_degree 
	graph export pypi_indeg-outdeg.jpg, replace
	
	// binscatter
	binscatter Popularity ev_centrality
	graph export pypi_bs_popularity-ev_centrality.jpg, replace
		
	// number of contributors vs popularity
	binscatter NumContributors Popularity
	graph export pypi_bs_t99_numcontributors_popularity.jpg, replace
	
	// regressions
	regress Popularity NumContributors
	regress Popularity ev_centrality
	
	// 
	// activity vs. popularity plots
	//
	gen top_pop = 0
	replace top_pop = 1 if Popularity > 164 // 99pct
	gen bot_pop = 0 
	replace bot_pop = 1 if Popularity == 0 // 50pct
	
	gen top_ev_cent = 0
	replace top_ev_cent = 1 if ev_centrality > 0.0596552 // 99pct
	gen bot_ev_cent = 0
	replace bot_ev_cent = 1 if ev_centrality <= 0.0025848  // 50pct
	
// 	gen top_indeg_cent = 0
// 	replace top_indeg_cent = 1 if indeg_centrality > 0.0000629 // 99pct
// 	gen bot_indeg_cent = 0
// 	replace bot_indeg_cent = 1 if indeg_centrality <= 0.00000932 // 50 pct

save tmp_10_popularity_centrality-repo.dta, replace


//
// CENTRALTIES
//
// KATZ CENTRALITY VS. POPULARITY
cd ~/Downloads/Pypi
use tmp_10_popularity_centrality-repo.dta, clear
	
	keep if top_ev_cent == 1 | top_pop == 1
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_ev_cent == 1
	hist logSize if top_pop == 1
	
	hist NumContributors if top_ev_cent == 1
	hist NumContributors if top_pop == 1
	
	twoway (hist logSize if top_ev_cent == 1, start(-15) width(1) color(red%30)) ///
		(hist logSize if top_pop == 1, start(-15) width(1) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export pypi_hist_logSize_CentralPopular.jpg, replace
		
	twoway (hist NumContributors if top_ev_cent == 1, start(0) width(5) color(red%30)) ///
		(hist  NumContributors if top_pop == 1, start(0) width(5) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export pypi_hist_NumContributors_CentralPopular.jpg, replace
		
// 	twoway (hist NumReleases if top_katz_cent == 1, start(0) width(10) color(red%30)) ///
// 		(hist   NumReleases if top_pop == 1, start(0) width(10) color(blue%30)), ///
// 		legend(order(1 "Most Central" 2 "Most Popular"))
// 	graph export pypi_hist_NumReleases_CentralPopular.jpg, replace
save 11_top_popularity_centrality-repo1.dta, replace

// TOP VS. BOTTOM EV CENTRALITY
cd ~/Downloads/Pypi
use tmp_10_popularity_centrality-repo.dta, clear
	
	keep if top_ev_cent == 1 | bot_ev_cent == 1
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_ev_cent == 1
	hist logSize if bot_ev_cent == 1
	
	hist NumContributors if top_ev_cent == 1
	hist NumContributors if bot_ev_cent == 1
	
	twoway (hist logSize if top_ev_cent == 1, start(-15) width(1) color(red%30)) ///
		(hist logSize if bot_ev_cent == 1, start(-15) width(1) color(blue%30)), ///
		legend(order(1 "Log(Size) Most Central" 2 "Log(Size) Least Central"))
	graph export pypi_hist_logSize_TopLeast_Central.jpg, replace
		
	twoway (hist NumContributors if top_ev_cent == 1, start(0) width(5) color(red%30)) ///
		(hist  NumContributors if bot_ev_cent == 1, start(0) width(5) color(blue%30)), ///
		legend(order(1 "NumContrib Most Central" 2 "NumContrib Least Central"))
	graph export pypi_hist_NumContributors_TopLeast_Central.jpg, replace
		
// 	twoway (hist NumReleases if top_katz_cent == 1, start(0) width(10) color(red%30)) ///
// 		(hist   NumReleases if bot_katz_cent == 1, start(0) width(10) color(blue%30)), ///
// 		legend(order(1 "NumReleases Most Central" 2 "NumReleases Least Central"))
// 	graph export pypi_hist_NumReleases_TopLeast_Central.jpg, replace 
save 11_top_popularity_centrality-repo2.dta, replace

// TOP VS. BOTTOM POPULARITY
cd ~/Downloads/Pypi
use tmp_10_popularity_centrality-repo.dta, clear
	
	keep if top_pop == 1 | bot_pop == 1
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_pop == 1
	hist logSize if bot_pop == 1
	
	hist NumContributors if top_pop == 1
	hist NumContributors if bot_pop == 1
	
	twoway (hist logSize if top_pop == 1, start(-15) width(1) color(red%30)) ///
		(hist logSize if bot_pop == 1, start(-15) width(1) color(blue%30)), ///
		legend(order(1 "Log(Size) Most Popular" 2 "Log(Size) Least Popular"))
	graph export pypi_hist_logSize_TopLeast_Popularity.jpg, replace
		
	twoway (hist NumContributors if top_pop == 1, start(0) width(5) color(red%30)) ///
		(hist  NumContributors if bot_pop == 1, start(0) width(5) color(blue%30)), ///
		legend(order(1 "NumContrib Most Popular" 2 "NumContrib Least Popular"))
	graph export pypi_hist_NumContributors_TopLeast_Popularity.jpg, replace
		
save 11_top_popularity_centrality-projects3.dta, replace

//
// NUMCONTRIBUTORS VS. SIZE
//
cd ~/Downloads/Pypi
use tmp_10_popularity_centrality-repo.dta, clear
	gen foo = Size/(1024*1024)
	drop Size
	rename foo Size
	
// 	winsor2 Size, replace cuts(0,90) trim
// 	winsor2 TotalCommits, replace cuts(0,90) trim
// 	winsor2 NumContributors, replace cuts(0,90) trim. // TODO: careful

// 	drop if TotalCommits > 1000000  // all of these are somewhat suspicious repositories
// 	drop if NumContributors > 150
// 	drop if Size > 38.3  // p99
	
	scatter NumContributors Size
	graph export pypi_NumContrib_Size.jpg, replace
	
// 	scatter TotalCommits Size
// 	graph export pypi_TotalCommits_Size.jpg, replace
//	
// 	scatter TotalCommits NumContributors
// 	graph export pypi_TotalCommits_NumContributors.jpg, replace


// ============================================================================
//
// Cargo -- 1.6.0 -- NOT USED 
//
// ============================================================================

//
// PREPARE FILES
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/

// repositories
cd ~/Downloads/Cargo/
insheet using "repositories_Cargo.csv", delimiter(";") names clear
	drop if repoid == "RepoID"
	destring size, replace
	destring numstars, replace
	destring numforks, replace
	destring numwatchers, replace
	destring numcontributors, replace

	destring repoid, replace
save "repositories_Cargo.dta", replace

// projects
cd ~/Downloads/Cargo/
insheet using "projects_Cargo.csv", delimiter(";") names clear
	drop if id == "ID"
	destring id, replace
	destring repoid, replace
save "projects_Cargo.dta", replace
	rename id projectid
	keep projectid repoid
	
	drop if repoid == .
save projectid_repoid.dta, replace 

// REPO DEPENDENCIES 
//
// NB (from libraries.io): A repository dependency is a dependency upon a Version from a package manager has been specified in a manifest file, either as a manually added dependency committed by a user or listed as a generated dependency listed in a lockfile that has been automatically generated by a package manager and committed.
cd ~/Downloads/Cargo
insheet using repo_dependencies_Cargo.csv, names delimiter(";") clear
	drop id 
	drop projectname dependencyprojectname
	drop dependencyrequirements
	
	drop if dependencyprojectid == ""
	drop if dependencyprojectid == "DependencyProjectID"
	
	destring dependencyprojectid, replace
	rename dependencyprojectid projectid
	
	// repoid already exists
	rename repoid from_repo_id
	destring from_repo_id, replace
	
	// match dependencyproject
	drop if projectid == "" | projectid == "runtime" | projectid == "]}" | projectid == "=>true" | projectid == "=>false}"
	destring projectid, replace
merge m:1 projectid using projectid_repoid.dta
	keep if _merge == 3
	drop _merge

	rename projectid to_project_id
	rename repoid to_repo_id
	sort from_repo_id to_repo_id 
	order from_repo_id to_repo_id
save repo_match_dependencies_Cargo2.dta, replace
	keep to_repo_id from_repo_id
	duplicates drop
outsheet using "dependencies_Cargo-repo2.csv", delimiter(";") replace
save "dependencies_Cargo-repo2.dta", replace // 3,676,078 observations


//
// Cargo -- MAIN ANALYSIS -- REPO LEVEL
//
// PREPARE CENTRALITIES
// cd ~/Downloads/Cargo
insheet using gephi_analysis_dependencies_Cargo-repo2-lcc.csv, clear names
	drop v2 v3
	rename v1 repoid 
	rename v4 in_degree
	rename v5 out_degree
	drop v6
	rename v7 pagerank
	rename v8 ev_centrality
save analysis_dependencies_Cargo-repo2-lcc.dta, replace

// CREATE MASTER DATASET
// cd ~/Downloads/Cargo
use repositories_Cargo.dta, clear
	drop description 
	sort repoid

merge 1:1 repoid using analysis_dependencies_Cargo-repo2-lcc.dta
	keep if _merge == 3. // we lose 22,229 out of 70,054 observations
	drop _merge

	rename size Size
	rename numcontributors NumContributors
	
	drop if Size == 0  // some packages have zero size
	rename numstars Popularity
	label var ev_centrality "Eigenvector Centrality"
	// truncate
// 	winsor2 ev_centrality, replace cuts(0 95) trim
// 	winsor2 katz_centrality, replace cuts(0 95) trim
// 	winsor2 indeg_centrality, replace cuts(0,95) trim
// 	winsor2 in_degree, replace cuts(0,99) trim
// 	winsor2 out_degree, replace cuts(0,99) trim
	winsor2 Popularity, replace cuts(0 99) trim
	winsor2 NumContributors, replace cuts(0 99) trim
	
	// look at most central packages manually
	gsort - ev_centrality 
	
	// simple scatter plot
	scatter Popularity ev_centrality
	graph export cargo_popularity-ev_centrality.jpg, replace
	
// 	scatter Popularity katz_centrality
// 	graph export cargo_popularity-katz_centrality.jpg, replace

// 	scatter Popularity indeg_centrality
// 	graph export cargo_popularity-indeg_centrality.jpg, replace
	
	label variable in_degree "in-degree"
	label variable out_degree "out-degree"
	scatter in_degree out_degree 
	graph export cargo_indeg-outdeg.jpg, replace
	
	// binscatter
	binscatter Popularity ev_centrality
	graph export cargo_bs_popularity-ev_centrality.jpg, replace
	
// 	binscatter Popularity katz_centrality
// 	graph export pypi_bs_popularity-katz_centrality.jpg, replace
	
// 	binscatter Popularity indeg_centrality
// 	graph export pypi_bs_popularity-indeg_centrality.jpg, replace
	
	// number of contributors vs popularity
	binscatter NumContributors Popularity
	graph export cargo_bs_t99_numcontributors_popularity.jpg, replace
	
// 	binscatter NumContributors katz_centrality
// 	graph export cargo_bs_t99_numcontributors_katz_centrality.jpg, replace

// 	binscatter NumContributors indeg_centrality
// 	graph export cargo_bs_t99_numcontributors_indeg_centrality.jpg, replace

	// regressions
	regress Popularity NumContributors
	regress Popularity ev_centrality
	
	// 
	// activity vs. popularity plots
	//
	gen top_pop = 0
	replace top_pop = 1 if Popularity > 227 // 99pct
	gen bot_pop = 0 
	replace bot_pop = 1 if Popularity == 0 // 50pct
	
	gen top_ev_cent = 0
	replace top_ev_cent = 1 if ev_centrality > 0.0214597 // 99pct
	gen bot_ev_cent = 0
	replace bot_ev_cent = 1 if ev_centrality <= 0.0020911 // 50pct
	
// 	gen top_indeg_cent = 0
// 	replace top_indeg_cent = 1 if indeg_centrality > 0.0000629 // 99pct
// 	gen bot_indeg_cent = 0
// 	replace bot_indeg_cent = 1 if indeg_centrality <= 0.00000932 // 50 pct

save tmp_10_popularity_centrality-repo.dta, replace


//
// CENTRALTIES
//
// KATZ CENTRALITY VS. POPULARITY
// cd ~/Downloads/Cargo
use tmp_10_popularity_centrality-repo.dta, clear
	
	keep if top_ev_cent == 1 | top_pop == 1
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_ev_cent == 1
	hist logSize if top_pop == 1
	
	hist NumContributors if top_ev_cent == 1
	hist NumContributors if top_pop == 1
	
	twoway (hist logSize if top_ev_cent == 1, start(-15) width(1) color(red%30)) ///
		(hist logSize if top_pop == 1, start(-15) width(1) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export cargo_hist_logSize_CentralPopular.jpg, replace
		
	twoway (hist NumContributors if top_ev_cent == 1, start(0) width(25) color(red%30)) ///
		(hist  NumContributors if top_pop == 1, start(0) width(25) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export cargo_hist_NumContributors_CentralPopular.jpg, replace
		
// 	twoway (hist NumReleases if top_katz_cent == 1, start(0) width(10) color(red%30)) ///
// 		(hist   NumReleases if top_pop == 1, start(0) width(10) color(blue%30)), ///
// 		legend(order(1 "Most Central" 2 "Most Popular"))
// 	graph export pypi_hist_NumReleases_CentralPopular.jpg, replace
save 11_top_popularity_centrality-repo1.dta, replace

// TOP VS. BOTTOM KATZ CENTRALITY
// cd ~/Downloads/Cargo
use tmp_10_popularity_centrality-repo.dta, clear
	
	keep if top_ev_cent == 1 | bot_ev_cent == 1
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_ev_cent == 1
	hist logSize if bot_ev_cent == 1
	
	hist NumContributors if top_ev_cent == 1
	hist NumContributors if bot_ev_cent == 1
	
	twoway (hist logSize if top_ev_cent == 1, start(-16) width(2) color(red%30)) ///
		(hist logSize if bot_ev_cent == 1, start(-16) width(2) color(blue%30)), ///
		legend(order(1 "Log(Size) Most Central" 2 "Log(Size) Least Central"))
	graph export cargo_hist_logSize_TopLeast_Central.jpg, replace
		
	twoway (hist NumContributors if top_ev_cent == 1, start(0) width(5) color(red%30)) ///
		(hist  NumContributors if bot_ev_cent == 1, start(0) width(5) color(blue%30)), ///
		legend(order(1 "NumContrib Most Central" 2 "NumContrib Least Central"))
	graph export cargo_hist_NumContributors_TopLeast_Central.jpg, replace
		
// 	twoway (hist NumReleases if top_katz_cent == 1, start(0) width(10) color(red%30)) ///
// 		(hist   NumReleases if bot_katz_cent == 1, start(0) width(10) color(blue%30)), ///
// 		legend(order(1 "NumReleases Most Central" 2 "NumReleases Least Central"))
// 	graph export pypi_hist_NumReleases_TopLeast_Central.jpg, replace 
save 11_top_popularity_centrality-repo2.dta, replace

// TOP VS. BOTTOM POPULARITY
// cd ~/Downloads/Cargo
use tmp_10_popularity_centrality-repo.dta, clear
	
	keep if top_pop == 1 | bot_pop == 1
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_pop == 1
	hist logSize if bot_pop == 1
	
	hist NumContributors if top_pop == 1
	hist NumContributors if bot_pop == 1
	
	twoway (hist logSize if top_pop == 1, start(-16) width(2) color(red%30)) ///
		(hist logSize if bot_pop == 1, start(-16) width(2) color(blue%30)), ///
		legend(order(1 "Log(Size) Most Popular" 2 "Log(Size) Least Popular"))
	graph export cargo_hist_logSize_TopLeast_Popularity.jpg, replace
		
	twoway (hist NumContributors if top_pop == 1, start(0) width(5) color(red%30)) ///
		(hist  NumContributors if bot_pop == 1, start(0) width(5) color(blue%30)), ///
		legend(order(1 "NumContrib Most Popular" 2 "NumContrib Least Popular"))
	graph export cargo_hist_NumContributors_TopLeast_Popularity.jpg, replace
		
// 	twoway (hist NumReleases if top_pop == 1, start(0) width(10) color(red%30)) ///
// 		(hist   NumReleases if bot_pop == 1, start(0) width(10) color(blue%30)), ///
// 		legend(order(1 "NumReleases Most Popular" 2 "NumReleases Least Popular"))
// 	graph export hist_NumReleases_TopLeast_Popular.jpg, replace 
save 11_top_popularity_centrality-projects3.dta, replace

// INDEGREE CENTRALITY VS. POPULARITY
// cd ~/Downloads/Cargo
// use tmp_10_popularity_centrality-repo.dta, clear
//
// 	keep if top_indeg_cent == 1 | top_pop == 1
// 	gen foo = log(Size / (1024*1024))
// 	drop Size
// 	rename foo logSize // MB
//	
// 	hist logSize if top_indeg_cent == 1
// 	hist logSize if top_pop == 1
//	
// 	hist NumContributors if top_indeg_cent == 1
// 	hist NumContributors if top_pop == 1
//
// 	twoway (hist logSize if top_indeg_cent == 1, start(-16) width(2) color(red%30)) ///
// 		(hist logSize if top_pop == 1, start(-16) width(2) color(blue%30)), ///
// 		legend(order(1 "Most Central" 2 "Most Popular"))
// 	graph export pypi_hist_logSize_IndegCentralPopular.jpg, replace
//		
// 	twoway (hist NumContributors if top_indeg_cent == 1, start(0) width(125) color(red%30)) ///
// 		(hist  NumContributors if top_pop == 1, start(0) width(125) color(blue%30)), ///
// 		legend(order(1 "Most Central" 2 "Most Popular"))
// 	graph export pypi_hist_NumContributors_IndegCentralPopular.jpg, replace
//		
// // 	twoway (hist NumReleases if top_indeg_cent == 1, start(0) width(10) color(red%30)) ///
// // 		(hist   NumReleases if top_pop == 1, start(0) width(10) color(blue%30)), ///
// // 		legend(order(1 "Most Central" 2 "Most Popular"))
// // 	graph export hist_NumReleases_IndegCentralPopular.jpg, replace
// save 11_top_popularity_centrality-projects4.dta, replace


//
// NUMCONTRIBUTORS VS. SIZE
//
// cd ~/Downloads/Cargo
use tmp_10_popularity_centrality-repo.dta, clear
	gen foo = Size/(1024*1024)
	drop Size
	rename foo Size
	
// 	winsor2 Size, replace cuts(0,90) trim
// 	winsor2 TotalCommits, replace cuts(0,90) trim
// 	winsor2 NumContributors, replace cuts(0,90) trim. // TODO: careful

// 	drop if TotalCommits > 1000000  // all of these are somewhat suspicious repositories
// 	drop if NumContributors > 150
// 	drop if Size > 38.3  // p99
	
	scatter NumContributors Size
	graph export cargo_NumContrib_Size.jpg, replace
	
// 	scatter TotalCommits Size
// 	graph export pypi_TotalCommits_Size.jpg, replace
//	
// 	scatter TotalCommits NumContributors
// 	graph export pypi_TotalCommits_NumContributors.jpg, replace

	
	
	
// ============================================================================
//
// Cargo -- 1.4.0
//
// ============================================================================

//
// PRELIMINARY ANALYSES
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/
insheet using "dependencies_Cargo.csv", delimiter(";") names clear
	rename projectid id_from
	rename dependencyprojectid id_to
	keep id*
duplicates drop
	drop if id_from == "Project ID"
	destring id*, replace
outsheet using "dependencies_Cargo-projects.csv", delimiter(";") replace


//
// 1_maintainer_githubID.dta
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
insheet using "Maintainer_GithubID.csv", delimiter(",") names clear 
	rename project name_project
save "1_maintainer_githubID.dta", replace


//
// 2_maintainer_github_metadata.dta
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
insheet using "Maintainer_github_metadata.csv", delimiter(",") names clear 
	rename contributor_github_url maintainer_github_url

	// data not filled for 2/3 of the maintainers
	gen pct_code_review = round(100*code_review / contributions)
	gen pct_commits = round(100*commits / contributions)
	gen pct_issues = round(100*issues / contributions)
	gen pct_pull_requests = round(100*pull_requests / contributions)
	
save "2_maintainer_github_metadata-full.dta", replace
outsheet using "2_maintainer_github_metadata-full.csv", delimiter(",") replace

	sort maintainer_github_url year
	bysort maintainer_github_url: gen MaintainerSeniority = _N
	bysort maintainer_github_url: egen MaintainerActivity = sum(contributions)
	gen MaintainerAvgActivity = MaintainerActivity / MaintainerSeniority

	keep maintainer_github_url Maintainer*
	duplicates drop
	
save "2_maintainer_github_metadata.dta", replace
outsheet using "2_maintainer_github_metadata.csv", delimiter(",") replace
 

//
// 2_contributor_commits.dta
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
insheet using "Contributor_commits-clean.csv", delimiter(";") names clear 
	
	drop if contributor_github_url == ""  // 5,476 observations lost
	sort name_project contributor_github_url
	
save "2_contributor_commits-full.dta", replace
outsheet using "2_contributor_commits-full.csv", delimiter(",") replace

	bysort name_project: gen num_contributors_alt = _N

	bysort contributor_github_url: gen ContributorExperience = _N
	bysort contributor_github_url: egen ContributorTotalCommits = sum(contributor_commits)
	gen ContributorActivty = ContributorExperience / ContributorTotalCommits

	keep name_project contributor_github_url Contributor*
	
	duplicates drop
	
save "2_contributor_commits.dta", replace
outsheet using "2_contributor_commits.csv", delimiter(",") replace
	bysort name_project: egen TotalContributorCommits = sum(ContributorTotalCommits)
	keep name_project TotalContributorCommits
	duplicates drop 
save 12_contributors_project.dta, replace

//
// 3_covariates_maintainers.dta
//
// prepare maintainer data
use 2_maintainer_github_metadata-full.dta, clear
	bysort maintainer_github_url: egen total_contributions = sum(contributions)
	drop if total_contributions > 125000 // there seem to be a handful of either malicious or automated accounts that we are dropping here
	keep maintainer_github_url total_contributions
	duplicates drop
save 12_maintainer_contributions.dta, replace

// prepare contributor data 
insheet using Maintainer_GithubID.csv, delimiter(",") clear names
	merge m:1 maintainer_github_url using 12_maintainer_contributions.dta 
	drop if _merge != 3
	drop _merge
	rename project name_project
	bysort maintainer_github_url: gen num_repos_contributed_to = _N
	gen avg_contributions = total_contributions / num_repos_contributed_to
	duplicates drop
	sort name_project
	by name_project: egen tot_avg_maint_contrib = sum(avg_contributions)
save 12_maintainer_project.dta, replace // careful, total contributions are to all repositories a maintainer works on

	keep name_project tot_avg_maint_contrib
	duplicates drop
merge 1:1 name_project using 12_contributors_project.dta. // from before
	drop if _merge == 2
	drop _merge
	replace TotalContributorCommits = 0 if TotalContributorCommits == .
	rename tot_avg_maint_contrib TotalAverageMaintainerCommits
	gen TotalCommits = TotalAverageMaintainerCommits + TotalContributorCommits
save 12_project_commits.dta, replace

// prepare covariates
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
insheet using "covariates_maintainers-1.csv", delimiter(";") clear
	rename date_first_release str_date_first_release
	rename date_latest_release str_date_latest_release
	gen date_first_release = date(str_date_first_release, "YMD")
	format date_first_release %td
	gen date_latest_release = date(str_date_latest_release, "YMD")
	format date_latest_release %td
duplicates drop

	// Activity, Maturity
	gen Maturity = date_latest_release - date_first_release

	gen Activity = 30*num_total_releases / Maturity
	replace Activity = 0 if Activity == .

	// Other variables
	rename num_stars Popularity
	rename num_forks NumForks
	rename num_contributors NumContributors
	rename size_repository Size  // in Byte
	rename num_watchers NumWatchers 
	rename num_total_releases NumReleases
merge 1:1 name_project using 12_project_commits.dta 
	keep if _merge == 3
	drop _merge
	
	order name_project crates_url github_repo
outsheet using "3_covariates_maintainers.csv", delimiter(",") names replace
save "3_covariates_maintainers.dta", replace

	drop if crates_url == ""

	bysort crates_url: gen projects_per_crate = _N 
	bysort github_repo: gen projects_per_repo = _N 
	
	order github_repo projects_per_* name_project crates_url
	keep github_repo projects_per_* name_project crates_url
outsheet using "3_projects_per_repo.csv", delimiter(",") names replace
save "3_projects_per_repo.dta", replace
	
 
//
// 4_projects_cargo.dta -- to prepare mapping
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/
insheet using "projects_Cargo.csv", delimiter(";") clear
	rename projectid key1
	rename name name_project
	keep key1 name_project
duplicates drop
save "covariates/4_projects_cargo.dta", replace
outsheet using "covariates/4_projects_cargo.csv", delimiter(",") replace


// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
//
// ALTERNATIVE dependency graph based on Cargo.csv obtained from 
// new scraper (2023-09-13)
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/
insheet using "dependencies_Cargo.csv", delimiter(";") names clear
	rename projectid id_from
	rename dependencyprojectid id_to
	keep id*
duplicates drop
	drop if id_from == "Project ID"
	destring id*, replace
	drop if id_from == . | id_to == .
outsheet using "dependencies_Cargo-projects2.csv", delimiter(";") replace
save dependencies_Cargo-projects2.dta, replace

cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/
insheet using "projects_Cargo.csv", delimiter(";") names clear
	rename name project_name
	rename projectid project_id 
save projects_Pypi.dta, replace
	keep project_name project_id
	duplicates drop
save project_id_name.dta, replace

insheet using "Cargo.csv", delimiter(";") names clear
	sort github_repo project package_manager_url
	order github_repo project package_manager_url
	drop if github_repo == ""
	
	rename project project_name
merge m:1 project_name using project_id_name.dta 
	keep if _merge == 3
	drop _merge
	
	keep github_repo project_id 
	duplicates drop
	sort github_repo project_id
	
	bysort project_id : gen foo = _N
	drop if foo > 1
	drop foo
save github_projectid.dta, replace

//
// ALTERNATIVE: repo-based dependency graph
//
use dependencies_Cargo-projects2.dta, clear
	rename id_from project_id 
merge m:1 project_id using github_projectid.dta
	keep if _merge == 3
	drop _merge 
	rename project_id id_from 
	rename github_repo repo_from 
	
	rename id_to project_id 
merge m:1 project_id using github_projectid.dta
	keep if _merge == 3
	drop _merge 
	rename project_id id_to 
	rename github_repo repo_to 
	
	keep repo_from repo_to

	duplicates drop
save repo_dependencies2.dta, replace
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//
// dependencies_Cargo-repo -- create repo-based dependency graph
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/
insheet using "dependencies_Cargo.csv", delimiter(";") names clear
	rename projectid from
	rename dependencyprojectid to
	keep from to
	duplicates drop
	drop if from == "Project ID"
	
	// match project names
	rename from key1
	destring key1, replace
merge m:1 key1 using covariates/4_projects_cargo.dta
	keep if _merge == 3
	drop _merge
	rename key1 id_from 
	// now match repos to project names
merge m:1 name_project using covariates/3_projects_per_repo.dta 
	keep if _merge == 3
	drop _merge
	rename name_project name_from
	rename github_repo repo_from
	rename crates_url crates_from
	drop projects*
	
	// match project names
	rename to key1
	destring key1, replace
merge m:1 key1 using covariates/4_projects_cargo.dta
	keep if _merge == 3
	drop _merge
	rename key1 id_to 
	// now match repos to project names
merge m:1 name_project using covariates/3_projects_per_repo.dta 
	keep if _merge == 3
	drop _merge
	rename name_project name_to
	rename github_repo repo_to
	rename crates_url crates_to
	drop projects*
save dependencies_Cargo-repo-tmp.dta, replace

use dependencies_Cargo-repo-tmp.dta, clear
	keep repo_from
	duplicates drop
	rename repo_from repo_name
save repo_from.dta, replace

use dependencies_Cargo-repo-tmp.dta, clear
	keep repo_to
	rename repo_to repo_name
	duplicates drop
append using repo_from.dta	
	duplicates drop
	
	sort repo_name
	egen id_repo = group(repo_name)
	replace id_repo = 0 if id_repo == .
save id_repo_name.dta, replace

	// generate repo ids
use dependencies_Cargo-repo-tmp.dta, clear
	rename repo_from repo_name
merge m:1 repo_name using id_repo_name.dta
	keep if _merge == 3
	drop _merge
	rename repo_name repo_from 
	rename id_repo id_repo_from 

	rename repo_to repo_name
merge m:1 repo_name using id_repo_name.dta
	keep if _merge == 3
	drop _merge
	rename repo_name repo_to
	rename id_repo id_repo_to
	
	gen _missing = 0
	replace _missing = 1 if repo_from == "" | repo_to == ""
	replace _missing = 2 if repo_from == "" & repo_to == ""
	
	order id_from id_repo_from id_to id_repo_to _missing name_from name_to repo_from repo_to crates_from crates_to
	sort name_from name_to
save dependencies_Cargo-repo.dta, replace	
outsheet using dependencies_Cargo-repo.csv, delimiter(";") replace
	
	// now save only those for which we have to and from repos
	keep if _missing == 0
outsheet using dependencies_Cargo-repo-nomissing.csv, nonames delimiter(";") replace
	keep id_repo_from id_repo_to // repo_from repo_to
	duplicates drop
	sort id_repo_from id_repo_to
outsheet using dependencies_Cargo-repo-nomissing.dat, nonames delimiter(" ") replace


//
// MAIN ANALYSIS -- REPO LEVEL
//
// PREPARE CENTRALITIES
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/
insheet using analysis_dependencies_Cargo-repo-nomissing.csv, delimiter(";") names clear
	rename id_node id_repo
save 6_centralities_Cargo-repo-nonmissing.dta, replace

// CREATE MASTER DATASET
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use 3_covariates_maintainers.dta, clear
	keep name_project NumForks NumContributors NumReleases Size Popularity NumWatchers Total*

merge 1:1 name_project using 3_projects_per_repo.dta
	drop if _merge != 3
	drop _merge
	
	drop if github_repo == ""
	
	bysort github_repo: egen foo = total(NumReleases)
	drop NumReleases
	rename foo NumReleases
	
	order github_repo NumReleases Size NumContributors NumForks Popularity NumWatchers
	keep github_repo NumReleases Size NumContributors NumForks Popularity NumWatchers Total*
	duplicates drop

	// there are some edge cases here that we are alleviating this way; the issue is in the raw data
	foreach var of varlist NumReleases-TotalCommits {
		bysort github_repo: egen foo = mean(`var')
		drop `var'
		rename foo `var'
	}
	duplicates drop
	
	rename github_repo repo_name
merge 1:1 repo_name using ../id_repo_name.dta
	keep if _merge == 3
	drop _merge
	rename repo_name github_repo
	
merge 1:1 id_repo using ../6_centralities_Cargo-repo-nonmissing.dta
	keep if _merge == 3
	drop _merge 
save ../10_popularity_centrality-projects.dta, replace

use ../10_popularity_centrality-projects.dta, clear
	drop if Size == 0  // some packages have zero size

	// truncate Popularity and centrality 
	
	// simple scatter plot
	scatter Popularity ev_centrality
	graph export popularity-ev_centrality.jpg, replace
	
	scatter Popularity katz_centrality
	graph export popularity-katz_centrality.jpg, replace

	scatter Popularity indeg_centrality
	graph export popularity-indeg_centrality.jpg, replace
	
	// binscatter
// 	winsor2 ev_centrality, replace cuts(0 99) trim
	binscatter Popularity ev_centrality
	graph export bs_popularity-ev_centrality.jpg, replace
	
// 	winsor2 katz_centrality, replace cuts(0 99) trim
	binscatter Popularity katz_centrality
	graph export bs_popularity-katz_centrality.jpg, replace
	
// 	winsor2 indeg_centrality, replace cuts(0 99) trim
	binscatter Popularity indeg_centrality
	graph export bs_popularity-indeg_centrality.jpg, replace

	// number of releases and popularity should be truncated as well
	winsor2 NumReleases, replace cuts(0 99) trim
	winsor2 Popularity, replace cuts(0 99) trim
	
	// number of contributors vs popularity
	binscatter NumContributors Popularity
	graph export bs_t99_numcontributors_popularity.jpg, replace
	
	binscatter NumContributors katz_centrality
	graph export bs_t99_numcontributors_katz_centrality.jpg, replace

	binscatter NumContributors indeg_centrality
	graph export bs_t99_numcontributors_indeg_centrality.jpg, replace

	// regressions
	regress Popularity NumContributors
	regress Popularity katz_centrality
	
	// 
	// activity vs. popularity plots
	//
	gen top_pop = 0
	replace top_pop = 1 if Popularity > 1800 // 138 changes, 99pct
	gen bot_pop = 0 
	replace bot_pop = 1 if Popularity <= 4 // 3581 changes, 50pct
	
	gen top_katz_cent = 0
	replace top_katz_cent = 1 if katz_centrality > 0.024288 // 77 changes, 99pct
	gen bot_katz_cent = 0
	replace bot_katz_cent = 1 if katz_centrality <= 0.0011881 // 4036 changes, 50pct
	
	gen top_indeg_cent = 0
	replace top_indeg_cent = 1 if indeg_centrality > 0.0068458 // 69 changes, 99pct
	gen bot_indeg_cent = 0
	replace bot_indeg_cent = 1 if indeg_centrality <= 0 // 4036 changes, 50 pct

save ../tmp_10_popularity_centrality-projects.dta, replace


//
// CENTRALTIES
//
// KATZ CENTRALITY VS. POPULARITY
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use ../tmp_10_popularity_centrality-projects.dta, clear
	
	keep if top_katz_cent == 1 | top_pop == 1. // 331 obs left
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_katz_cent == 1
	hist logSize if top_pop == 1
	
	hist NumContributors if top_katz_cent == 1
	hist NumContributors if top_pop == 1
	
	twoway (hist logSize if top_katz_cent == 1, start(-6) width(2) color(red%30)) ///
		(hist logSize if top_pop == 1, start(-5) width(2) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_logSize_CentralPopular.jpg, replace
		
	twoway (hist NumContributors if top_katz_cent == 1, start(0) width(125) color(red%30)) ///
		(hist  NumContributors if top_pop == 1, start(0) width(125) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_NumContributors_CentralPopular.jpg, replace
		
	twoway (hist NumReleases if top_katz_cent == 1, start(0) width(10) color(red%30)) ///
		(hist   NumReleases if top_pop == 1, start(0) width(10) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_NumReleases_CentralPopular.jpg, replace
save ../11_top_popularity_centrality-projects-1.dta, replace

// TOP VS. BOTTOM KATZ CENTRALITY
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use ../tmp_10_popularity_centrality-projects.dta, clear
	
	keep if top_katz_cent == 1 | bot_katz == 1
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_katz_cent == 1
	hist logSize if bot_katz_cent == 1
	
	hist NumContributors if top_katz_cent == 1
	hist NumContributors if bot_katz_cent == 1
	
	twoway (hist logSize if top_katz_cent == 1, start(-8) width(2) color(red%30)) ///
		(hist logSize if bot_katz_cent == 1, start(-8) width(2) color(blue%30)), ///
		legend(order(1 "Log(Size) Most Central" 2 "Log(Size) Least Central"))
	graph export hist_logSize_TopLeast_Central.jpg, replace
		
	twoway (hist NumContributors if top_katz_cent == 1, start(0) width(100) color(red%30)) ///
		(hist  NumContributors if bot_katz_cent == 1, start(0) width(100) color(blue%30)), ///
		legend(order(1 "NumContrib Most Central" 2 "NumContrib Least Central"))
	graph export hist_NumContributors_TopLeast_Central.jpg, replace
		
	twoway (hist NumReleases if top_katz_cent == 1, start(0) width(10) color(red%30)) ///
		(hist   NumReleases if bot_katz_cent == 1, start(0) width(10) color(blue%30)), ///
		legend(order(1 "NumReleases Most Central" 2 "NumReleases Least Central"))
	graph export hist_NumReleases_TopLeast_Central.jpg, replace 
save ../11_top_popularity_centrality-projects-2.dta, replace

// TOP VS. BOTTOM POPULARITY
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use ../tmp_10_popularity_centrality-projects.dta, clear
	
	keep if top_pop == 1 | bot_pop == 1
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_pop == 1
	hist logSize if bot_pop == 1
	
	hist NumContributors if top_pop == 1
	hist NumContributors if bot_pop == 1
	
	twoway (hist logSize if top_pop == 1, start(-8) width(2) color(red%30)) ///
		(hist logSize if bot_pop == 1, start(-8) width(2) color(blue%30)), ///
		legend(order(1 "Log(Size) Most Popular" 2 "Log(Size) Least Popular"))
	graph export hist_logSize_TopLeast_Popularity.jpg, replace
		
	twoway (hist NumContributors if top_pop == 1, start(0) width(100) color(red%30)) ///
		(hist  NumContributors if bot_pop == 1, start(0) width(100) color(blue%30)), ///
		legend(order(1 "NumContrib Most Popular" 2 "NumContrib Least Popular"))
	graph export hist_NumContributors_TopLeast_Popularity.jpg, replace
		
	twoway (hist NumReleases if top_pop == 1, start(0) width(10) color(red%30)) ///
		(hist   NumReleases if bot_pop == 1, start(0) width(10) color(blue%30)), ///
		legend(order(1 "NumReleases Most Popular" 2 "NumReleases Least Popular"))
	graph export hist_NumReleases_TopLeast_Popular.jpg, replace 
save ../11_top_popularity_centrality-projects-3.dta, replace

// INDEGREE CENTRALITY VS. POPULARITY
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use ../tmp_10_popularity_centrality-projects.dta, clear	
	keep if top_indeg_cent == 1 | top_pop == 1. // 331 obs left
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_indeg_cent == 1
	hist logSize if top_pop == 1
	
	hist NumContributors if top_indeg_cent == 1
	hist NumContributors if top_pop == 1

	twoway (hist logSize if top_indeg_cent == 1, start(-6) width(2) color(red%30)) ///
		(hist logSize if top_pop == 1, start(-5) width(2) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_logSize_IndegCentralPopular.jpg, replace
		
	twoway (hist NumContributors if top_indeg_cent == 1, start(0) width(125) color(red%30)) ///
		(hist  NumContributors if top_pop == 1, start(0) width(125) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_NumContributors_IndegCentralPopular.jpg, replace
		
	twoway (hist NumReleases if top_indeg_cent == 1, start(0) width(10) color(red%30)) ///
		(hist   NumReleases if top_pop == 1, start(0) width(10) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_NumReleases_IndegCentralPopular.jpg, replace
save ../11_top_popularity_centrality-projects-4.dta, replace


//
// NUMCONTRIBUTORS VS. SIZE
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo
use tmp_10_popularity_centrality-projects.dta, clear
// 	gen foo = log(Size / (1024*1024))
// 	drop Size
// 	rename foo logSize // MB
	gen foo = Size/(1024*1024)
	drop Size
	rename foo Size
	
// 	winsor2 Size, replace cuts(0,90) trim
// 	winsor2 TotalCommits, replace cuts(0,90) trim
// 	winsor2 NumContributors, replace cuts(0,90) trim. // TODO: careful
	drop if TotalCommits > 1000000  // all of these are somewhat suspicious repositories
	drop if NumContributors > 150
	drop if Size > 38.3  // p99
	
	scatter NumContributors Size
	graph export NumContrib_Size.jpg, replace
	
	scatter TotalCommits Size
	graph export TotalCommits_Size.jpg, replace
	
	scatter TotalCommits NumContributors
	graph export TotalCommits_NumContributors.jpg, replace

	gen Binned_NumContrib = round(NumContributors/10,1)
	gen AvgNumCommits = TotalCommits / NumContributors
	bysort Binned_NumContrib: egen AvgCommits = mean(AvgNumCommits)
	keep Binned_NumContrib AvgCommits
	duplicates drop
	
	line AvgCommits Binned_NumContrib
	graph export AvgCommits_BinnedNumContrib.jpg, replace
		
	

// ==============================================================================
//
// NOT USED
//
// ==============================================================================
// NOTE: based on dependency graph with versions

cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/
insheet using centrality_dependencies_Cargo-merged.csv, delimiter(";") clear
	split node, p(-)
	rename node1 key1
	drop node* 
	order key1
	sort key1
	duplicates drop
	
	destring key1, replace
	bysort key1: egen ev_cent_mean = mean(ev_centrality)
	bysort key1: egen deg_cent_mean = mean(deg_centrality)
	
	keep key1 *_mean
	duplicates drop 

save 5_centralities_cargo.dta, replace
outsheet using 5_centralities_cargo.csv, delimiter(";") replace

// based on dependency graph on project level
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
insheet using ../centrality_dependencies_Cargo-projects.csv, delimiter(";") clear
	rename node key1
	sort key1
save 5_centralities_cargo-projects.dta, replace
outsheet using 5_centralities_cargo-projects.csv, delimiter(";") replace
	


	
	
	
	
	
	
	

// summary stats of most central and most popular packages
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use ../10_popularity_centrality-projects.dta, clear

	// table for most central projects
	gsort - degree

	order name_project degree ev_centrality deg_centrality Popularity Size NumContributors NumReleases
	keep name_project degree ev_centrality deg_centrality Popularity Size NumContributors NumReleases
	keep in 1/10
	
	texsave using 5_centralities_list.tex, replace
	
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use ../10_popularity_centrality-projects.dta, clear
	// table for most popular projects
	gsort - Popularity
	drop if Size == 978321408 // drop rust language repositories
	drop if Size == 4383047
	
	order name_project degree ev_centrality deg_centrality Popularity Size NumContributors NumReleases
	keep name_project degree ev_centrality deg_centrality Popularity Size NumContributors NumReleases
	keep in 1/10
	
	texsave using 5_popularity_list.tex, replace

	
	
	
	
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
// // prepare maintainer data
// use 2_maintainer_github_metadata-full.dta, clear
// 	bysort maintainer_github_url: egen total_contributions = sum(contributions)
// 	drop if total_contributions > 125000 // there seem to be a handful of either malicious or automated accounts that we are dropping here
//
// 	keep maintainer_github_url total_contributions
// 	duplicates drop
// save 2_maintainer_github_metadata-full-total.dta, replace
//
// // prepare mapping
insheet using Maintainer_GithubID.csv, delimiter(",") clear names
//
// merge m:1 maintainer_github_url using 2_maintainer_github_metadata-full-total.dta
// 	keep if _merge == 3
// 	drop _merge

// PROJECT.MAJOR.MINOR.VERSION LEVEL
// TODO: double check why we have so few matches between centrality and popularity


// ============================================================================
//
// DEPRECATED
// 
// ============================================================================

// // 5_master_covariates_Cargo-merged.dta -- the actual mapping
// insheet using "key_dependencies_Cargo-merged.dat", delimiter(";") clear   // created by 30_create_dependency_graph.py so that node names can be used in gephi
// 	split key, p("-")
// 	replace key3 = key3 + "-" + key4 if key4 != ""
// 	drop key4
// 	replace key2 = key2 + "-" + key3 if key3 != ""
// 	drop key3
// save "covariates/5_key_dependencies_Cargo-merged.dta", replace
// outsheet using "covariates/5_key_dependencies_Cargo-merged.csv", delimiter(",") replace
//
// 	destring key1, replace
// 	merge m:1 key1 using "covariates/4_projects_cargo.dta"
// keep if _merge == 3
// 	drop _merge
//
// 	sort name_project
// 	keep name_project key1 node_id
// duplicates drop
// 	merge m:1 name_project using "covariates/3_covariates_maintainers.dta"
// keep if _merge == 3
// 	drop _merge
//
// save "covariates/5_master_covariates_Cargo-merged.dta", replace
// outsheet using "covariates/5_master_covariates_Cargo-merged.csv", delimiter(",") replace
