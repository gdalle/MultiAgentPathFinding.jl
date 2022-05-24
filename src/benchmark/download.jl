function download_benchmark_mapf(series="street", instance="Berlin_0_256"; buckets)
    benchmark_url = "https://movingai.com/benchmarks/"
    data_dir = tempdir()
    map_zip_path = joinpath(data_dir, "$instance.map.zip")
    map_path = joinpath(data_dir, "$instance.map")
    scenario_zip_path = joinpath(data_dir, "$instance.map-scen.zip")
    scenario_path = joinpath(data_dir, "$instance.map.scen")
    # Download
    HTTP.open(:GET, benchmark_url * "$series/$instance.map.zip") do page
        open(map_zip_path, "w") do file
            write(file, page)
        end
    end
    HTTP.open(:GET, benchmark_url * "$series/$instance.map-scen.zip") do page
        open(scenario_zip_path, "w") do file
            write(file, page)
        end
    end
    # Extract
    for compressed_file in ZipFile.Reader(map_zip_path).files[1:1]
        open(map_path, "w") do file
            write(file, read(compressed_file, String))
        end
    end
    for compressed_file in ZipFile.Reader(scenario_zip_path).files[1:1]
        open(scenario_path, "w") do file
            write(file, read(compressed_file, String))
        end
    end
    # Parse
    mapf = benchmark_mapf(map_path, scenario_path; buckets=buckets)
    return mapf
end
