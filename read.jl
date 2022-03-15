using CSV
using DataFrames

function date_sort!(fv::Array{String})

	month_d = Dict(
					"Jan"=>1,
					"Feb"=>2,
					"Mar"=>3,
					"Apr"=>4,
					"May"=>5,
					"Jun"=>6,
					"Jul"=>7,
					"Aug"=>8,
					"Sep"=>9,
					"Oct"=>10,
					"Nov"=>11,
					"Dec"=>12
					)

	date_v = map(fv) do date
		(day, month, year) = split(date,"-")
		day = tryparse(Int64, day)
		month = month_d[month]
		year = tryparse(Int64, year[1:4])
		(day, month, year, date)
	end

	sort!(date_v, by = x->(x[3],x[2],x[1],x[4]))
	fv[:] = map(x -> x[4], date_v) 
end

function read_csv_var_cols(file_path::String)

	# read a csv file with a variable number of columns across rows
	# missing data_m elements are filled with ""

	max_ncols = 0 
	nrows = 0 

	f = open(file_path)
	while !eof(f)
		new_line = split(strip(readline(f)),',') 
		if length(new_line) > max_ncols
			max_ncols = length(new_line)
		end
		nrows += 1
	end
	close(f)

	f = open(file_path)

	headers = [string("col",i) for i = 1 : max_ncols]
	ncols = max_ncols ;
	data_m = Matrix{String}(undef, nrows, max_ncols)

	i = 1
	while !eof(f)

		new_line = split(strip(readline(f)),',')
		length(new_line) < ncols && append!(new_line,["" for i=1:ncols-length(new_line)])

		data_m[i, :] = new_line

		i += 1
	end

	close(f)
	return data_m
end

function read_CS(dir)

	file_v = filter(x->occursin(".csv", x), readdir(dir)) ;
	date_sort!(file_v)

	dt_row_len = 34

	CS_start_delay = 200 # centiseconds
	CS_duration = 600 # centiseconds

	#trial_type_d = Dict(0 => "FR", 1 => "FR+Tone+Shock", 2 => "FR+Tone")
	trial_type_d = Dict(0 => "FR", 1 => "FR+Tone")

	df = DataFrame(ID = Int64[], 
					trial = Int64[], trial_type = String[], 
					RT = Float64[], LP = Int64[], 
					outcome = String[], side = String[])

	LP_CS_v = Int64[]

	for file_name in file_v
		
		println(file_name)

		data_m = read_csv_var_cols(string(dir, file_name)) ;

		(nrows, ncols) = size(data_m)

		subj_ID = 0 
		side = "" 
		trial_start_time_v = Int64[]
		row_idx = 1
	
		while row_idx < nrows

			if occursin("Id", data_m[row_idx, 1])
				id_number_v = split(data_m[row_idx, 2], '_')
				subj_ID = tryparse(Int64, id_number_v[2])
			end

			if occursin("L(1)", data_m[row_idx, 1])
				side = data_m[row_idx + 1, 1] != "0" ? "L" : "R"
			end

			if occursin("Ref", data_m[row_idx, 1]) && occursin("Outcome", data_m[row_idx, 2])

				trial_rows = 1
				time_v = Int64[]

				while !occursin("ENDDATA", data_m[row_idx + trial_rows, 1]) && 
					!occursin("-1", data_m[row_idx + trial_rows, 1]) && 
					!isempty(data_m[row_idx + trial_rows, 1])

					trial_v = parse.(Int, data_m[row_idx + trial_rows, 1:dt_row_len])

					RT = (trial_v[13] - trial_v[12]) / 100.0

					LP = trial_v[9] + trial_v[10] + trial_v[14] + trial_v[15]

					trial_type = trial_type_d[trial_v[3]]

					if trial_v[2] == 0
						outcome = "finished"
					elseif LP > 0
						outcome = "started"
					else
						outcome = "omission"
					end

					push!(df, [subj_ID, trial_rows, trial_type, RT, LP, outcome, side])
					push!(time_v, trial_v[7])

					trial_rows += 1
				end

				trial_start_time_v = time_v
				row_idx += trial_rows
			end

			if occursin("ACTIVITYLOG", data_m[row_idx, 1])
				
				trial_idx = 0
				trial_rows = 1

				while !occursin("END", data_m[row_idx, 1])

					if occursin("TRIAL", data_m[row_idx, 1])

						trial_idx = parse(Int, data_m[row_idx, 2])
						trial_rows = 1
						c = 0
						
						while occursin("DATA", data_m[row_idx + trial_rows, 1])
							
							t = split.(data_m[row_idx + trial_rows, 2:end], ";")
							t = filter(x -> (length(x) >= 4) && (x[2] == "STIN") && (x[3] == "7") , t)

							c += count(x -> (parse(Int, x[4]) >= (trial_start_time_v[trial_idx] + CS_start_delay))  &&
											(parse(Int, x[4]) <= (trial_start_time_v[trial_idx] + CS_duration)),
										t)
							trial_rows += 1
						end

						if trial_idx > 0
							push!(LP_CS_v, c)
						end
					end
					row_idx += trial_rows
				end
			end

			row_idx += 1 
		end
	end

	df.LP_CS = LP_CS_v

	return df
end

function read_FR(dir)

	file_v = filter(x->occursin(".csv", x), readdir(dir)) ;
	date_sort!(file_v)
	
	dt_row_len = 45

	trial_type_d = Dict(0 => "FR", 1 => "FR+Tone+Shock", 2 => "FR+Tone")

	df = DataFrame(ID = String[], session = Int64[], 
					trial = Int64[], trial_type = String[], 
					RT = Float64[], LP = Int64[], 
					outcome = Bool[], side = String[])

	session = 1

	for file_name in file_v
		
		println(file_name)

		data_m = read_csv_var_cols(string(dir, file_name)) ;

		(nrows, ncols) = size(data_m)

		subj_ID = "" 
		side = "" 
		row_idx = 1
	
		while row_idx < nrows

			if occursin("Id", data_m[row_idx, 1])
				subj_ID = data_m[row_idx, 2]
			end

			if occursin("L(1)", data_m[row_idx, 1])
				side = data_m[row_idx + 1, 1] != "0" ? "L" : "R"
			end

			if occursin("Ref", data_m[row_idx, 1]) && occursin("Outcome", data_m[row_idx, 2])

				trial_rows = 1

				while !occursin("ENDDATA", data_m[row_idx + trial_rows, 1]) && 
					!occursin("-1", data_m[row_idx + trial_rows, 1]) && 
					!isempty(data_m[row_idx + trial_rows, 1])

					trial_v = parse.(Int, data_m[row_idx + trial_rows, 1:dt_row_len])

					RT = (trial_v[16] - trial_v[15]) / 100.0

					LP = trial_v[12] + trial_v[13] + trial_v[17] + trial_v[18]

					trial_type = trial_type_d[trial_v[3]]

					outcome = (trial_v[2] == 0) || (LP == 32) ? true : false

					push!(df, [subj_ID, session, trial_rows, trial_type, RT, LP, outcome, side])

					trial_rows += 1
				end
				row_idx += trial_rows
			end
			row_idx += 1 
		end
		session += 1
	end
	return df
end