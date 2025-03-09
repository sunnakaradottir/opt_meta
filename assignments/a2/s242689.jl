include("PlastOutReader.jl")

mutable struct solution
    objective::Float64 # total revenue
    order_mapping::Array{Int, 2} # 2D array: rows = lines, cols = orders
end

mutable struct termination_criteria
    max_iterations::Int
    not_improvement_limit::Int
    candidate_solution::solution
    iteration::Int
    not_improvement_count::Int
end

function Terminate(instance_data, some_solution::solution, criteria::termination_criteria)
    criteria.iteration += 1

    # see if candidate solution is better than the current best
    if some_solution.objective > criteria.candidate_solution.objective
        criteria.candidate_solution = some_solution
        criteria.not_improvement_count = 0
    else
        criteria.not_improvement_count += 1
    end

    # stop if max iterations or no improvement for too long
    return criteria.iteration >= criteria.max_iterations || criteria.not_improvement_count >= criteria.not_improvement_limit
end

#= struct problem_data
    case_name::String
    no_orders::Int
    LB::Int
    revenue::Int
    revenue_pair::Array{Int, 2}
    no_prod_lines::Int
    time_horizon::Int
    prod_time::Array{Int, 1}
end =#

function GreedyRandomizedConstruction(problem_data::problem_date)
    # attempts to find an initial fesible solution
    solution = solution(-Inf, fill(0, data.no_prod_lines, data.no_orders))  # 2D array: rows = lines, cols = orders

    # goal: assign orders to production lines while maximizing revenue.
    # constraints: each order is assigned to exactly one production line, no production line exceeds maximum production time

    # initialize variables
    remaining_time = fill(problem_data.time_horizon, problem_data.no_prod_lines) # each production line has max time
    total_revenue = 0.0
    visited_orders = falses(data.no_orders) # boolean to track visited orders

    # 1: select orders for production lines
    while any(.!visited_orders)
        # randomly select order to assign to a production line
        order = rand(1:problem_data.no_orders)
        if assigned_orders[order]
            continue
        end

        # find feasible production lines for the random order
        candidate_lines = []
        revenue_values = []
        for line in 1:problem_data.no_prod_lines
            if remaining_time[line] >= problem_data.prod_time[order]
                # compute total revenue if order is assigned to this line
                total_revenue = data.revenue[order]
                for assigned_order in 1:data.no_orders
                    if solution[line, assigned_order] == 1
                        total_revenue += data.revenue_pair[order, assigned_order]
                    end
                end
                push!(candidate_lines, line)
                push!(revenue_values, total_revenue)
            end
        end

    end
    # 2: use a RCL to select the next order to assign (to avoid strictly greedy choices)


end

function LocalSearch(instance_data, some_solution::solution)
    # something
end

function Profit(instance_data, some_solution::solution)
    # something
end


function Main()
    # receive user input and retrieve instance data
    if length(ARGS) < 1
        println("Usage: julia s242689.jl <instance>.txt")
        exit(1)
    end
    instance = ARGS[1]
    instance_path = pwd() * "/PlastOut_Instances/" * instance
    problem_data = read_instance(instance_path)

    # set up termination criteria and an empty current solution
    criteria = termination_criteria(1000, 100, solution(-Inf, fill(0, data.no_prod_lines, data.no_orders)), 0, 0)
    current_solution = solution(-Inf, fill(0, data.no_prod_lines, data.no_orders))

    while !Terminate(problem_data, current_solution, criteria)
        current_solution = GreedyRandomizedConstruction(problem_data) # randomized solution
        LocalSearch(problem_data, current_solution) # perform local search on it
    end

end

main()