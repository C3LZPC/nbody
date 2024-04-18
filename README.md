# nbody


**!! The task can only be accepted with real-time graphical display (i.e., OGL/DX/Vulcan interop.).**

Implement the space-partitioned version of the N-body simulation seen in the practice, that is, divide the simulation space into smaller blocks within which the interaction (with particles of the nearest neighbouring blocks) is exact (20%), but distant blocks interact only through their centres of mass. (20%)

Enable the user to easily reset and re-parameterize the simulation
 * changing the gravitational constant, (5%)
 * setting the number of objects, (5%)
 * changing the type of initial distribution of the objects (e.g., uniform/non-uniform randomization). (10%)
 * Implement the N-body simulation in 3D (10%), where the user can navigate space and observe the simulation from different viewpoints (20%).

**If you move memory from GPU to CPU (e.g., particle positions) before drawing them, you lose 40%.**



