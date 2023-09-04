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


//
// 3_covariates_maintainers.dta
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
insheet using "covariates_maintainers-1.csv", delimiter(";") clear
	drop v10
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
	
outsheet using "3_covariates_maintainers.csv", delimiter(",") names replace
save "3_covariates_maintainers.dta", replace

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

//
// PREPARE CENTRALITIES
//
// based on dependency graph with versions
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
	

//
// MAPPING 
//

// PROJECT LEVEL
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use 3_covariates_maintainers.dta, clear
	keep name_project NumForks NumContributors NumReleases Size Popularity NumWatchers 

merge 1:1 name_project using 4_projects_cargo.dta 
	drop if _merge != 3
	drop _merge
	
merge 1:1 key1 using 5_centralities_cargo-projects.dta
	keep if _merge == 3
	drop _merge 
save ../10_popularity_centrality-projects.dta, replace

	// truncate Popularity and centrality 
	winsor2 ev_centrality, replace cuts(0 99) trim
	winsor2 deg_centrality, replace cuts(0 99) trim
	
	// simple scatter plot
	scatter Popularity ev_centrality
	graph export popularity-ev_centrality.jpg, replace
	
	scatter Popularity deg_centrality
	graph export popularity-deg_centrality.jpg, replace

	// binscatter
	binscatter Popularity ev_centrality
	graph export bs_popularity-ev_centrality.jpg, replace
	
	binscatter Popularity deg_centrality
	graph export bs_popularity-deg_centrality.jpg, replace
	
	// number of contributors vs popularity
	winsor2 Popularity, replace cuts(1 99) trim
	binscatter NumContributors Popularity
	graph export bs_t99_numcontributors_popularity.jpg, replace
	
	binscatter NumContributors ev_centrality
	graph export bs_t99_numcontributors_ev_centrality.jpg, replace
	
	// regressions
	regress Popularity ev_centrality
	regress Popularity deg_centrality
	
	// 
	// activity vs. popularity plots
	//
	drop if Size == 0  // some packages have zero size
	gen top_pop = 0
	replace top_pop = 1 if Popularity > 6030 // 159 changes, 99pct
	
	gen top_ev_cent = 0
	replace top_ev_cent = 1 if ev_centrality > 0.0172589 // 171 changes, 99pct
	
	keep if top_ev_cent == 1 | top_pop == 1
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_ev_cent == 1
	hist logSize if top_pop == 1
	
	hist NumContributors if top_ev_cent == 1
	hist NumContributors if top_pop == 1
	
	twoway (hist logSize if top_ev_cent == 1, start(-5) width(2) color(red%30)) ///
		(hist logSize if top_pop == 1, start(-5) width(2) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_logSize_CentralPopular.jpg, replace
		
	twoway (hist NumContributors if top_ev_cent == 1, start(0) width(125) color(red%30)) ///
		(hist  NumContributors if top_pop == 1, start(0) width(125) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_NumContributors_CentralPopular.jpg, replace
		
	twoway (hist NumReleases if top_ev_cent == 1, start(0) width(75) color(red%30)) ///
		(hist   NumReleases if top_pop == 1, start(0) width(75) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_NumReleases_CentralPopular.jpg, replace

save ../11_top_popularity_centrality-projects.dta, replace


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

	
	
	
	
// cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
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
// insheet using Maintainer_GithubID.csv, delimiter(",") clear names
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
