using Random
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
    if elapsed_time > criteria.time_limit || criteria.not_improvement_count >= criteria.not_improvement_limit
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
            some_solution.total_cost = Inf
            return Inf
        end

        total_cost += current_cost
    end

    some_solution.total_cost = total_cost
    return total_cost
end

function LocalSearchInitialization(instance_data::problem_data, max_attempts::Int = 5000, max_iterations::Int = 10000)
    valid_solution_found = false
    best_solution = solution([], Inf, nothing)
    
    for attempt in 1:max_attempts
        # Generate a random sequence of guests
        guests = collect(1:instance_data.dimension)
        shuffle!(guests)
        
        # Create an initial solution object
        current_solution = solution(guests, Inf, nothing)
        current_solution.total_cost = UpdateSolutionCost(current_solution, instance_data)
        
        # Check if the generated solution is valid (i.e., total_cost is finite and not Inf)
        if current_solution.total_cost < Inf
            valid_solution_found = true
            best_solution = deepcopy(current_solution)
            break  # We found a valid solution, so exit the attempt loop
        end
    end

    if !valid_solution_found
        println("❌ No valid solution found after $max_attempts attempts.")
        return nothing  # Return nothing if no valid solution was found
    end
    
    println("✅ Valid initial solution found. Starting local search refinement...")

    # Refine the solution using a simple local search
    for iter in 1:max_iterations
        neighbours = CalculateNeighbours(best_solution)
        best_neighbour = CalculateBestNeighbour(neighbours, instance_data, termination_criteria(0, 0, 0, 0, time_ns(), [], 0))
        
        if best_neighbour.total_cost < best_solution.total_cost
            best_solution = deepcopy(best_neighbour)
        else
            break  # No improvement, stop refining
        end
    end
    
    println("Initial solution generated using Local Search: ", StringRepresentation(best_solution))
    return best_solution
end



function CalculateNeighbours(some_solution::solution; max_neighbours::Int = 100)
    neighbours = Vector{solution}()  # initialize an empty vector of type solution
    n = length(some_solution.customer_list)
    neighbour_count = 0

    # limit the number of generated neighbours to avoid long computation times
    for i in 1:(n-1)
        for j in (i+1):n
            if neighbour_count >= max_neighbours
                return neighbours  # return early if the maximum limit is reached
            end
            
            # generate a neighbour by reversing a segment of the tour
            new_tour = deepcopy(some_solution.customer_list)
            new_tour[i:j] = reverse(new_tour[i:j])
            
            move = (i, j)
            push!(neighbours, solution(new_tour, 0, move))  # ensure type consistency
            neighbour_count += 1
        end
    end

    return neighbours
end


function CalculateBestNeighbour(neighbours::Vector{solution}, instance_data::problem_data, criteria::termination_criteria)
    best_neighbour = solution([], Inf, nothing)
    
    for neighbour in neighbours
        neighbour.total_cost = UpdateSolutionCost(neighbour, instance_data)
        
        # stop as soon as we find a valid improvement
        if neighbour.total_cost < best_neighbour.total_cost
            best_neighbour = deepcopy(neighbour)
            break  # early stopping to save computation time
        end
    end

    return best_neighbour
end

function PrintCostMatrix(instance_data::problem_data)
    cost_matrix = instance_data.cost
    n = size(cost_matrix, 1)
    
    println("Cost Matrix:")
    
    # print header row with customer IDs
    print("      ")
    for i in 1:n
        print(rpad(string(i), 6))  # adjust spacing for alignment
    end
    println()
    
    for i in 1:n
        # print customer ID as row header
        print(rpad(string(i), 6))
        
        for j in 1:n
            cost_value = cost_matrix[i, j]
            if cost_value == -1
                print(rpad("X", 6))  # use 'X' for invalid paths
            else
                print(rpad(string(cost_value), 6))
            end
        end
        println()  # new line for next row
    end
end

function main()
    println("🚀 Starting Tabu Search Algorithm...")
    instance_filename = ARGS[1]
    solution_filename = ARGS[2]
    time_limit_seconds = parse(Float64, ARGS[3])
    time_limit_ns = UInt64(time_limit_seconds * 1_000_000_000)
    instance_data = read_instance(instance_filename)

    if !isdir("sols")
        mkdir("sols")
    end

    # Generate initial solution using Local Search
    current_solution = LocalSearchInitialization(instance_data)
    criteria = termination_criteria(time_limit_ns, 5000, 0, 0, time_ns(), [], 50)
    
    println("🏁 Starting optimization process...")

    while !Terminate(criteria)
        neighbours = CalculateNeighbours(current_solution)
        best_neighbour = CalculateBestNeighbour(neighbours, instance_data, criteria)

        if best_neighbour.total_cost < Inf
            if best_neighbour.swap_move !== nothing
                PushToTabuList!(criteria, best_neighbour.swap_move)
            end

            if best_neighbour.total_cost < current_solution.total_cost
                current_solution = best_neighbour
                criteria.not_improvement_count = 0
            else
                criteria.not_improvement_count += 1
            end
        end

        criteria.iteration += 1
    end

    # Print the best solution quality
    println("📊 Upper bound: ", instance_data.upper_bound)
    println("📊 Best Solution Cost: ", current_solution.total_cost)
    println("best solution: ", StringRepresentation(current_solution))
    PrintCostMatrix(instance_data)
    if current_solution.total_cost != Inf && current_solution.total_cost > 0
        solution_quality = instance_data.upper_bound / current_solution.total_cost
        println("📊 Solution Quality (Upper Bound / Solution Cost): ", round(solution_quality, digits=4))
    else
        println("📊 Solution Quality: Cannot calculate, solution is invalid (Inf or 0).")
    end

    f = open(solution_filename, "w")
    write(f, StringRepresentation(current_solution))
    close(f)

    println()
end


main()