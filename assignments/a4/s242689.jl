include("InstanceReader.jl")

mutable struct termination_criteria
    time_limit::UInt64
    not_improvement_limit::Int32
    iteration::Int32
    not_improvement_count::Int32
    start_time::UInt64
    tabu_list::Vector{Tuple{Int32, Int32}} # stores swap moves (i, j) for swapping customer i with customer j
    tabu_list_size::Int32 # max size of the list, when we exceed it is FIFO
end

mutable struct solution
    customer_list::Array{Int32, 1} # customer sequence in visitation order
    total_cost::Float64 # the total distance travelled
    swap_move::Union{Nothing, Tuple{Int32, Int32}} # swap move to generate solution if applicable
end

function StringRepresentation(some_solution::solution)
    return_string = join(some_solution.customer_list, " ")
    return return_string
end

function Terminate(criteria::termination_criteria)
    elapsed_time = time_ns() - criteria.start_time
    if elapsed_time > criteria.time_limit #|| criteria.not_improvement_count >= criteria.not_improvement_limit
        return true
    end
    return false
end

function PushToTabuList!(criteria::termination_criteria, move::Tuple{Int32, Int32})
    push!(criteria.tabu_list, move)
    if length(criteria.tabu_list) > criteria.tabu_list_size
        popfirst!(criteria.tabu_list)  # remove the oldest move if the list exceeds its size
    end
end

function IsTabu(criteria::termination_criteria, move::Tuple{Int32, Int32})
    # check if a move is to be avoided
    return move in criteria.tabu_list
end

function UpdateSolutionCost(some_solution::solution, instance_data::problem_data)
    total_cost = 0

    for i in 1:(length(some_solution.customer_list)-1)
        current_cost = instance_data.cost[some_solution.customer_list[i], some_solution.customer_list[i+1]]

        if current_cost == -1  # invalid path due to precedence constraint violation
            return Inf
        end

        total_cost += current_cost
    end

    some_solution.total_cost = total_cost
    return total_cost
end

function CalculateGreedySolution(instance_data::problem_data, starting_customer::Int64)
    current_customer = starting_customer
    unvisited = Set(1:instance_data.dimension)
    delete!(unvisited, current_customer)
    tour = [current_customer]
    total_cost = 0.0
    invalid_tour = false

    while !isempty(unvisited)
        min_cost = Inf
        next_customer = -1
        # we choose the next customer based on the cheapest path from where we are
        for customer in unvisited
            current_cost = instance_data.cost[current_customer, customer]

            if current_cost != -1 && current_cost < min_cost
                min_cost = current_cost
                next_customer = customer
            end
        end

        # move to next customer if no valid moves found from the previous starting point
        if next_customer == -1
            if starting_customer < instance_data.dimension
                return CalculateGreedySolution(instance_data, starting_customer + 1) # restart from next customer
            else
                invalid_tour = true # otherwise we cant find a valid tour
                tour = collect(1:instance_data.dimension) # return a dummy tour
                return solution(tour, Inf, nothing)
            end
        end

        # move to the next customer
        push!(tour, next_customer)
        delete!(unvisited, next_customer)
        total_cost += min_cost
        current_customer = next_customer
    end

    return solution(tour, total_cost, nothing)
end

function CalculateNeighbours(some_solution::solution)
    neighbours = []
    n = length(some_solution.customer_list)

    # 2-opt move: deleting two edges and reconnecting in another way, finding new solutions
    for i in 1:(n-1)
        for j in (i+1):n # go through all possible pairs of (i,j) and reverse the sublist between them
            new_tour = deepcopy(some_solution.customer_list)
            new_tour[i:j] = reverse(new_tour[i:j])
            
            move = (i, j)
            push!(neighbours, solution(new_tour, 0, move)) # we will evaluate the cost later
        end
    end

    return neighbours
end

function CalculateBestNeighbour(neighbours::Vector{Any}, instance_data::problem_data, criteria::termination_criteria)
    best_neighbour = solution([], Inf, nothing) # starting solution to check against

    for neighbour in neighbours
        neighbour.total_cost = UpdateSolutionCost(neighbour, instance_data) # now we check the cost
        
        # we dont want to repeat moves from the tabu list
        if neighbour.total_cost < Inf && (!IsTabu(criteria, neighbour.swap_move) && neighbour.total_cost < best_neighbour.total_cost)
            best_neighbour = neighbour
        end
    end

    return best_neighbour
end

function main()
    println("🚀 Starting Tabu Search Algorithm...")
    # receive user input and retrieve instance data
    if length(ARGS) < 3
        println("Usage: julia s242689.jl Instances/<instance.txt> <solution_filename.txt> <time_limit_seconds>")
        exit(1)
    end
    instance_filename = ARGS[1]
    solution_filename = ARGS[2]
    time_limit_seconds = parse(Float64, ARGS[3])
    time_limit_ns = UInt64(time_limit_seconds * 1_000_000_000)
    instance_data = read_instance(instance_filename) # structure the problem data for referencing
    if !isdir("sols")
        mkdir("sols") # create solution directory if it doesnt exist
    end
    # generate initial greedy solution and setup termination criteria
    current_solution = CalculateGreedySolution(instance_data, 1)
    criteria = termination_criteria(time_limit_ns, 5000, 0, 0, time_ns(), [], 50)
    println("Initial Tour: ", StringRepresentation(current_solution))

    println("🏁 Starting optimization process...")
    # run the CTSP algorithm to try and get a better solution
    while !Terminate(criteria)
        neighbours = CalculateNeighbours(current_solution)
        best_neighbour = CalculateBestNeighbour(neighbours, instance_data, criteria)

        if best_neighbour.total_cost < Inf
            # add move to tabu list
            if best_neighbour.swap_move !== nothing
                PushToTabuList!(criteria, best_neighbour.swap_move)
            end

            # check if this is the best solution found so far, update if it is
            if best_neighbour.total_cost < current_solution.total_cost
                current_solution = best_neighbour
                criteria.not_improvement_count = 0
            else
                criteria.not_improvement_count += 1
            end
        end

        criteria.iteration += 1
    end

    # write the best solution to a file
    f = open(solution_filename, "w")
    write(f, StringRepresentation(current_solution))
    close(f)
    
    println("📊 Upper bound: ", instance_data.upper_bound)
    println("📊 Upper bound: ", current_solution.total_cost)
    if current_solution.total_cost != Inf && current_solution.total_cost > 0
        solution_quality = instance_data.upper_bound / current_solution.total_cost
        println("📊 Solution Quality (Upper Bound / Solution Cost): ", round(solution_quality, digits=4))
    else
        println("📊 Solution Quality: Cannot calculate, solution is invalid (Inf or 0).")
    end

end

main()