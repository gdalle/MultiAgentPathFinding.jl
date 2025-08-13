_SOLUTION_IDS = Dict(
    "Berlin_1_256" => "63761f255d814f08ecdbf3af",
    "Paris_1_256" => "63761f255d814f08ecdbf3b1",
    "Boston_0_256" => "63761f265d814f08ecdbf3ba",
    "empty-32-32" => "63761f245d814f08ecdbf3a2",
    "empty-8-8" => "63761f255d814f08ecdbf3a6",
    "empty-48-48" => "63761f255d814f08ecdbf3ad",
    "empty-16-16" => "63761f265d814f08ecdbf3c2",
    "lak303d" => "63761f255d814f08ecdbf3a4",
    "brc202d" => "63761f255d814f08ecdbf3a5",
    "ost003d" => "63761f255d814f08ecdbf3a8",
    "den520d" => "63761f255d814f08ecdbf3a9",
    "ht_mansion_n" => "63761f255d814f08ecdbf3ab",
    "w_woundedcoast" => "63761f255d814f08ecdbf3ae",
    "ht_chantry" => "63761f255d814f08ecdbf3b3",
    "den312d" => "63761f265d814f08ecdbf3b8",
    "lt_gallowstemplar_n" => "63761f265d814f08ecdbf3be",
    "orz900d" => "63761f265d814f08ecdbf3bf",
    "maze-128-128-10" => "63761f255d814f08ecdbf3aa",
    "maze-128-128-1" => "63761f255d814f08ecdbf3b2",
    "maze-128-128-2" => "63761f265d814f08ecdbf3b6",
    "maze-32-32-4" => "63761f265d814f08ecdbf3bb",
    "random-32-32-20" => "63761f255d814f08ecdbf3a3",
    "random-64-64-10" => "63761f255d814f08ecdbf3a7",
    "random-64-64-20" => "63761f265d814f08ecdbf3b7",
    "random-32-32-10" => "63761f265d814f08ecdbf3c0",
    "room-64-64-8" => "63761f255d814f08ecdbf3ac",
    "room-32-32-4" => "63761f265d814f08ecdbf3bc",
    "room-64-64-16" => "63761f265d814f08ecdbf3bd",
    "warehouse-20-40-10-2-1" => "63761f255d814f08ecdbf3b0",
    "warehouse-10-20-10-2-1" => "63761f255d814f08ecdbf3b4",
    "warehouse-20-40-10-2-2" => "63761f255d814f08ecdbf3b5",
    "warehouse-10-20-10-2-2" => "63761f265d814f08ecdbf3b9",
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

    for (instance_name, instance_id) in pairs(_SOLUTION_IDS)
        download_link = "https://fe2410d1.pathfinding.ai/api/instance/DownloadMapByID/$(instance_id)"
        register(
            DataDep(
                "mapf-sol-$instance_name",
                """
                Best known solutions for the $instance_name instance of the Sturtevant MAPF benchmarks
                Source: https://tracker.pathfinding.ai/
                """,
                download_link;
                post_fetch_method=path -> mv(path, "solution.json"),
            ),
        )
    end
    return nothing
end
