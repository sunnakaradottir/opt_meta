**Project Description**
Given a set of cities, find the least-cost Hamiltonian path.
Instance reader and helper functions: TSPSolver.jl

**Instances and format description**
•    README.md
•    toy_slides.tsp
•    tsp_toy.tsp
•    tsp_toy20.tsp
•    tsp_toy50.tsp

**Documentation of the TSP instance files**
The first line describes the name of the file
The second line is used for comments on the intance
The third line described the type of problem, in our case it is always TSP
The forth line indicates the number of cities in the instance
The fifth line descrive how the distance should be a computed, in our case it is always the straight line distance
The sixth line indicated the start of the node section
Next there is a line for each city in the instance. The line in composed of 3 numbers: the ID of the city, and the X and Y coordinates.
