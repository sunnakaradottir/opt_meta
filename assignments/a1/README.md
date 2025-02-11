Your task is to implement an Iterated Local Search for the Clever Travelling Salesperson Problem. 
You will need to design your own solution representation, neighbourhood function, step function and perturbation.
Test different implementation options, and give your best shot at finding the best solution. 

The upper bound value provided with each instance is there so that you can evaluate the quality of your solutions.
Those are the best-known values for the instances (remember, no one is expecting you to reach or be better than these upper bounds).

Your program needs to be able to take three command line parameters, the name of the instance and the time limit (in seconds), and create a text file with the solution you have found. Also, the main file of your program should have your study number as filename.

You are provided with an instance reader and a set of test instances. Note that the assignment is assessed on a hidden set of instances.

You are also provided with a command line solution checker, which is also what we will use to test your algorithm




Depending on your operating system, your machine may interpret file names differently. 
In some cases you might need to add a backslash before dots that are meant to be included in the filename itself.
Example: julia s242689.jl Instances/br17\.10.sop