_SOLUTION_SIZES = Dict(
    "Berlin_1_256" => "762.95 MB",
    "Boston_0_256" => "921.70 MB",
    "Paris_1_256" => "1013.86 MB",
    "brc202d" => "6.30 GB",
    "den312d" => "196.84 MB",
    "den520d" => "642.26 MB",
    "empty-32-32" => "41.25 MB",
    "empty-48-48" => "286.19 MB",
    "empty-8-8" => "37.89 MB",
    "ht_chantry" => "311.30 MB",
    "ht_mansion_n" => "421.75 MB",
    "lak303d" => "1.14 GB",
    "lt_gallowstemplar_n" => "499.80 MB",
    "maze-128-128-1" => "27.16 MB",
    "maze-128-128-10" => "1.25 GB",
    "maze-128-128-2" => "677.25 MB",
    "maze-32-32-4" => "14.97 MB",
    "orz900d" => "54.03 GB",
    "ost003d" => "762.52 MB",
    "random-32-32-20" => "22.06 MB",
    "random-64-64-10" => "132.79 MB",
    "random-64-64-20" => "177.50 MB",
    "room-32-32-4" => "28.29 MB",
    "room-64-64-16" => "725.42 MB",
    "room-64-64-8" => "643.67 MB",
    "w_woundedcoast" => "6.79 GB",
    "warehouse-10-20-10-2-1" => "138.14 MB",
    "warehouse-10-20-10-2-2" => "190.49 MB",
    "warehouse-20-40-10-2-1" => "415.00 MB",
    "warehouse-20-40-10-2-2" => "565.16 MB",
)

function __init__()
    register(
        DataDep(
            "mapf-map",
            """
            All maps from the Sturtevant MAPF benchmarks (size: 73 KB)
            https://movingai.com/benchmarks/mapf/index.html
            """,
            "https://movingai.com/benchmarks/mapf/mapf-map.zip",
            "9da2e4c5ce03aa4e063b3a283ce874590b36cc4f31a297fe7ecb00d105abf288";
            post_fetch_method=unpack,
        ),
    )
    register(
        DataDep(
            "mapf-scen-random",
            """
            All random scenarios from the Sturtevant MAPF benchmarks (size: 7.9 MB)
            Source: https://movingai.com/benchmarks/mapf/index.html
            """,
            "https://movingai.com/benchmarks/mapf/mapf-scen-random.zip",
            "20b7838f7a51f13e90a63ee138e9435fb4e41b0381becbc7313b7d3a7d859276";
            post_fetch_method=unpack,
        ),
    )
    register(
        DataDep(
            "mapf-scen-even",
            """
            All even scenarios from the Sturtevant MAPF benchmarks (size: 9.9 MB)
            Source: https://movingai.com/benchmarks/mapf/index.html
            """,
            "https://movingai.com/benchmarks/mapf/mapf-scen-even.zip",
            "249896aaf15ef2d9beb378f954f0b7ca17189c6dec1b76a78965bbdbe714ad75";
            post_fetch_method=unpack,
        ),
    )

    for (instance_name, download_size) in pairs(_SOLUTION_SIZES)
        download_link = "https://tracker-legacy.pathfinding.ai/quickDownload/results/$(instance_name).zip"
        register(
            DataDep(
                "mapf-sol-$instance_name",
                """
                Best known solutions for the $instance_name instance of the Sturtevant MAPF benchmarks (size: $download_size)
                Source: https://tracker-legacy.pathfinding.ai/
                """,
                download_link;
                post_fetch_method=unpack,
            ),
        )
    end
    return nothing
end
