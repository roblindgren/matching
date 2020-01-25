capture program drop match_sample_norep
program define match_sample
	args sample1 sample2 output matchvars idvar

	/*
	This program creates a 1-1 matched sample. Each match selects the observation
	in sample2 that minimizes the distance to an observation in sample1, where
	distance is measured as the sum of squared errors. 
	
	Each observation in sample 2 may be matched to an observation in sample 1 
	more than once (sampling with replacement).
	
	Created: January 14, 2020 by Rob Lindgren.
	
	Args: 
	
		sample1: Filepath for the sample to be matched, stored as a stata dta file. 
		String.
		
		sample2: Filepath for the sample from which we will pull matches, stored as 
		a stata dta file. String.
		
		output: Filepath for output dta file. String.
		
		matchvars: List of the names of variables in the "feature set" on which
		observations will  be matched. String.
			Ex - "var1 var2 var3"
			
		idvar: Name of the id variable in the datasets that are to be matched. String.
	
	Output:
	
		A stata dta file consisting of two variables: sample1_id has all of the ids
		for observations in sample1, sample2_id has the best matches from sample2
		for the corresponding sample1_ids. Save in the filepath determined by "`'output'".
	*/

	* Variable abbreviation not allowed
	novarabbrev {
	
	* Append the two samples and create an indicator variable that tells us 
	* which sample each observation came from
	use "`sample1'", clear
	gen smpl = 1
	append using "`sample2'"
	replace smpl = 2 if missing(smpl)
	sort smpl
	
	di "Drop if missing match variables"
	* Drop observations if missing any variables used for creating matched sample
	foreach var of local matchvars {
		drop if missing(`var')
	}
	
	di "Getting match ids"
	* This function does all the work
	mata: match_ids = getMatches()
	
	* Save the output of match_ids to dta file "`output'"
	clear
	
	mata: storeIDs(match_ids)
	save "`output'", replace
	
	di "Matching complete"
	
	} // end novarabbrev

end

* Clear out functions in case they've already been created
capture mata mata drop getMatches()
capture mata mata drop storeIDs()
capture mata mata drop standardizeVars()
capture mata mata drop findMatch()
capture mata mata drop standardDeviation()

mata:
	
	real scalar standardDeviation(real vector x) {
		// Utility function for calculating the standard deviation of a vector
		sd = sqrt(quadvariance(x))
		return(sd)
	}
	
	real matrix standardizeVars(real matrix in_data, real vector var_indices) {
		// Takes a matrix containing the variables to be standardized and a vector 
		// of indices to pick out the correct variables.
		
		// It then standardizes those variables to represent the number of standard
		// deviations above or below their means.
		
		// Returns a matrix of data with all variables indicated by var_indices
		// standardized, but otherwise identical to in_data.
		
		out_data = in_data
		
		for(k=1; k<=length(var_indices); k++) {
			varmean = J(rows(in_data), 1, mean(in_data[., var_indices[k]]))
			varsd = J(rows(in_data), 1, standardDeviation(in_data[., var_indices[k]]))
			out_data[., var_indices[k]] = (in_data[., var_indices[k]] - varmean) :/ varsd
		}
		return(out_data)
	}
	
	real scalar getSSE(real vector vec1, real vector vec2, real vector var_indices) {
		// Takes two observations as vectors and a vector indicating which variables 
		// to measure on.
		
		// It then calculates the sum of squared errors, which it returns as a scalar.
		
		deltas_sq = J(length(var_indices), 1, 0)
				
		for(k=1; k<=length(var_indices); k++) {
			deltas_sq[k] = (vec1[var_indices[k]] - vec2[var_indices[k]])^2
		}
		SSE = sum(deltas_sq)
		
		return(SSE)
	}
	
	real scalar findMatch(real vector target, real matrix pool, real vector var_indices,
							real scalar idvar_index) {
		// Takes a target observation to be matched to, a pool of possible matches,
		// and a vector indicating which variables they should be matched on.
		
		// It then returns the id of the observation matched to the target as a scalar.
		
		SSEs = J(rows(pool), 1, 0)
		
		for(j=1; j<=rows(pool); j++) {
				SSEs[j] = getSSE(pool[j,.], target, var_indices)
		}
		
		minSSE = min(SSEs)
		match = select(pool[., idvar_index], SSEs :== minSSE)
			
		return(match)
	}
	
	real matrix getMatches() {
		// Takes the combined stata dataset and the macros that contain the 
		// list of matching variables and id variable.
		
		// It then returns a two-column matrix that matches each id from sample1 
		// to its best match in sample2.
		
		// Load macros as variables
		_matchvars = tokens(st_local("matchvars"))
		_idvar_index = st_varindex(st_local("idvar"))
		
		// Load Stata dataset as matrix
		_data = st_data(.,.)
		
		// Standardize match variables
		matchvars_indices = st_varindex(_matchvars)
		data_stand = standardizeVars(_data, matchvars_indices)
		
		// Divide standardized data into two matrices by sample
		sample1 = select(data_stand[.,.], data_stand[., st_varindex("smpl")] :== 1)
		sample2 = select(data_stand[.,.], data_stand[., st_varindex("smpl")] :== 2)
		
		// Find a match in sample 2 for each observation in sample 1
		sample2_matches = J(rows(sample1), 1, 0)
		for(i=1; i<=rows(sample1); i++) {
			sample2_matches[i] = findMatch(sample1[i,.], sample2, matchvars_indices,
											_idvar_index)
			printf("%f of %f matches complete\n", i, rows(sample1))
		}		
		
		r_ids = J(rows(sample1), 2, 0)
		r_ids[., 1] = sample1[., _idvar_index]
		r_ids[., 2] = sample2_matches
		return(r_ids)
	}
	
	// This mata function stores the matched ids in a stata dataset
	void storeIDs(real matrix ids) {
		st_addvar("long", "sample1_id")
		st_addvar("long", "sample2_id")
		st_addobs(rows(ids) - st_nobs())
		st_store(., "sample1_id", ids[., 1])
		st_store(., "sample2_id", ids[., 2])
	}
end
