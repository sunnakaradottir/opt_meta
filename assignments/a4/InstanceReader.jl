struct problem_data
    name::String
    upper_bound::Int64
    dimension::Int64
    cost::Array{Int64, 2} # cost between travelling from customer i to customer j
end


# Read an instance of the Clever Traveling Salesperson Problem
# Input: filename = path + filename of the instance
function read_instance(filename)
    # Opens the file
    f = open(filename)
    # Reads the name of the instance
    name = split(readline(f))[2]
    # reads the upper bound value
    upper_bound = parse(Int64,split(readline(f))[2])
    readline(f)#type
    readline(f)#comment
    # reads the dimentions of the problem
    dimension = parse(Int64,split(readline(f))[2]);
    readline(f)#Edge1
    readline(f)#Edge2
    readline(f)#Edge3
    readline(f)#Dimention 2

    # Initialises the cost matrix
    cost = zeros(Int64,dimension,dimension)
    # Reads the cost matrix
    for i in 1:dimension
        data = parse.(Int64,split(readline(f)))
        cost[i,:]=data
    end

    # Closes the file
    close(f)

    # Returns the input data
    return problem_data(name, upper_bound, dimension, cost)
end
