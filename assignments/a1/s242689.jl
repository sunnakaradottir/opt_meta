include("InstanceReader.jl")

function x()
    return 1
end

function main()
    if length(ARGS) < 1
        println("Usage: julia s242689.jl Instances/<name_of_the_instance>.sop")
        exit(1)
    end
    instance = ARGS[1]
    instance_path = pwd() * "/" * instance
    name, upper_bound, dimension, cost = read_instance(instance_path)
    println("Instance: $name")
    println("Upper bound: $upper_bound")
    println("Dimention: $dimension")
    println("Cost: $cost")

    # TODO: Implement the ILS algorithm for the CTSP
end

main()