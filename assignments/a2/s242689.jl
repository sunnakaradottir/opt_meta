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

function Terminate(instance_data::problem_data, some_solution::solution, criteria::termination_criteria)
    criteria.iteration += 1

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

function GreedyRandomizedConstruction(instance_data::problem_data, α::Float64)
    # attempts to find an initial fesible solution
    solution = solution(-Inf, fill(0, instance_data.no_prod_lines, instance_data.no_orders))  # 2D array: rows = lines, cols = orders

    # initialize variables
    remaining_time = fill(instance_data.time_horizon, instance_data.no_prod_lines) # each production line has max time
    total_revenue = 0.0
    visited_orders = falses(instance_data.no_orders) # boolean to track visited orders

    # 1: select orders for production lines
    while any(.!visited_orders)
        # randomly select order to assign to a production line
        order = rand(1:instance_data.no_orders)
        if visited_orders[order]
            continue
        end

        # find feasible production lines for the random order
        candidate_lines = [] # list of production lines that can handle the order
        revenue_values = [] # list of total revenue values for each candidate line
        for line in 1:instance_data.no_prod_lines
            if remaining_time[line] >= instance_data.prod_time[order]
                # compute total revenue if order is assigned to this line
                total_revenue = instance_data.revenue[order] # profit for this order
                for assigned_order in 1:instance_data.no_orders # add cost savings from other orders
                    if solution[line, assigned_order] == 1
                        total_revenue += instance_data.revenue_pair[order, assigned_order]
                    end
                end
                push!(candidate_lines, line)
                push!(revenue_values, total_revenue)
            end
        end

        if !isempty(candidate_lines)
            # calculate min/max revenue
            rMin = minimum(revenue_values)
            rMax = maximum(revenue_values)

            # calculate the RCL
            RCL = []
            for i in 1:length(candidate_lines)
                if revenue_values[i] >= rMin + α * (rMax - rMin)
                    push!(RCL, i)
                end
            end

            # randomly select a line from the RCL
            selected_line = RCL[rand(1:length(RCL))]

            # assign the order to the selected line
            solution.objective = revenue_values[selected_line]
            solution.order_mapping[candidate_lines[selected_line], order] = 1
            remaining_time[candidate_lines[selected_line]] -= instance_data.prod_time[order]
        end

        visited_orders[order] = true
    end

    return solution
end

function LocalSearch(instance_data::problem_data, some_solution::solution)
    improved = true

    while improved
        improved = false

        # move an order from one production line to another (if it increases the total revenue)
        for order in 1:instance_data.no_orders
            for assigned_line in 1:instance_data.no_prod_lines
                if some_solution.order_mapping[assigned_line, order] != 1 # get the assigned line
                    continue
                end
                for new_line in 1:instance_data.no_prod_lines
                    if new_line == assigned_line # get an unused line
                        continue
                    end
                    # calculate the revenue of a solution where the order is moved to the new line
                    new_revenue = instance_data.revenue[order]
                    for new_order in 1:instance_data.no_orders # add cost savings from other orders
                        if solution[new_line, new_order] == 1 # if the new order is also assigned to the line
                            new_revenue += instance_data.revenue_pair[order, new_order]
                        end
                    end

                    # if the new solution is better, update the solution
                    if new_revenue > some_solution.objective
                        some_solution.objective = new_revenue
                        some_solution.order_mapping[new_line, order] = 1
                        some_solution.order_mapping[assigned_line, order] = 0
                        improved = true
                    end
                end
            end
        end
    end

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
    criteria = termination_criteria(1000, 100, solution(-Inf, fill(0, problem_data.no_prod_lines, problem_data.no_orders)), 0, 0)
    current_solution = solution(-Inf, fill(0, problem_data.no_prod_lines, problem_data.no_orders))
    alpha = 0.3

    while !Terminate(problem_data, current_solution, criteria)
        candidate_solution = GreedyRandomizedConstruction(problem_data, alpha) # randomized solution
        LocalSearch(problem_data, candidate_solution) # perform local search around it

        if candidate_solution.objective > current_solution.objective
            current_solution = candidate_solution
            criteria.not_improvement_count = 0
        else
            criteria.not_improvement_count += 1
        end
    end

end

main()